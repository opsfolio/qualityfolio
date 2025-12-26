-- SQLITE ETL SCRIPT — FINAL MODIFIED VERSION (Relying on Evidence Status)
-- 1. CLEAN AND PARSE THE RAW CONTENT
------------------------------------------------------------------------------
DROP TABLE IF EXISTS t_raw_data;
CREATE TABLE t_raw_data AS WITH ranked AS (
  SELECT
    ur.uniform_resource_id,
    ur.uri,
    ur.last_modified_at,
    urpe.file_basename,
    -- Clean and fix corrupted escapes
    REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            SUBSTR(
              CAST(urt.content AS TEXT),
              2,
              LENGTH(CAST(urt.content AS TEXT)) - 2
            ),
            CHAR(10),
            ''
          ),
          CHAR(13),
          ''
        ),
        '\x22',
        '"' -- Fix escaped quotes
      ),
      '\n',
      '' -- Fix escaped newlines
    ) AS cleaned_json_text,
    ROW_NUMBER() OVER (
      PARTITION BY ur.uri
      ORDER BY
        ur.last_modified_at DESC,
        ur.uniform_resource_id DESC
    ) AS rn
  FROM
    uniform_resource_transform urt
    JOIN uniform_resource ur ON ur.uniform_resource_id = urt.uniform_resource_id
    JOIN ur_ingest_session_fs_path_entry urpe ON ur.uniform_resource_id = urpe.uniform_resource_id
  WHERE
    ur.last_modified_at IS NOT NULL
)
SELECT
  file_basename,
  uniform_resource_id,
  uri,
  last_modified_at,
  cleaned_json_text
FROM
  ranked
WHERE
  rn = 1;
-- 2. LOAD doc-classify ROLE→DEPTH MAP
  ------------------------------------------------------------------------------
  DROP TABLE IF EXISTS t_role_depth_map;
CREATE TABLE t_role_depth_map AS
SELECT
  ur.uniform_resource_id,
  JSON_EXTRACT(role_map.value, '$.role') AS role_name,
  CAST(
    SUBSTR(
      JSON_EXTRACT(role_map.value, '$.select'),
      INSTR(
        JSON_EXTRACT(role_map.value, '$.select'),
        'depth="'
      ) + 7,
      INSTR(
        SUBSTR(
          JSON_EXTRACT(role_map.value, '$.select'),
          INSTR(
            JSON_EXTRACT(role_map.value, '$.select'),
            'depth="'
          ) + 7
        ),
        '"'
      ) - 1
    ) AS INTEGER
  ) AS role_depth
FROM
  uniform_resource ur,
  JSON_EACH(ur.frontmatter, '$.doc-classify') AS role_map
WHERE
  ur.frontmatter IS NOT NULL;
-- 3. JSON TRAVERSAL
  ------------------------------------------------------------------------------
  DROP TABLE IF EXISTS t_all_sections_flat;
CREATE TABLE t_all_sections_flat AS
SELECT
  td.uniform_resource_id,
  td.file_basename,
  jt_title.value AS title,
  CAST(jt_depth.value AS INTEGER) AS depth,
  jt_body.value AS body_json_string
FROM
  t_raw_data td,
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
CREATE TABLE t_all_sections AS
SELECT
  s.uniform_resource_id,
  s.file_basename,
  s.depth,
  s.title,
  s.body_json_string,
  -- Extract @id (Test Case ID)
  TRIM(
    SUBSTR(
      s.body_json_string,
      INSTR(s.body_json_string, '@id') + 4,
      INSTR(
        SUBSTR(
          s.body_json_string,
          INSTR(s.body_json_string, '@id') + 4
        ),
        '"'
      ) - 1
    )
  ) AS extracted_id,
  -- Extract and normalize YAML/code content
  CASE
    WHEN INSTR(s.body_json_string, '"code":"') > 0 THEN REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        SUBSTR(
                          s.body_json_string,
                          INSTR(s.body_json_string, '"code":"') + 8,
                          INSTR(s.body_json_string, '","type":') - (INSTR(s.body_json_string, '"code":"') + 8)
                        ),
                        'Tags:',
                        CHAR(10) || 'Tags:'
                      ),
                      'Scenario Type:',
                      CHAR(10) || 'Scenario Type:'
                    ),
                    'Priority:',
                    CHAR(10) || 'Priority:'
                  ),
                  'requirementID:',
                  CHAR(10) || 'requirementID:'
                ),
                -- IMPORTANT: cycle-date MUST come before cycle
                'cycle-date:',
                CHAR(10) || 'cycle-date:'
              ),
              'cycle:',
              CHAR(10) || 'cycle:'
            ),
            'severity:',
            CHAR(10) || 'severity:'
          ),
          'assignee:',
          CHAR(10) || 'assignee:'
        ),
        'status:',
        CHAR(10) || 'status:'
      ),
      'issue_id:',
      CHAR(10) || 'issue_id:'
    )
    ELSE NULL
  END AS code_content,
  rm.role_name
FROM
  t_all_sections_flat s
  LEFT JOIN t_role_depth_map rm ON s.uniform_resource_id = rm.uniform_resource_id
  AND s.depth = rm.role_depth;
-- 5. EVIDENCE HISTORY JSON ARRAY (Aggregates all evidence history)
  ------------------------------------------------------------------------------
  -- Logic for cycle, severity, assignee, and status parsing is retained from previous fix.
  DROP TABLE IF EXISTS t_evidence_history_json;
CREATE TABLE t_evidence_history_json AS WITH evidence_positions AS (
    -- Stage 1A: Calculate extraction positions safely in a separate CTE
    SELECT
      tas.uniform_resource_id,
      tas.extracted_id AS test_case_id,
      tas.file_basename,
      tas.code_content,
      -- Find end positions for parsing logic
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'severity:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'severity:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'assignee:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_cycle_pos,
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'assignee:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_severity_pos,
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_assignee_pos,
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_status_pos,
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'created_date:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'created_date:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_issue_id_pos
    FROM
      t_all_sections tas
    WHERE
      tas.role_name = 'evidence'
      AND tas.extracted_id IS NOT NULL
      AND tas.code_content IS NOT NULL
  ),
  evidence_temp AS (
    -- Stage 1B: Extract fields using calculated positions
    SELECT
      ep.uniform_resource_id,
      ep.test_case_id,
      ep.file_basename,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'cycle:') + 6,
          ep.end_of_cycle_pos - (INSTR(ep.code_content, 'cycle:') + 6)
        )
      ) AS val_cycle,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'severity:') + 9,
          ep.end_of_severity_pos - (INSTR(ep.code_content, 'severity:') + 9)
        )
      ) AS val_severity,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'assignee:') + 9,
          ep.end_of_assignee_pos - (INSTR(ep.code_content, 'assignee:') + 9)
        )
      ) AS val_assignee,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'status:') + 7,
          ep.end_of_status_pos - (INSTR(ep.code_content, 'status:') + 7)
        )
      ) AS val_status,
      CASE
        WHEN INSTR(ep.code_content, 'issue_id:') > 0 THEN TRIM(
          SUBSTR(
            ep.code_content,
            INSTR(ep.code_content, 'issue_id:') + 9,
            ep.end_of_issue_id_pos - (INSTR(ep.code_content, 'issue_id:') + 9)
          )
        )
        ELSE ''
      END AS val_issue_id,
      CASE
        WHEN INSTR(ep.code_content, 'created_date:') > 0 THEN TRIM(
          SUBSTR(
            ep.code_content,
            INSTR(ep.code_content, 'created_date:') + 13
          )
        )
        ELSE NULL
      END AS val_created_date
    FROM
      evidence_positions ep
  ) -- Stage 2: Aggregate the extracted values into a structured JSON string (array)
SELECT
  et.uniform_resource_id,
  et.test_case_id,
  '[' || GROUP_CONCAT(
    JSON_OBJECT(
      'cycle',
      et.val_cycle,
      'severity',
      et.val_severity,
      'assignee',
      et.val_assignee,
      'status',
      et.val_status,
      'issue_id',
      et.val_issue_id,
      'created_date',
      et.val_created_date,
      'file_basename',
      et.file_basename
    ),
    ','
  ) || ']' AS evidence_history_json
FROM
  evidence_temp et
GROUP BY
  et.uniform_resource_id,
  et.test_case_id;
-- 5.5 LATEST EVIDENCE STATUS (Finds the single latest record for each test case PER FILE)
  ------------------------------------------------------------------------------
  DROP TABLE IF EXISTS t_latest_evidence_status;
CREATE TABLE t_latest_evidence_status AS WITH evidence_positions AS (
    SELECT
      tas.uniform_resource_id,
      tas.file_basename,
      tas.extracted_id AS test_case_id,
      tas.code_content,
      -- End position for cycle
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'cycle-date:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'cycle-date:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'severity:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'severity:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'assignee:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_cycle_pos,
      -- End position for cycle-date
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'severity:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'severity:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'assignee:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_cycle_date_pos,
      -- End position for severity
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'assignee:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_severity_pos,
      -- End position for assignee
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'status:')
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_assignee_pos,
      -- End position for status
      CASE
        WHEN INSTR(tas.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(tas.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(tas.code_content) + 1
      END AS end_of_status_pos
    FROM
      t_all_sections tas
    WHERE
      tas.role_name = 'evidence'
      AND tas.extracted_id IS NOT NULL
      AND tas.code_content IS NOT NULL
  ),
  evidence_details AS (
    SELECT
      ep.uniform_resource_id,
      ep.file_basename,
      ep.test_case_id,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'cycle:') + 6,
          ep.end_of_cycle_pos - (INSTR(ep.code_content, 'cycle:') + 6)
        )
      ) AS val_cycle,
      CASE
        WHEN INSTR(ep.code_content, 'cycle-date:') > 0 THEN TRIM(
          SUBSTR(
            ep.code_content,
            INSTR(ep.code_content, 'cycle-date:') + 11,
            ep.end_of_cycle_date_pos - (INSTR(ep.code_content, 'cycle-date:') + 11)
          )
        )
      END AS val_cycle_date,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'severity:') + 9,
          ep.end_of_severity_pos - (INSTR(ep.code_content, 'severity:') + 9)
        )
      ) AS val_severity,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'assignee:') + 9,
          ep.end_of_assignee_pos - (INSTR(ep.code_content, 'assignee:') + 9)
        )
      ) AS val_assignee,
      TRIM(
        SUBSTR(
          ep.code_content,
          INSTR(ep.code_content, 'status:') + 7,
          ep.end_of_status_pos - (INSTR(ep.code_content, 'status:') + 7)
        )
      ) AS val_status,
      CASE
        WHEN INSTR(ep.code_content, 'issue_id:') > 0 THEN TRIM(
          SUBSTR(
            ep.code_content,
            INSTR(ep.code_content, 'issue_id:') + 9
          )
        )
        ELSE ''
      END AS val_issue_id
    FROM
      evidence_positions ep
  ),
  ranked_evidence AS (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY uniform_resource_id,
        test_case_id
        ORDER BY
          val_cycle DESC
      ) AS rn
    FROM
      evidence_details
  )
SELECT
  uniform_resource_id,
  test_case_id,
  file_basename AS latest_file_basename,
  val_cycle AS latest_cycle,
  val_cycle_date AS latest_cycle_date,
  val_severity AS latest_severity,
  val_assignee AS latest_assignee,
  val_status AS latest_status,
  val_issue_id AS latest_issue_id
FROM
  ranked_evidence
WHERE
  rn = 1;
-- 6. TEST CASE DETAILS (Aggregates case details and latest evidence status)
  ------------------------------------------------------------------------------
  DROP VIEW IF EXISTS v_test_case_details;
CREATE VIEW v_test_case_details AS
SELECT
  s.uniform_resource_id,
  s.file_basename,
  s.extracted_id AS test_case_id,
  s.title AS test_case_title,
  -- Dynamic Status and Severity pulled from the latest evidence record
  les.latest_status AS test_case_status,
  -- Status from latest evidence is the most appropriate dynamic status
  les.latest_severity AS severity,
  -- Severity from latest evidence
  les.latest_cycle,
  les.latest_assignee,
  les.latest_issue_id,
  /*CASE
          WHEN INSTR(s.code_content, 'requirementID:') > 0 THEN
             TRIM(SUBSTR(s.code_content, INSTR(s.code_content, 'requirementID:') + 14,    INSTR(s.code_content, 'Priority:') -(15+INSTR(s.code_content, 'requirementID:')) ))    
             else  '' end as requirement_ID  */
  CASE
    WHEN INSTR(s.code_content, 'requirementID:') > 0 THEN TRIM(
      SUBSTR(
        s.code_content,
        INSTR(lower(s.code_content), 'requirementid:') + 14,
        INSTR(lower(s.code_content), 'priority:') -(
          15 + INSTR(lower(s.code_content), 'requirementid:')
        )
      )
    )
    else ''
  end as requirement_ID
FROM
  t_all_sections s
  LEFT JOIN t_latest_evidence_status les ON s.uniform_resource_id = les.uniform_resource_id
  AND s.extracted_id = les.test_case_id
WHERE
  s.role_name = 'case'
  AND s.extracted_id IS NOT NULL;
DROP VIEW IF EXISTS v_section_hierarchy_summary;
CREATE VIEW v_section_hierarchy_summary AS
SELECT
  s.file_basename,
  (
    SELECT
      title
    FROM
      t_all_sections p
    WHERE
      p.uniform_resource_id = s.uniform_resource_id
      AND p.role_name = 'project'
    ORDER BY
      p.depth
    LIMIT
      1
  ) AS project_title,
  -- Concatenate inner section titles (Strategy, Plan, Suite) to show hierarchy
  GROUP_CONCAT(
    CASE
      s.role_name
      WHEN 'strategy' THEN 'Strategy: ' || s.title
      WHEN 'plan' THEN 'Plan: ' || s.title
      WHEN 'suite' THEN 'Suite: ' || s.title
      ELSE NULL
    END,
    ' | '
  ) AS inner_sections,
  -- Count the number of test cases associated with this file
  COUNT(
    CASE
      WHEN s.role_name = 'case' THEN 1
      ELSE NULL
    END
  ) AS test_case_count
FROM
  t_all_sections s
GROUP BY
  s.uniform_resource_id,
  s.file_basename;
DROP VIEW IF EXISTS v_success_percentage;
CREATE VIEW v_success_percentage AS
SELECT
  COUNT(
    CASE
      WHEN test_case_status = 'passed' THEN 1
    END
  ) AS successful_cases,
  COUNT(
    CASE
      WHEN test_case_status = 'failed' THEN 1
    END
  ) AS failed_cases,
  COUNT(*) AS total_cases,
  ROUND(
    (
      COUNT(
        CASE
          WHEN test_case_status = 'passed' THEN 1
        END
      ) * 100.0
    ) / COUNT(*)
  ) || '%' AS success_percentage,
  ROUND(
    (
      COUNT(
        CASE
          WHEN test_case_status = 'failed' THEN 1
        END
      ) * 100.0
    ) / COUNT(*)
  ) || '%' AS failed_percentage
FROM
  v_test_case_details;
DROP VIEW IF EXISTS v_test_assignee;
CREATE VIEW v_test_assignee as
select
  'ALL' as assignee
union all
select
  distinct latest_assignee as assignee
from
  v_test_case_details;
-- 7. OPEN ISSUES AGE TRACKING
  ------------------------------------------------------------------------------
  DROP TABLE IF EXISTS t_issues;
CREATE TABLE t_issues AS WITH issue_code_blocks AS (
    --------------------------------------------------------------------------
    -- 1. Extract issue code blocks and NORMALIZE YAML (one key per line)
    --------------------------------------------------------------------------
    SELECT
      DISTINCT td.uniform_resource_id,
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  JSON_EXTRACT(code_node.value, '$.code'),
                  'issue_id:',
                  CHAR(10) || 'issue_id:'
                ),
                'created_date:',
                CHAR(10) || 'created_date:'
              ),
              'test_case_id:',
              CHAR(10) || 'test_case_id:'
            ),
            'status:',
            CHAR(10) || 'status:'
          ),
          'title:',
          CHAR(10) || 'title:'
        ),
        'role:',
        CHAR(10) || 'role:'
      ) AS issue_yaml_code
    FROM
      t_raw_data td,
      JSON_TREE(td.cleaned_json_text, '$') AS code_node
    WHERE
      code_node.key = 'code_block'
      AND JSON_EXTRACT(code_node.value, '$.code') LIKE '%role: issue%'
  ),
  parsed_issues AS (
    --------------------------------------------------------------------------
    -- 2. Extract each field independently (NO ordering assumptions)
    --------------------------------------------------------------------------
    SELECT
      uniform_resource_id,
      -- issue_id
      TRIM(
        SUBSTR(
          issue_yaml_code,
          INSTR(issue_yaml_code, CHAR(10) || 'issue_id:') + 11,
          INSTR(
            SUBSTR(
              issue_yaml_code,
              INSTR(issue_yaml_code, CHAR(10) || 'issue_id:') + 11
            ),
            CHAR(10)
          ) - 1
        )
      ) AS issue_id,
      -- test_case_id
      TRIM(
        SUBSTR(
          issue_yaml_code,
          INSTR(issue_yaml_code, CHAR(10) || 'test_case_id:') + 14,
          INSTR(
            SUBSTR(
              issue_yaml_code,
              INSTR(issue_yaml_code, CHAR(10) || 'test_case_id:') + 14
            ),
            CHAR(10)
          ) - 1
        )
      ) AS test_case_id,
      -- status
      -- status (FIXED)
      CASE
        WHEN INSTR(issue_yaml_code, CHAR(10) || 'status:') > 0 THEN TRIM(
          SUBSTR(
            issue_yaml_code,
            INSTR(issue_yaml_code, CHAR(10) || 'status:') + 9,
            CASE
              WHEN INSTR(
                SUBSTR(
                  issue_yaml_code,
                  INSTR(issue_yaml_code, CHAR(10) || 'status:') + 9
                ),
                CHAR(10)
              ) > 0 THEN INSTR(
                SUBSTR(
                  issue_yaml_code,
                  INSTR(issue_yaml_code, CHAR(10) || 'status:') + 9
                ),
                CHAR(10)
              ) - 1
              ELSE LENGTH(issue_yaml_code)
            END
          )
        )
        ELSE NULL
      END AS status,
      -- created_date
      -- created_date (FIXED & SAFE)
      CASE
        WHEN INSTR(issue_yaml_code, CHAR(10) || 'created_date:') > 0 THEN TRIM(
          SUBSTR(
            issue_yaml_code,
            INSTR(issue_yaml_code, CHAR(10) || 'created_date:') + 14,
            CASE
              WHEN INSTR(
                SUBSTR(
                  issue_yaml_code,
                  INSTR(issue_yaml_code, CHAR(10) || 'created_date:') + 14
                ),
                CHAR(10)
              ) > 0 THEN INSTR(
                SUBSTR(
                  issue_yaml_code,
                  INSTR(issue_yaml_code, CHAR(10) || 'created_date:') + 14
                ),
                CHAR(10)
              ) - 1
              ELSE LENGTH(issue_yaml_code)
            END
          )
        )
        ELSE NULL
      END AS created_date
    FROM
      issue_code_blocks
  ) -- 3. Final cleanup (guard against malformed blocks)
  --------------------------------------------------------------------------
SELECT
  uniform_resource_id,
  issue_id,
  test_case_id,
  LOWER(status) AS status,
  created_date
FROM
  parsed_issues
WHERE
  issue_id IS NOT NULL
  AND test_case_id IS NOT NULL;
DROP VIEW IF EXISTS v_open_issues_age;
CREATE VIEW v_open_issues_age AS
SELECT
  iss.issue_id,
  iss.created_date,
  iss.test_case_id,
  CAST(
    JULIANDAY('now') - JULIANDAY(
      -- Convert MM-DD-YYYY to YYYY-MM-DD format
      SUBSTR(iss.created_date, 7, 4) || '-' || SUBSTR(iss.created_date, 1, 2) || '-' || SUBSTR(iss.created_date, 4, 2)
    ) AS INTEGER
  ) AS total_days,
  tcd.test_case_title AS test_case_description
FROM
  t_issues iss
  LEFT JOIN v_test_case_details tcd ON iss.test_case_id = tcd.test_case_id
WHERE
  iss.status = 'open'
  AND iss.created_date IS NOT NULL
ORDER BY
  total_days DESC;


  --history--
DROP VIEW IF EXISTS v_evidence_history_complete;
 
CREATE VIEW v_evidence_history_complete AS
 
WITH raw_transform_data AS (
    SELECT distinct
        ur.uniform_resource_id,
        ur.uri,
        ur.last_modified_at,
        urt.uniform_resource_transform_id,
        urpe.file_basename,
 
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        SUBSTR(CAST(urt.content AS TEXT), 2, LENGTH(CAST(urt.content AS TEXT)) - 2),
                        CHAR(10), ''
                    ),
                    CHAR(13), ''
                ),
                '\x22', '"'
            ),
            '\n', ''
        ) AS cleaned_json_text
    FROM uniform_resource_transform urt
    JOIN uniform_resource ur
        ON ur.uniform_resource_id = urt.uniform_resource_id
    JOIN ur_ingest_session_fs_path_entry urpe
        ON ur.uniform_resource_id = urpe.uniform_resource_id
    WHERE ur.last_modified_at IS NOT NULL
),
 
role_depth_mapping AS (
    SELECT
        ur.uniform_resource_id,
        JSON_EXTRACT(role_map.value, '$.role') AS role_name,
        CAST(
            SUBSTR(
                JSON_EXTRACT(role_map.value, '$.select'),
                INSTR(JSON_EXTRACT(role_map.value, '$.select'), 'depth="') + 7,
                INSTR(
                    SUBSTR(
                        JSON_EXTRACT(role_map.value, '$.select'),
                        INSTR(JSON_EXTRACT(role_map.value, '$.select'), 'depth="') + 7
                    ),
                    '"'
                ) - 1
            ) AS INTEGER
        ) AS role_depth
    FROM uniform_resource ur,
         JSON_EACH(ur.frontmatter, '$.doc-classify') AS role_map
    WHERE ur.frontmatter IS NOT NULL
),
 
sections_parsed AS (
    SELECT
        rtd.uniform_resource_id,
        rtd.uniform_resource_transform_id,
        rtd.file_basename,
        rtd.last_modified_at,
        jt_title.value AS title,
        CAST(jt_depth.value AS INTEGER) AS depth,
        jt_body.value AS body_json_string
    FROM raw_transform_data rtd,
         json_tree(rtd.cleaned_json_text, '$') AS jt_section,
         json_tree(rtd.cleaned_json_text, '$') AS jt_depth,
         json_tree(rtd.cleaned_json_text, '$') AS jt_title,
         json_tree(rtd.cleaned_json_text, '$') AS jt_body
    WHERE jt_section.key = 'section'
      AND jt_depth.parent = jt_section.id AND jt_depth.key = 'depth'
      AND jt_title.parent = jt_section.id AND jt_title.key = 'title'
      AND jt_body.parent = jt_section.id AND jt_body.key = 'body'
),
 
sections_with_roles AS (
    SELECT
        sp.uniform_resource_id,
        sp.uniform_resource_transform_id,
        sp.file_basename,
        sp.last_modified_at,
        sp.depth,
        sp.title,
        sp.body_json_string,
 
        TRIM(
            SUBSTR(
                sp.body_json_string,
                INSTR(sp.body_json_string, '@id') + 4,
                INSTR(
                    SUBSTR(sp.body_json_string, INSTR(sp.body_json_string, '@id') + 4),
                    '"'
                ) - 1
            )
        ) AS extracted_id,
 
       CASE
        WHEN INSTR(sp.body_json_string, '"code":"') > 0 THEN
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    SUBSTR(
                                                        sp.body_json_string,
                                                        INSTR(sp.body_json_string, '"code":"') + 8,
                                                        INSTR(sp.body_json_string, '","type":')
                                                        - (INSTR(sp.body_json_string, '"code":"') + 8)
                                                    ),
                                                    'Tags:', CHAR(10) || 'Tags:'
                                                ),
                                                'Scenario Type:', CHAR(10) || 'Scenario Type:'
                                            ),
                                            'Priority:', CHAR(10) || 'Priority:'
                                        ),
                                        'requirementID:', CHAR(10) || 'requirementID:'
                                    ),
                                    -- IMPORTANT: cycle-date MUST come before cycle
                                    'cycle-date:', CHAR(10) || 'cycle-date:'
                                ),
                                'cycle:', CHAR(10) || 'cycle:'
                            ),
                            'severity:', CHAR(10) || 'severity:'
                        ),
                        'assignee:', CHAR(10) || 'assignee:'
                    ),
                    'status:', CHAR(10) || 'status:'
                ),
                'issue_id:', CHAR(10) || 'issue_id:'
            )
        ELSE NULL
    END AS code_content,
 
        rdm.role_name
    FROM sections_parsed sp
    LEFT JOIN role_depth_mapping rdm
        ON sp.uniform_resource_id = rdm.uniform_resource_id
       AND sp.depth = rdm.role_depth
),
 
-- ✅ NEW: case title lookup
case_titles AS (
    SELECT
        uniform_resource_id,
        extracted_id AS test_case_id,
        title AS test_case_title
    FROM sections_with_roles
    WHERE role_name = 'case'
      AND extracted_id IS NOT NULL
),
 
evidence_extraction_positions AS (
    SELECT
        swr.uniform_resource_id,
        swr.uniform_resource_transform_id,
        swr.file_basename,
        swr.last_modified_at,
        swr.extracted_id AS test_case_id,
        swr.code_content,
 
        CASE
             WHEN INSTR(swr.code_content, CHAR(10) || 'cycle-date:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'cycle-date:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'severity:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'severity:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'assignee:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'status:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'issue_id:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'requirementID:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'requirementID:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'Priority:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'Priority:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'Tags:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'Tags:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'Scenario Type:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'Scenario Type:')
            ELSE LENGTH(swr.code_content) + 1
        END AS end_of_cycle_pos,
 
        CASE
            WHEN INSTR(swr.code_content, CHAR(10) || 'assignee:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'assignee:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'status:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(swr.code_content) + 1
        END AS end_of_severity_pos,
 
        CASE
            WHEN INSTR(swr.code_content, CHAR(10) || 'status:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'status:')
            WHEN INSTR(swr.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(swr.code_content) + 1
        END AS end_of_assignee_pos,
 
        CASE
            WHEN INSTR(swr.code_content, CHAR(10) || 'issue_id:') > 0 THEN INSTR(swr.code_content, CHAR(10) || 'issue_id:')
            ELSE LENGTH(swr.code_content) + 1
        END AS end_of_status_pos,
 
        -- ✅ NEW: end of cycle-date
CASE
    WHEN INSTR(swr.code_content, CHAR(10) || 'cycle:') > INSTR(swr.code_content, 'cycle-date:')
    THEN INSTR(swr.code_content, CHAR(10) || 'cycle:')
 
    WHEN INSTR(swr.code_content, CHAR(10) || 'severity:') > INSTR(swr.code_content, 'cycle-date:')
    THEN INSTR(swr.code_content, CHAR(10) || 'severity:')
 
    WHEN INSTR(swr.code_content, CHAR(10) || 'assignee:') > INSTR(swr.code_content, 'cycle-date:')
    THEN INSTR(swr.code_content, CHAR(10) || 'assignee:')
 
    WHEN INSTR(swr.code_content, CHAR(10) || 'status:') > INSTR(swr.code_content, 'cycle-date:')
    THEN INSTR(swr.code_content, CHAR(10) || 'status:')
 
    WHEN INSTR(swr.code_content, CHAR(10) || 'issue_id:') > INSTR(swr.code_content, 'cycle-date:')
    THEN INSTR(swr.code_content, CHAR(10) || 'issue_id:')
 
    ELSE LENGTH(swr.code_content) + 1
END AS end_of_cycle_date_pos
 
    FROM sections_with_roles swr
    WHERE swr.role_name = 'evidence'
      AND swr.extracted_id IS NOT NULL
      AND swr.code_content IS NOT NULL
)
 
SELECT
    eep.uniform_resource_id,
    eep.uniform_resource_transform_id,
    eep.file_basename,
    eep.last_modified_at AS ingestion_timestamp,
    eep.test_case_id,
    ct.test_case_title,            -- ✅ ADDED
 
    CASE
        WHEN TRIM(SUBSTR(
            eep.code_content,
            INSTR(eep.code_content, 'cycle:') + 6,
            eep.end_of_cycle_pos - (INSTR(eep.code_content, 'cycle:') + 6)
        )) LIKE '%:%'
        THEN NULL
        ELSE TRIM(SUBSTR(
            eep.code_content,
            INSTR(eep.code_content, 'cycle:') + 6,
            eep.end_of_cycle_pos - (INSTR(eep.code_content, 'cycle:') + 6)
        ))
    END AS latest_cycle,
 
    TRIM(SUBSTR(eep.code_content, INSTR(eep.code_content, 'severity:') + 9,
         eep.end_of_severity_pos - (INSTR(eep.code_content, 'severity:') + 9))) AS severity,
 
    TRIM(SUBSTR(eep.code_content, INSTR(eep.code_content, 'assignee:') + 9,
         eep.end_of_assignee_pos - (INSTR(eep.code_content, 'assignee:') + 9))) AS assignee,
 
    TRIM(SUBSTR(eep.code_content, INSTR(eep.code_content, 'status:') + 7,
         eep.end_of_status_pos - (INSTR(eep.code_content, 'status:') + 7))) AS status,
 
    CASE
        WHEN INSTR(eep.code_content, 'issue_id:') > 0
        THEN TRIM(SUBSTR(eep.code_content, INSTR(eep.code_content, 'issue_id:') + 9))
        ELSE NULL
    END AS issue_id,
    CASE
    WHEN INSTR(eep.code_content, 'cycle-date:') > 0
    THEN TRIM(
        SUBSTR(
            eep.code_content,
            INSTR(eep.code_content, 'cycle-date:') + 11,
            eep.end_of_cycle_date_pos
              - (INSTR(eep.code_content, 'cycle-date:') + 11)
        )
    )
    ELSE NULL
END AS cycle_date
 
FROM evidence_extraction_positions eep
LEFT JOIN case_titles ct
    ON ct.uniform_resource_id = eep.uniform_resource_id
   AND ct.test_case_id = eep.test_case_id
 
ORDER BY eep.test_case_id, eep.last_modified_at DESC, latest_cycle DESC;


DROP VIEW IF EXISTS v_latest_ingested_cycle_summary;
 
CREATE VIEW v_latest_ingested_cycle_summary AS
WITH last_changed_cycle AS (
    SELECT
        latest_cycle
    FROM v_evidence_history_complete
    WHERE latest_cycle IS NOT NULL
      AND latest_cycle != ''
    ORDER BY ingestion_timestamp DESC
    LIMIT 1
)
SELECT
    tcd.latest_cycle,
 
    SUM(tcd.test_case_status = 'passed')  AS passed_count,
    SUM(tcd.test_case_status = 'failed')  AS failed_count,
    SUM(tcd.test_case_status = 'reopen')  AS reopen_count,
    SUM(tcd.test_case_status = 'closed')  AS closed_count,
 
    COUNT(tcd.test_case_id) AS test_count
 
FROM v_test_case_details tcd
JOIN last_changed_cycle lcc
  ON tcd.latest_cycle = lcc.latest_cycle
 
GROUP BY tcd.latest_cycle;


--RAHUL WORKS

DROP VIEW IF EXISTS v_sections_case_summary_depth;
CREATE VIEW v_sections_case_summary_depth AS
SELECT DISTINCT
    file_basename,
    role_name   AS rolename,
    depth
FROM t_all_sections
WHERE role_name = 'case'; 

DROP VIEW IF EXISTS v_case_details;
CREATE VIEW v_case_details AS
SELECT
    v.file_basename,
    v.rolename,
    v.depth,
    s.title,
    s.body_json_string,
    s.extracted_id  AS code,
    s.code_content  AS content
FROM v_sections_case_summary_depth v
JOIN t_all_sections s
      ON  s.file_basename = v.file_basename
      AND s.depth        = v.depth
      AND s.role_name    = v.rolename; 


-- Drop old view if you’re iterating
DROP VIEW IF EXISTS v_case_summary;

CREATE VIEW v_case_summary AS
SELECT
    file_basename,
    extracted_id  AS code,
    code_content  AS content,
    depth,

    -- Test Case ID: "@id TC-BCTM-0037"  -> "TC-BCTM-0037"
    REPLACE(
        json_extract(body_json_string, '$[0].paragraph'),
        '@id ',
        ''
    ) AS test_case_id,

    -- Description (index 3)
    json_extract(body_json_string, '$[3].paragraph') AS description,

    -- Preconditions list (index 5)
    json_extract(body_json_string, '$[5].list')      AS preconditions,

    -- Steps list (index 7)
    json_extract(body_json_string, '$[7].list')      AS steps,

    -- Expected Results list (index 9)
    json_extract(body_json_string, '$[9].list')      AS expected_results,

    -- Single JSON object with everything
    json_object(
        'test_case_id',     REPLACE(json_extract(body_json_string, '$[0].paragraph'), '@id ', ''),
        'description',      json_extract(body_json_string, '$[3].paragraph'),
        'preconditions',    json_extract(body_json_string, '$[5].list'),
        'steps',            json_extract(body_json_string, '$[7].list'),
        'expected_results', json_extract(body_json_string, '$[9].list'),
        'file_basename',    file_basename,
        'code',             extracted_id,
        'content',          code_content,
        'depth',            depth
    ) AS case_summary_json

FROM t_all_sections
WHERE role_name = 'case';

      