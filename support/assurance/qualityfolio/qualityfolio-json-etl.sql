-- SQLITE ETL SCRIPT — FINAL SYNTAX FIX


-- 1. CLEAN AND PARSE THE RAW CONTENT
------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_raw_data;
CREATE  TABLE t_raw_data AS
SELECT
    urpe.file_basename,
    urt.uniform_resource_id,
    
    -- Clean and fix corrupted escapes
    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(
                    SUBSTR(CAST(urt.content AS TEXT), 2, LENGTH(CAST(urt.content AS TEXT)) - 2),
                    CHAR(10), '' 
                ),
                CHAR(13), ''
            ),
            '\x22', '"' -- Fix escaped quotes
        ),
        '\n', '' -- Fix escaped newlines
    ) AS cleaned_json_text
FROM uniform_resource_transform urt
INNER JOIN ur_ingest_session_fs_path_entry urpe
    ON urt.uniform_resource_id = urpe.uniform_resource_id;


-- 2. LOAD doc-classify ROLE→DEPTH MAP
------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_role_depth_map;
CREATE  TABLE t_role_depth_map AS
SELECT
    ur.uniform_resource_id,
    JSON_EXTRACT(role_map.value, '$.role') AS role_name,
    CAST(
        SUBSTR(
            JSON_EXTRACT(role_map.value, '$.select'),
            INSTR(JSON_EXTRACT(role_map.value, '$.select'), 'depth="') + 7,
            INSTR(SUBSTR(JSON_EXTRACT(role_map.value, '$.select'), INSTR(JSON_EXTRACT(role_map.value, '$.select'), 'depth="') + 7), '"') - 1
        )
    AS INTEGER) AS role_depth
FROM uniform_resource ur
    ,JSON_EACH(ur.frontmatter, '$.doc-classify') AS role_map
WHERE ur.frontmatter IS NOT NULL;


-- 3. JSON TRAVERSAL
------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_all_sections_flat;
CREATE  TABLE t_all_sections_flat AS
SELECT
    td.uniform_resource_id,
    td.file_basename,
    jt_title.value AS title,
    CAST(jt_depth.value AS INTEGER) AS depth,
    jt_body.value AS body_json_string
FROM t_raw_data td,
    json_tree(td.cleaned_json_text, '$') AS jt_section,
    json_tree(td.cleaned_json_text, '$') AS jt_depth,
    json_tree(td.cleaned_json_text, '$') AS jt_title,
    json_tree(td.cleaned_json_text, '$') AS jt_body
WHERE 
    jt_section.key = 'section' 
    AND jt_depth.parent = jt_section.id 
    AND jt_depth.key = 'depth' 
    AND jt_depth.value IS NOT NULL
    AND jt_title.parent = jt_section.id 
    AND jt_title.key = 'title' 
    AND jt_title.value IS NOT NULL
    AND jt_body.parent = jt_section.id 
    AND jt_body.key = 'body' 
    AND jt_body.value IS NOT NULL;


-- 4. NORMALIZE + ROLE ATTACH & CODE EXTRACTION (CRITICAL: Robust Delimiter Injection)
------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_all_sections;
CREATE  TABLE t_all_sections AS
SELECT
    s.uniform_resource_id,
    s.file_basename,
    s.depth,
    s.title,
    s.body_json_string,
    
    -- Extract @id (Test Case ID)
    TRIM(SUBSTR(
        s.body_json_string,
        INSTR(s.body_json_string, '@id') + 4,
        INSTR(SUBSTR(s.body_json_string, INSTR(s.body_json_string, '@id') + 4), '"') - 1
    )) AS extracted_id,
    
    -- Extract and clean raw YAML/code content
    CASE 
        WHEN INSTR(s.body_json_string, '"code":"') > 0 THEN
            -- CRITICAL FIX: Inject CHAR(10) before known keys to force separation for robust SUBSTR/INSTR logic
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            -- Start with the extracted code string
                                            SUBSTR(
                                                s.body_json_string,
                                                INSTR(s.body_json_string, '"code":"') + 8,
                                                INSTR(s.body_json_string, '","type":') - (INSTR(s.body_json_string, '"code":"') + 8)
                                            ),
                                            
                                            -- CASE keys
                                            'Tags:', CHAR(10) || 'Tags:'
                                        ),
                                        'Scenario Type:', CHAR(10) || 'Scenario Type:'
                                    ),
                                    'Priority:', CHAR(10) || 'Priority:'
                                ),
                                'requirementID:', CHAR(10) || 'requirementID:'
                            ),
                            -- EVIDENCE keys
                            'cycle:', CHAR(10) || 'cycle:'
                        ),
                        'assignee:', CHAR(10) || 'assignee:'
                    ),
                    'status:', CHAR(10) || 'status:'
                ),
                'issue_id:', CHAR(10) || 'issue_id:'
            )
        ELSE NULL
    END AS code_content,
    
    rm.role_name
FROM t_all_sections_flat s
LEFT JOIN t_role_depth_map rm
    ON s.uniform_resource_id = rm.uniform_resource_id
   AND s.depth = rm.role_depth;


-- 5. EVIDENCE HISTORY JSON ARRAY (Aggregates all evidence history)
------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_evidence_history_json;
CREATE  TABLE t_evidence_history_json AS
WITH evidence_positions AS (
    -- Stage 1A: Calculate extraction positions safely in a separate CTE
    SELECT
        tas.uniform_resource_id,
        tas.extracted_id AS test_case_id,
        tas.file_basename,
        tas.code_content,

        -- Find end positions for parsing logic
        CASE 
            WHEN INSTR(tas.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'assignee:') 
            WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
            WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(tas.code_content) + 1
        END AS end_of_cycle_pos,

        CASE 
            WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
            WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(tas.code_content) + 1
        END AS end_of_assignee_pos,
        
        CASE
            WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(tas.code_content) + 1
        END AS end_of_status_pos
    FROM t_all_sections tas
    WHERE tas.role_name = 'evidence' AND tas.extracted_id IS NOT NULL AND tas.code_content IS NOT NULL
), 
evidence_temp AS (
    -- Stage 1B: Extract fields using calculated positions
    SELECT
        ep.uniform_resource_id,
        ep.test_case_id,
        ep.file_basename,

        TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'cycle:') + 6, ep.end_of_cycle_pos - (INSTR(ep.code_content, 'cycle:') + 6))) AS val_cycle,
        TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'assignee:') + 9, ep.end_of_assignee_pos - (INSTR(ep.code_content, 'assignee:') + 9))) AS val_assignee,
        TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'status:') + 7, ep.end_of_status_pos - (INSTR(ep.code_content, 'status:') + 7))) AS val_status,
        CASE WHEN INSTR(ep.code_content, 'issue_id:') > 0 THEN TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'issue_id:') + 9)) ELSE '' END AS val_issue_id
    FROM evidence_positions ep
)
-- Stage 2: Aggregate the extracted values into a structured JSON string (array)
SELECT
    et.uniform_resource_id,
    et.test_case_id,
    
    '[' || GROUP_CONCAT(
        JSON_OBJECT(
            'cycle', et.val_cycle,
            'assignee', et.val_assignee,
            'status', et.val_status,
            'issue_id', et.val_issue_id,
            'file_basename', et.file_basename
        )
    , ',') || ']' AS evidence_history_json
FROM evidence_temp et
GROUP BY et.uniform_resource_id, et.test_case_id;


-- 5.5 LATEST EVIDENCE STATUS (Finds the single latest record for each test case PER FILE)
------------------------------------------------------------------------------

DROP TABLE IF EXISTS t_latest_evidence_status;
CREATE  TABLE t_latest_evidence_status AS
WITH evidence_positions AS (
    -- Stage 1A: Calculate extraction positions safely
    SELECT
        tas.uniform_resource_id,
        tas.file_basename, 
        tas.extracted_id AS test_case_id,
        tas.code_content,
        
        -- Find end position for cycle
        CASE 
            WHEN INSTR(tas.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'assignee:') 
            WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
            WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(tas.code_content) + 1
        END AS end_of_cycle_pos,

        -- Find end position for assignee
        CASE 
            WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
            WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(tas.code_content) + 1
        END AS end_of_assignee_pos,
        
        -- Find end position for status
        CASE
            WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(tas.code_content) + 1
        END AS end_of_status_pos

    FROM t_all_sections tas
    WHERE tas.role_name = 'evidence' AND tas.extracted_id IS NOT NULL AND tas.code_content IS NOT NULL
), 
evidence_details AS (
    -- Stage 1B: Extract fields using calculated positions
    SELECT
        ep.uniform_resource_id,
        ep.file_basename,
        ep.test_case_id,
        
        TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'cycle:') + 6, ep.end_of_cycle_pos - (INSTR(ep.code_content, 'cycle:') + 6))) AS val_cycle,
        TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'assignee:') + 9, ep.end_of_assignee_pos - (INSTR(ep.code_content, 'assignee:') + 9))) AS val_assignee,
        TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'status:') + 7, ep.end_of_status_pos - (INSTR(ep.code_content, 'status:') + 7))) AS val_status,
        CASE WHEN INSTR(ep.code_content, 'issue_id:') > 0 THEN TRIM(SUBSTR(ep.code_content, INSTR(ep.code_content, 'issue_id:') + 9)) ELSE '' END AS val_issue_id
    FROM evidence_positions ep
),
-- Use ROW_NUMBER() to find the latest (highest cycle) for each test case PER FILE
ranked_evidence AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            -- FIX: Partition by uniform_resource_id AND test_case_id
            PARTITION BY uniform_resource_id, test_case_id
            ORDER BY val_cycle DESC
        ) AS rn
    FROM evidence_details
)
-- Select only the latest record (rank = 1)
SELECT
    uniform_resource_id,
    test_case_id,
    file_basename AS latest_file_basename, 
    val_cycle AS latest_cycle,
    val_assignee AS latest_assignee,
    val_status AS latest_status,
    val_issue_id AS latest_issue_id
FROM ranked_evidence
WHERE rn = 1;


CREATE VIEW v_section_hierarchy_summary AS
SELECT
    s.file_basename,
    (SELECT title FROM t_all_sections p WHERE p.uniform_resource_id = s.uniform_resource_id AND p.role_name = 'project'  ORDER BY p.depth LIMIT 1) AS project_title,
    -- Concatenate inner section titles (Strategy, Plan, Suite) to show hierarchy
    GROUP_CONCAT(
        CASE s.role_name
            WHEN 'strategy' THEN 'Strategy: ' || s.title
            WHEN 'plan'     THEN 'Plan: ' || s.title
            WHEN 'suite'    THEN 'Suite: ' || s.title
            ELSE NULL
        END, ' | '
    ) AS inner_sections,
    -- Count the number of test cases associated with this file
    COUNT(CASE WHEN s.role_name = 'case' THEN 1 ELSE NULL END) AS test_case_count
FROM t_all_sections s
GROUP BY s.uniform_resource_id, s.file_basename;

