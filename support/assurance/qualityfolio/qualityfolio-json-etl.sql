CREATE TABLE IF NOT EXISTS commit_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    commit_sha TEXT,
    filename TEXT,
    status TEXT,
    additions INTEGER,
    deletions INTEGER,
    patch TEXT,
    file_details text
);

-- CREATE VIEW in case singer tap didn't run, so queries don't crash
CREATE VIEW IF NOT EXISTS github_commits AS 
SELECT NULL AS id, NULL AS sha, '{}' AS "commit", NULL AS html_url, '[]' AS files WHERE 1=0;

-- SQLITE ETL SCRIPT — FINAL MODIFIED VERSION (Relying on Evidence Status)
-- 1. CLEAN AND PARSE THE RAW CONTENT
------------------------------------------------------------------------------
DROP TABLE IF EXISTS qf_markdown_master;
CREATE TABLE qf_markdown_master AS WITH ranked AS (
  SELECT
    ur.uniform_resource_id,
    ur.uri,
    ur.last_modified_at,
    urpe.file_basename,
    urpe.ingest_session_id,
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
        urpe.ingest_session_id DESC,
        ur.uniform_resource_id DESC
    ) AS rn
  FROM
    uniform_resource_transform urt
    JOIN uniform_resource ur ON ur.uniform_resource_id = urt.uniform_resource_id
    JOIN ur_ingest_session_fs_path_entry urpe ON ur.uniform_resource_id = urpe.uniform_resource_id
)
SELECT
  file_basename,
  uniform_resource_id,
  uri,
  last_modified_at,
  ingest_session_id,
  cleaned_json_text
FROM
  ranked
WHERE
  rn = 1;
-- 2. LOAD doc-classify ROLE→DEPTH MAP
  ------------------------------------------------------------------------------
  DROP TABLE IF EXISTS qf_depth_master;
CREATE TABLE qf_depth_master AS
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
  DROP TABLE IF EXISTS qf_depth;
CREATE TABLE qf_depth AS
SELECT
  td.uniform_resource_id,
  td.file_basename,
  json_extract(jt.value, '$.title') AS title,
  CAST(json_extract(jt.value, '$.depth') AS INTEGER) AS depth,
  json_extract(jt.value, '$.body') AS body_json_string
FROM
  qf_markdown_master td,
  json_tree(td.cleaned_json_text, '$') AS jt
WHERE
  jt.key = 'section';
-- 4. NORMALIZE + ROLE ATTACH & CODE EXTRACTION (CRITICAL: Robust Delimiter Injection)
  ------------------------------------------------------------------------------
  DROP TABLE IF EXISTS qf_role;
CREATE TABLE qf_role AS
select
  t.rownum,
  t.uniform_resource_id,
  t.file_basename,
  t.depth,
  t.title,
  t.body_json_string,
  t.extracted_id,
  t.code_content,
  t.role_name
from
  (
    SELECT
      ROW_NUMBER() OVER (
        ORDER BY
          s.uniform_resource_id
      ) AS rownum,
      s.uniform_resource_id,
      s.file_basename,
      s.depth,
      s.title,
      s.body_json_string,
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
                ),
                'plan-name:',
                CHAR(10) || 'plan-name:'
              ),
              'plan-date:',
              CHAR(10) || 'plan-date:'
            ),
            'created-by:',
            CHAR(10) || 'created-by:'
          ),
          'suite-name:',
          CHAR(10) || 'suite-name:'
        ),
        'suite-date:',
        CHAR(10) || 'suite-date:'
      ) AS code_content,
      rm.role_name
    FROM
      qf_depth s
      LEFT JOIN qf_depth_master rm ON s.uniform_resource_id = rm.uniform_resource_id
      AND s.depth = rm.role_depth
  ) t
where
  t.depth != 5
union all
SELECT
  ROW_NUMBER() OVER (
    ORDER BY
      s.uniform_resource_id
  ) AS rownum,
  s.uniform_resource_id,
  s.file_basename,
  s.depth,
  s.title,
  s.body_json_string,
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
                      REPLACE(
                        REPLACE(
                          REPLACE(
                            REPLACE(
                              REPLACE(
                                REPLACE(
                                  REPLACE(
                                    json_extract(value, '$.code_block'),
                                    '{"code":"',
                                    ''
                                  ),
                                  '","type":"code","language":"yaml","metadata":"HFM"}',
                                  ''
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
            ),
            'plan-name:',
            CHAR(10) || 'plan-name:'
          ),
          'plan-date:',
          CHAR(10) || 'plan-date:'
        ),
        'created-by:',
        CHAR(10) || 'created-by:'
      ),
      'suite-name:',
      CHAR(10) || 'suite-name:'
    ),
    'suite-date:',
    CHAR(10) || 'suite-date:'
  ) as code_content,
  rm.role_name
FROM
  qf_depth s
  LEFT JOIN qf_depth_master rm ON s.uniform_resource_id = rm.uniform_resource_id
  AND s.depth = rm.role_depth,
  json_each(s.body_json_string)
WHERE
  json_type(value, '$.code_block') IS NOT NULL
  and s.depth = 5;
-- 5. EVIDENCE HISTORY JSON ARRAY (Aggregates all evidence history)
  ------------------------------------------------------------------------------
  -- Logic for cycle, severity, assignee, and status parsing is retained from previous fix.
  DROP TABLE IF EXISTS qf_evidence_event;
CREATE TABLE qf_evidence_event AS WITH RECURSIVE -- Step 1: get all evidence rows with normalized code_content
  evidence_source AS (
    SELECT
      tas.uniform_resource_id,
      tas.extracted_id AS test_case_id,
      tas.file_basename,
      -- Ensure code_content starts with 'cycle:' so the splitting works uniformly.
      CASE
        WHEN SUBSTR(TRIM(tas.code_content), 1, 6) = 'cycle:' THEN TRIM(tas.code_content)
        WHEN INSTR(tas.code_content, 'cycle:') > 0 THEN SUBSTR(
          tas.code_content,
          INSTR(tas.code_content, 'cycle:')
        )
        ELSE tas.code_content
      END AS code_content
    FROM
      qf_role tas
    WHERE
      tas.role_name = 'evidence'
      AND tas.extracted_id IS NOT NULL
      AND tas.code_content IS NOT NULL
  ),
  -- Step 2: recursively split code_content on CHAR(10)||'cycle:' to get one block per cycle
  cycle_blocks(
    uniform_resource_id,
    test_case_id,
    file_basename,
    remaining,
    block
  ) AS (
    SELECT
      uniform_resource_id,
      test_case_id,
      file_basename,
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          code_content,
          INSTR(code_content, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END AS remaining,
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            code_content,
            1,
            INSTR(code_content, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(code_content)
      END AS block
    FROM
      evidence_source
    UNION ALL
    SELECT
      uniform_resource_id,
      test_case_id,
      file_basename,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          remaining,
          INSTR(remaining, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            remaining,
            1,
            INSTR(remaining, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(remaining)
      END
    FROM
      cycle_blocks
    WHERE
      remaining IS NOT NULL
  ),
  -- Step 3: parse each individual cycle block for its fields
  evidence_temp AS (
    SELECT
      uniform_resource_id,
      test_case_id,
      file_basename,
      -- cycle
      TRIM(
        REPLACE(
          SUBSTR(
            block,
            INSTR(block, 'cycle:') + 6,
            CASE
              WHEN INSTR(
                SUBSTR(block, INSTR(block, 'cycle:') + 6),
                CHAR(10)
              ) = 0 THEN LENGTH(block)
              ELSE INSTR(
                SUBSTR(block, INSTR(block, 'cycle:') + 6),
                CHAR(10)
              )
            END
          ),
          CHAR(10),
          ''
        )
      ) AS val_cycle,
      -- severity
      CASE
        WHEN INSTR(block, 'severity:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'severity:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'severity:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'severity:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS val_severity,
      -- assignee
      CASE
        WHEN INSTR(block, 'assignee:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'assignee:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'assignee:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'assignee:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS val_assignee,
      -- status
      CASE
        WHEN INSTR(block, 'status:') > 0 THEN LOWER(TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'status:') + 7,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'status:') + 7),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'status:') + 7),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        ))
        ELSE NULL
      END AS val_status,
      -- issue_id
      CASE
        WHEN INSTR(block, 'issue_id:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'issue_id:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'issue_id:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'issue_id:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE ''
      END AS val_issue_id,
      -- cycle_date (was improperly named val_created_date, now correctly handles cycle-date)
      CASE
        WHEN INSTR(block, 'cycle-date:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'cycle-date:') + 11,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'cycle-date:') + 11),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'cycle-date:') + 11),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS val_cycle_date
    FROM
      cycle_blocks
    WHERE
      block IS NOT NULL
      AND TRIM(block) != ''
      AND INSTR(block, 'cycle:') > 0
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
      et.val_cycle_date,
      'file_basename',
      et.file_basename
    ),
    ','
  ) || ']' AS evidence_history_json
FROM
  evidence_temp et
WHERE
  (
    NULLIF(et.val_cycle_date, '') IS NULL
    OR DATE(
      SUBSTR(et.val_cycle_date, 7, 4) || '-' || SUBSTR(et.val_cycle_date, 1, 2) || '-' || SUBSTR(et.val_cycle_date, 4, 2)
    ) <= DATE('now', 'localtime')
  )
GROUP BY
  et.uniform_resource_id,
  et.test_case_id;
-- 6. TEST CASE DETAILS (Aggregates case details and latest evidence status)
  ------------------------------------------------------------------------------
  DROP VIEW IF EXISTS qf_case_status;
CREATE VIEW qf_case_status AS
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
  les.latest_cycle_date,
  les.latest_assignee,
  les.latest_issue_id,
  (
    SELECT
      p.title
    FROM
      qf_role p
    WHERE
      p.uniform_resource_id = s.uniform_resource_id
      AND p.role_name = 'project'
    ORDER BY
      p.depth
    LIMIT
      1
  ) AS project_name,
  /*CASE
                  WHEN INSTR(s.code_content, 'requirementID:') > 0 THEN
                     TRIM(SUBSTR(s.code_content, INSTR(s.code_content, 'requirementID:') + 14,    INSTR(s.code_content, 'Priority:') -(15+INSTR(s.code_content, 'requirementID:')) ))    
                     else  '' end as requirement_ID  */
  CASE
    WHEN INSTR(lower(s.code_content), 'requirementid:') > 0 THEN 
      TRIM(REPLACE(REPLACE(SUBSTR(
        s.code_content,
        INSTR(lower(s.code_content), 'requirementid:') + 14,
        CASE
          WHEN INSTR(SUBSTR(lower(s.code_content), INSTR(lower(s.code_content), 'requirementid:') + 14), 'priority:') > 0
          THEN INSTR(SUBSTR(lower(s.code_content), INSTR(lower(s.code_content), 'requirementid:') + 14), 'priority:') - 1
          WHEN INSTR(SUBSTR(lower(s.code_content), INSTR(lower(s.code_content), 'requirementid:') + 14), CHAR(10)) > 0
          THEN INSTR(SUBSTR(lower(s.code_content), INSTR(lower(s.code_content), 'requirementid:') + 14), CHAR(10)) - 1
          ELSE 50
        END
      ), CHAR(10), ''), CHAR(13), ''))
    else ''
  end as requirement_ID
FROM
  qf_role s
  LEFT JOIN qf_evidence_status les ON s.uniform_resource_id = les.uniform_resource_id
  AND s.extracted_id = les.test_case_id
WHERE
  s.role_name = 'case'
  AND s.extracted_id IS NOT NULL;
DROP VIEW IF EXISTS qf_case_count;
CREATE VIEW qf_case_count AS
SELECT
  s.file_basename,
  -- Project title
  (
    SELECT
      p.title
    FROM
      qf_role p
    WHERE
      p.uniform_resource_id = s.uniform_resource_id
      AND p.role_name = 'project'
    ORDER BY
      p.depth
    LIMIT
      1
  ) AS project_title,
  -- Inner hierarchy (strategy / plan / suite)
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
  -- Test case count
  COUNT(
    CASE
      WHEN s.role_name = 'case' THEN 1
      ELSE NULL
    END
  ) AS test_case_count
FROM
  qf_role s
GROUP BY
  s.uniform_resource_id,
  s.file_basename;
-- DROP VIEW IF EXISTS qf_success_rate;
  -- CREATE VIEW qf_success_rate AS
  -- SELECT
  --   tenant_id,
  --   project_name,
  --   COUNT(
  --     CASE
  --       WHEN test_case_status = 'passed' THEN 1
  --     END
  --   ) AS successful_cases,
  --   COUNT(
  --     CASE
  --       WHEN test_case_status = 'failed' THEN 1
  --     END
  --   ) AS failed_cases,
  --   COUNT(*) AS total_cases,
  --   ROUND(
  --     (
  --       COUNT(
  --         CASE
  --           WHEN test_case_status = 'passed' THEN 1
  --         END
  --       ) * 100.0
  --     ) / COUNT(*)
  --   ) || '%' AS success_percentage,
  --   ROUND(
  --     (
  --       COUNT(
  --         CASE
  --           WHEN test_case_status = 'failed' THEN 1
  --         END
  --       ) * 100.0
  --     ) / COUNT(*)
  --   ) || '%' AS failed_percentage
  -- FROM
  --   qf_case_status
  -- GROUP BY
  --   tenant_id, project_name;
  DROP VIEW IF EXISTS qf_success_rate;
CREATE VIEW qf_success_rate AS
SELECT
  project_name,
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
  COUNT(CASE WHEN COALESCE(LOWER(test_case_status), '') NOT IN ('closed', 'todo', 'to-do', 'to do', '') THEN 1 END) AS total_cases,
  ROUND(
    COUNT(
      CASE
        WHEN test_case_status = 'passed' THEN 1
      END
    ) * 100.0 / NULLIF(COUNT(CASE WHEN COALESCE(LOWER(test_case_status), '') NOT IN ('closed', 'todo', 'to-do', 'to do', '') THEN 1 END), 0),
    2
  ) AS success_percentage,
  ROUND(
    COUNT(
      CASE
        WHEN test_case_status = 'failed' THEN 1
      END
    ) * 100.0 / NULLIF(COUNT(CASE WHEN COALESCE(LOWER(test_case_status), '') NOT IN ('closed', 'todo', 'to-do', 'to do', '') THEN 1 END), 0),
    2
  ) AS failed_percentage
FROM
  qf_case_status
GROUP BY
  project_name;
-- ASSIGNEE MASTER
  -- DROP VIEW IF EXISTS qf_assignee_master;
  -- CREATE VIEW qf_assignee_master as
  -- select
  --   'ALL' as assignee
  -- union all
  -- select
  --   distinct latest_assignee as assignee
  -- from
  --   qf_case_status;
  -- 7. OPEN ISSUES AGE TRACKING
  ------------------------------------------------------------------------------
  DROP TABLE IF EXISTS qf_issue;
CREATE TABLE qf_issue AS WITH issue_code_blocks AS (
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
      qf_markdown_master td,
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
-- AGE WISE OPEN ISSUES
  DROP VIEW IF EXISTS qf_open_issue_age;
CREATE VIEW qf_open_issue_age AS
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
  tcd.test_case_title AS test_case_description,
  tcd.project_name
FROM
  qf_issue iss
  LEFT JOIN qf_case_status tcd ON iss.test_case_id = tcd.test_case_id
WHERE
  iss.status = 'open'
  AND iss.created_date IS NOT NULL
ORDER BY
  total_days DESC;
--history--
  DROP VIEW IF EXISTS qf_evidence_history;
CREATE VIEW qf_evidence_history AS WITH raw_transform_data AS (
    SELECT
      distinct ur.uniform_resource_id,
      ur.uri,
      ur.created_at,
      urt.uniform_resource_transform_id,
      urpe.file_basename,
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
          '"'
        ),
        '\n',
        ''
      ) AS cleaned_json_text
    FROM
      uniform_resource_transform urt
      JOIN uniform_resource ur ON ur.uniform_resource_id = urt.uniform_resource_id
      JOIN ur_ingest_session_fs_path_entry urpe ON ur.uniform_resource_id = urpe.uniform_resource_id
    WHERE
      ur.last_modified_at IS NOT NULL
  ),
  role_depth_mapping AS (
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
      ur.frontmatter IS NOT NULL
  ),
  sections_parsed AS (
    SELECT
      rtd.uniform_resource_id,
      rtd.uniform_resource_transform_id,
      rtd.file_basename,
      rtd.created_at AS last_modified_at,
      jt_title.value AS title,
      CAST(jt_depth.value AS INTEGER) AS depth,
      jt_body.value AS body_json_string
    FROM
      raw_transform_data rtd,
      json_tree(rtd.cleaned_json_text, '$') AS jt_section,
      json_tree(rtd.cleaned_json_text, '$') AS jt_depth,
      json_tree(rtd.cleaned_json_text, '$') AS jt_title,
      json_tree(rtd.cleaned_json_text, '$') AS jt_body
    WHERE
      jt_section.key = 'section'
      AND jt_depth.parent = jt_section.id
      AND jt_depth.key = 'depth'
      AND jt_title.parent = jt_section.id
      AND jt_title.key = 'title'
      AND jt_body.parent = jt_section.id
      AND jt_body.key = 'body'
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
            SUBSTR(
              sp.body_json_string,
              INSTR(sp.body_json_string, '@id') + 4
            ),
            '"'
          ) - 1
        )
      ) AS extracted_id,
      CASE
        WHEN INSTR(sp.body_json_string, '"code":"') > 0 THEN REPLACE(
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
                              INSTR(sp.body_json_string, '","type":') - (INSTR(sp.body_json_string, '"code":"') + 8)
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
        ) -- Append second code block if present
        || CASE
          WHEN INSTR(
            SUBSTR(
              sp.body_json_string,
              INSTR(sp.body_json_string, '","type":') + 9
            ),
            '"code":"'
          ) > 0 THEN CHAR(10) || REPLACE(
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
                                SUBSTR(
                                  sp.body_json_string,
                                  INSTR(sp.body_json_string, '","type":') + 9
                                ),
                                INSTR(
                                  SUBSTR(
                                    sp.body_json_string,
                                    INSTR(sp.body_json_string, '","type":') + 9
                                  ),
                                  '"code":"'
                                ) + 8,
                                CASE
                                  WHEN INSTR(
                                    SUBSTR(
                                      SUBSTR(
                                        sp.body_json_string,
                                        INSTR(sp.body_json_string, '","type":') + 9
                                      ),
                                      INSTR(
                                        SUBSTR(
                                          sp.body_json_string,
                                          INSTR(sp.body_json_string, '","type":') + 9
                                        ),
                                        '"code":"'
                                      ) + 8
                                    ),
                                    '","type":'
                                  ) > 0 THEN INSTR(
                                    SUBSTR(
                                      SUBSTR(
                                        sp.body_json_string,
                                        INSTR(sp.body_json_string, '","type":') + 9
                                      ),
                                      INSTR(
                                        SUBSTR(
                                          sp.body_json_string,
                                          INSTR(sp.body_json_string, '","type":') + 9
                                        ),
                                        '"code":"'
                                      ) + 8
                                    ),
                                    '","type":'
                                  ) - 1
                                  ELSE LENGTH(sp.body_json_string)
                                END
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
          ELSE ''
        END
        ELSE NULL
      END AS code_content,
      rdm.role_name
    FROM
      sections_parsed sp
      LEFT JOIN role_depth_mapping rdm ON sp.uniform_resource_id = rdm.uniform_resource_id
      AND sp.depth = rdm.role_depth
  ),
  -- ✅ NEW: case title lookup
  case_titles AS (
    SELECT
      uniform_resource_id,
      extracted_id AS test_case_id,
      title AS test_case_title
    FROM
      sections_with_roles
    WHERE
      role_name = 'case'
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
        WHEN INSTR(swr.code_content, CHAR(10) || 'cycle:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'cycle:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'severity:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'severity:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'assignee:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'assignee:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'status:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'status:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'issue_id:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(swr.code_content) + 1
      END AS end_of_cycle_date_pos
    FROM
      sections_with_roles swr
    WHERE
      swr.role_name = 'evidence'
      AND swr.extracted_id IS NOT NULL
      AND swr.code_content IS NOT NULL
  )
SELECT
  eep.uniform_resource_id,
  eep.uniform_resource_transform_id,
  eep.file_basename,
  eep.last_modified_at AS ingestion_timestamp,
  eep.test_case_id,
  ct.test_case_title,
  -- ✅ ADDED
  CASE
    WHEN TRIM(
      SUBSTR(
        eep.code_content,
        INSTR(eep.code_content, 'cycle:') + 6,
        eep.end_of_cycle_pos - (INSTR(eep.code_content, 'cycle:') + 6)
      )
    ) LIKE '%:%' THEN NULL
    ELSE TRIM(
      SUBSTR(
        eep.code_content,
        INSTR(eep.code_content, 'cycle:') + 6,
        eep.end_of_cycle_pos - (INSTR(eep.code_content, 'cycle:') + 6)
      )
    )
  END AS latest_cycle,
  TRIM(
    SUBSTR(
      eep.code_content,
      INSTR(eep.code_content, 'severity:') + 9,
      eep.end_of_severity_pos - (INSTR(eep.code_content, 'severity:') + 9)
    )
  ) AS severity,
  TRIM(
    SUBSTR(
      eep.code_content,
      INSTR(eep.code_content, 'assignee:') + 9,
      eep.end_of_assignee_pos - (INSTR(eep.code_content, 'assignee:') + 9)
    )
  ) AS assignee,
  TRIM(
    SUBSTR(
      eep.code_content,
      INSTR(eep.code_content, 'status:') + 7,
      eep.end_of_status_pos - (INSTR(eep.code_content, 'status:') + 7)
    )
  ) AS status,
  CASE
    WHEN INSTR(eep.code_content, 'issue_id:') > 0 THEN TRIM(
      SUBSTR(
        eep.code_content,
        INSTR(eep.code_content, 'issue_id:') + 9
      )
    )
    ELSE NULL
  END AS issue_id,
  CASE
    WHEN INSTR(eep.code_content, 'cycle-date:') > 0 THEN TRIM(
      SUBSTR(
        eep.code_content,
        INSTR(eep.code_content, 'cycle-date:') + 11,
        eep.end_of_cycle_date_pos - (INSTR(eep.code_content, 'cycle-date:') + 11)
      )
    )
    ELSE NULL
  END AS cycle_date
FROM
  evidence_extraction_positions eep
  LEFT JOIN case_titles ct ON ct.uniform_resource_id = eep.uniform_resource_id
  AND ct.test_case_id = eep.test_case_id
WHERE
  (
    NULLIF(cycle_date, '') IS NULL
    OR DATE(
      SUBSTR(cycle_date, 7, 4) || '-' || SUBSTR(cycle_date, 1, 2) || '-' || SUBSTR(cycle_date, 4, 2)
    ) <= DATE('now', 'localtime')
  )
ORDER BY
  eep.test_case_id,
  eep.last_modified_at DESC,
  latest_cycle DESC;
--CASE DEPTH WISE ANALYSIS
  DROP VIEW IF EXISTS qf_case_depth;
CREATE VIEW qf_case_depth AS
SELECT
  DISTINCT file_basename,
  role_name AS rolename,
  depth
FROM
  qf_role
WHERE
  role_name = 'case';
DROP VIEW IF EXISTS qf_case_overview;
CREATE VIEW qf_case_overview AS
SELECT
  v.file_basename,
  v.rolename,
  v.depth,
  s.title,
  s.body_json_string,
  s.extracted_id AS code,
  s.code_content AS content
FROM
  qf_case_depth v
  JOIN qf_role s ON s.file_basename = v.file_basename
  AND s.depth = v.depth
  AND s.role_name = v.rolename;
-- Drop old view if you’re iterating
  DROP VIEW IF EXISTS qf_case_master;
CREATE VIEW qf_case_master AS
SELECT
  file_basename,
  extracted_id AS code,
  code_content AS content,
  depth,
  REPLACE(
    json_extract(body_json_string, '$[0].paragraph'),
    '@id ',
    ''
  ) AS test_case_id,
  -- Description (index 3)
  json_extract(body_json_string, '$[3].paragraph') AS description,
  -- Preconditions list (index 5)
  json_extract(body_json_string, '$[5].list') AS preconditions,
  -- Steps list (index 7)
  json_extract(body_json_string, '$[7].list') AS steps,
  -- Expected Results list (index 9)
  json_extract(body_json_string, '$[9].list') AS expected_results,
  -- Single JSON object with everything
  json_object(
    'test_case_id',
    REPLACE(
      json_extract(body_json_string, '$[0].paragraph'),
      '@id ',
      ''
    ),
    'description',
    json_extract(body_json_string, '$[3].paragraph'),
    'preconditions',
    json_extract(body_json_string, '$[5].list'),
    'steps',
    json_extract(body_json_string, '$[7].list'),
    'expected_results',
    json_extract(body_json_string, '$[9].list'),
    'file_basename',
    file_basename,
    'code',
    extracted_id,
    'content',
    code_content,
    'depth',
    depth
  ) AS case_summary_json
FROM
  qf_role
WHERE
  role_name = 'case';
DROP VIEW IF EXISTS qf_agewise_opencases;
CREATE VIEW qf_agewise_opencases AS
select
  created_date,
  count(created_date) as total_records,
  project_name as projectname
from
  qf_open_issue_age
group by
  created_date,
  project_name;
--latest batch changes--
  DROP VIEW IF EXISTS qf_evidence_recent;
CREATE VIEW qf_evidence_recent AS WITH latest_ingestion AS (
    SELECT
      MAX(ingestion_timestamp) AS max_timestamp
    FROM
      qf_evidence_history
  ),
  latest_batch AS (
    SELECT
      DISTINCT test_case_id
    FROM
      qf_evidence_history
    WHERE
      ingestion_timestamp = (
        SELECT
          max_timestamp
        FROM
          latest_ingestion
      )
  ),
  current_and_previous AS (
    SELECT
      h.*,
      ROW_NUMBER() OVER (
        PARTITION BY h.test_case_id
        ORDER BY
          h.ingestion_timestamp DESC
      ) AS row_num
    FROM
      qf_evidence_history h
      INNER JOIN latest_batch lb ON h.test_case_id = lb.test_case_id
  )
SELECT
  curr.test_case_id,
  curr.test_case_title,
  curr.file_basename,
  curr.ingestion_timestamp,
  curr.latest_cycle,
  curr.cycle_date,
  curr.status,
  curr.severity,
  curr.assignee,
  curr.issue_id,
  prev.latest_cycle AS prev_cycle,
  prev.status AS prev_status,
  prev.severity AS prev_severity
FROM
  current_and_previous curr
  LEFT JOIN current_and_previous prev ON curr.test_case_id = prev.test_case_id
  AND prev.row_num = 2
WHERE
  curr.row_num = 1
  AND (
    COALESCE(curr.latest_cycle, '') != COALESCE(prev.latest_cycle, '')
    OR COALESCE(curr.cycle_date, '') != COALESCE(prev.cycle_date, '')
    OR COALESCE(curr.status, '') != COALESCE(prev.status, '')
    OR COALESCE(curr.severity, '') != COALESCE(prev.severity, '')
    OR COALESCE(curr.assignee, '') != COALESCE(prev.assignee, '')
    OR COALESCE(curr.issue_id, '') != COALESCE(prev.issue_id, '')
    OR prev.test_case_id IS NULL
  );
DROP VIEW IF EXISTS qf_evidence_history_all;
CREATE VIEW qf_evidence_history_all AS WITH raw_transform_data AS (
    SELECT
      distinct ur.uniform_resource_id,
      ur.uri,
      ur.created_at,
      urt.uniform_resource_transform_id,
      urpe.file_basename,
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
          '"'
        ),
        '\n',
        ''
      ) AS cleaned_json_text
    FROM
      uniform_resource_transform urt
      JOIN uniform_resource ur ON ur.uniform_resource_id = urt.uniform_resource_id
      JOIN ur_ingest_session_fs_path_entry urpe ON ur.uniform_resource_id = urpe.uniform_resource_id -- ✅ REMOVED: WHERE ur.last_modified_at IS NOT NULL
      -- This now includes ALL files, not just changed ones
  ),
  -- ✅ NEW: Get all ingestion timestamps
  all_ingestion_timestamps AS (
    SELECT
      DISTINCT created_at AS ingestion_timestamp
    FROM
      uniform_resource
    WHERE
      created_at IS NOT NULL
  ),
  role_depth_mapping AS (
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
      ur.frontmatter IS NOT NULL
  ),
  sections_parsed AS (
    SELECT
      rtd.uniform_resource_id,
      rtd.uniform_resource_transform_id,
      rtd.file_basename,
      rtd.created_at AS last_modified_at,
      jt_title.value AS title,
      CAST(jt_depth.value AS INTEGER) AS depth,
      jt_body.value AS body_json_string
    FROM
      raw_transform_data rtd,
      json_tree(rtd.cleaned_json_text, '$') AS jt_section,
      json_tree(rtd.cleaned_json_text, '$') AS jt_depth,
      json_tree(rtd.cleaned_json_text, '$') AS jt_title,
      json_tree(rtd.cleaned_json_text, '$') AS jt_body
    WHERE
      jt_section.key = 'section'
      AND jt_depth.parent = jt_section.id
      AND jt_depth.key = 'depth'
      AND jt_title.parent = jt_section.id
      AND jt_title.key = 'title'
      AND jt_body.parent = jt_section.id
      AND jt_body.key = 'body'
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
            SUBSTR(
              sp.body_json_string,
              INSTR(sp.body_json_string, '@id') + 4
            ),
            '"'
          ) - 1
        )
      ) AS extracted_id,
      CASE
        WHEN INSTR(sp.body_json_string, '"code":"') > 0 THEN REPLACE(
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
                              INSTR(sp.body_json_string, '","type":') - (INSTR(sp.body_json_string, '"code":"') + 8)
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
        ) -- Append second code block if present
        || CASE
          WHEN INSTR(
            SUBSTR(
              sp.body_json_string,
              INSTR(sp.body_json_string, '","type":') + 9
            ),
            '"code":"'
          ) > 0 THEN CHAR(10) || REPLACE(
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
                                SUBSTR(
                                  sp.body_json_string,
                                  INSTR(sp.body_json_string, '","type":') + 9
                                ),
                                INSTR(
                                  SUBSTR(
                                    sp.body_json_string,
                                    INSTR(sp.body_json_string, '","type":') + 9
                                  ),
                                  '"code":"'
                                ) + 8,
                                CASE
                                  WHEN INSTR(
                                    SUBSTR(
                                      SUBSTR(
                                        sp.body_json_string,
                                        INSTR(sp.body_json_string, '","type":') + 9
                                      ),
                                      INSTR(
                                        SUBSTR(
                                          sp.body_json_string,
                                          INSTR(sp.body_json_string, '","type":') + 9
                                        ),
                                        '"code":"'
                                      ) + 8
                                    ),
                                    '","type":'
                                  ) > 0 THEN INSTR(
                                    SUBSTR(
                                      SUBSTR(
                                        sp.body_json_string,
                                        INSTR(sp.body_json_string, '","type":') + 9
                                      ),
                                      INSTR(
                                        SUBSTR(
                                          sp.body_json_string,
                                          INSTR(sp.body_json_string, '","type":') + 9
                                        ),
                                        '"code":"'
                                      ) + 8
                                    ),
                                    '","type":'
                                  ) - 1
                                  ELSE LENGTH(sp.body_json_string)
                                END
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
          ELSE ''
        END
        ELSE NULL
      END AS code_content,
      rdm.role_name
    FROM
      sections_parsed sp
      LEFT JOIN role_depth_mapping rdm ON sp.uniform_resource_id = rdm.uniform_resource_id
      AND sp.depth = rdm.role_depth
  ),
  case_titles AS (
    SELECT
      uniform_resource_id,
      extracted_id AS test_case_id,
      title AS test_case_title
    FROM
      sections_with_roles
    WHERE
      role_name = 'case'
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
      CASE
        WHEN INSTR(swr.code_content, CHAR(10) || 'cycle:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'cycle:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'severity:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'severity:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'assignee:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'assignee:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'status:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'status:')
        WHEN INSTR(swr.code_content, CHAR(10) || 'issue_id:') > INSTR(swr.code_content, 'cycle-date:') THEN INSTR(swr.code_content, CHAR(10) || 'issue_id:')
        ELSE LENGTH(swr.code_content) + 1
      END AS end_of_cycle_date_pos
    FROM
      sections_with_roles swr
    WHERE
      swr.role_name = 'evidence'
      AND swr.extracted_id IS NOT NULL
      AND swr.code_content IS NOT NULL
  ),
  -- ✅ NEW: Get the most recent version of each test case at or before each ingestion
  evidence_with_full_history AS (
    SELECT
      ait.ingestion_timestamp,
      eep.uniform_resource_id,
      eep.uniform_resource_transform_id,
      eep.file_basename,
      eep.last_modified_at AS file_last_modified,
      eep.test_case_id,
      eep.code_content,
      eep.end_of_cycle_pos,
      eep.end_of_severity_pos,
      eep.end_of_assignee_pos,
      eep.end_of_status_pos,
      eep.end_of_cycle_date_pos,
      ROW_NUMBER() OVER (
        PARTITION BY ait.ingestion_timestamp,
        eep.test_case_id
        ORDER BY
          eep.last_modified_at DESC
      ) AS rn
    FROM
      all_ingestion_timestamps ait
      CROSS JOIN evidence_extraction_positions eep
    WHERE
      eep.last_modified_at <= ait.ingestion_timestamp
  )
SELECT
  ewfh.ingestion_timestamp,
  ewfh.uniform_resource_id,
  ewfh.uniform_resource_transform_id,
  ewfh.file_basename,
  ewfh.file_last_modified,
  ewfh.test_case_id,
  ct.test_case_title,
  CASE
    WHEN TRIM(
      SUBSTR(
        ewfh.code_content,
        INSTR(ewfh.code_content, 'cycle:') + 6,
        ewfh.end_of_cycle_pos - (INSTR(ewfh.code_content, 'cycle:') + 6)
      )
    ) LIKE '%:%' THEN NULL
    ELSE TRIM(
      SUBSTR(
        ewfh.code_content,
        INSTR(ewfh.code_content, 'cycle:') + 6,
        ewfh.end_of_cycle_pos - (INSTR(ewfh.code_content, 'cycle:') + 6)
      )
    )
  END AS latest_cycle,
  TRIM(
    SUBSTR(
      ewfh.code_content,
      INSTR(ewfh.code_content, 'severity:') + 9,
      ewfh.end_of_severity_pos - (INSTR(ewfh.code_content, 'severity:') + 9)
    )
  ) AS severity,
  TRIM(
    SUBSTR(
      ewfh.code_content,
      INSTR(ewfh.code_content, 'assignee:') + 9,
      ewfh.end_of_assignee_pos - (INSTR(ewfh.code_content, 'assignee:') + 9)
    )
  ) AS assignee,
  TRIM(
    SUBSTR(
      ewfh.code_content,
      INSTR(ewfh.code_content, 'status:') + 7,
      ewfh.end_of_status_pos - (INSTR(ewfh.code_content, 'status:') + 7)
    )
  ) AS status,
  CASE
    WHEN INSTR(ewfh.code_content, 'issue_id:') > 0 THEN TRIM(
      SUBSTR(
        ewfh.code_content,
        INSTR(ewfh.code_content, 'issue_id:') + 9
      )
    )
    ELSE NULL
  END AS issue_id,
  CASE
    WHEN INSTR(ewfh.code_content, 'cycle-date:') > 0 THEN TRIM(
      SUBSTR(
        ewfh.code_content,
        INSTR(ewfh.code_content, 'cycle-date:') + 11,
        ewfh.end_of_cycle_date_pos - (INSTR(ewfh.code_content, 'cycle-date:') + 11)
      )
    )
    ELSE NULL
  END AS cycle_date
FROM
  evidence_with_full_history ewfh
  LEFT JOIN case_titles ct ON ct.uniform_resource_id = ewfh.uniform_resource_id
  AND ct.test_case_id = ewfh.test_case_id
WHERE
  ewfh.rn = 1 -- Only the most recent version at each ingestion point
  AND (
    NULLIF(cycle_date, '') IS NULL
    OR DATE(
      SUBSTR(cycle_date, 7, 4) || '-' || SUBSTR(cycle_date, 1, 2) || '-' || SUBSTR(cycle_date, 4, 2)
    ) <= DATE('now', 'localtime')
  )
ORDER BY
  ewfh.ingestion_timestamp DESC,
  ewfh.test_case_id;
-----project----
  -- 5. TAP RESULTS EXTRACTION
  -- ==============================================================================
  DROP VIEW IF EXISTS qf_tap_results;
CREATE VIEW qf_tap_results AS WITH tap_resources AS (
    SELECT
      ur.uniform_resource_id,
      urpe.ingest_session_id,
      urpe.file_basename,
      CAST(ur.content AS TEXT) AS tap_content
    FROM
      uniform_resource ur
      JOIN ur_ingest_session_fs_path_entry urpe ON ur.uniform_resource_id = urpe.uniform_resource_id
    WHERE
      (
        ur.uri LIKE '%.tap'
        OR ur.nature = 'tap'
      )
      AND ur.content IS NOT NULL
  ),
  tap_lines_recursive(
    uniform_resource_id,
    ingest_session_id,
    file_basename,
    remaining,
    line
  ) AS (
    SELECT
      uniform_resource_id,
      ingest_session_id,
      file_basename,
      tap_content || CHAR(10),
      NULL
    FROM
      tap_resources
    UNION ALL
    SELECT
      uniform_resource_id,
      ingest_session_id,
      file_basename,
      SUBSTR(remaining, INSTR(remaining, CHAR(10)) + 1),
      SUBSTR(remaining, 1, INSTR(remaining, CHAR(10)) - 1)
    FROM
      tap_lines_recursive
    WHERE
      INSTR(remaining, CHAR(10)) > 0
  ),
  tap_extracted AS (
    SELECT
      uniform_resource_id,
      ingest_session_id,
      file_basename,
      line,
      CASE
        WHEN line LIKE '# Execution Date:%' THEN CASE
          WHEN INSTR(line, '/') > 0 THEN -- Handle DD/MM/YYYY or MM/DD/YYYY by swapping if first part > 12
          CASE
            WHEN CAST(
              SUBSTR(TRIM(SUBSTR(line, INSTR(line, ':') + 1)), 1, 2) AS INTEGER
            ) > 12 THEN SUBSTR(
              REPLACE(
                TRIM(SUBSTR(line, INSTR(line, ':') + 1)),
                '/',
                '-'
              ),
              4,
              3
            ) || SUBSTR(
              REPLACE(
                TRIM(SUBSTR(line, INSTR(line, ':') + 1)),
                '/',
                '-'
              ),
              1,
              2
            ) || SUBSTR(
              REPLACE(
                TRIM(SUBSTR(line, INSTR(line, ':') + 1)),
                '/',
                '-'
              ),
              6
            )
            ELSE REPLACE(
              TRIM(SUBSTR(line, INSTR(line, ':') + 1)),
              '/',
              '-'
            )
          END
          ELSE -- Handle DD-MM-YYYY or MM-DD-YYYY
          CASE
            WHEN CAST(
              SUBSTR(TRIM(SUBSTR(line, INSTR(line, ':') + 1)), 1, 2) AS INTEGER
            ) > 12 THEN SUBSTR(TRIM(SUBSTR(line, INSTR(line, ':') + 1)), 4, 3) || SUBSTR(TRIM(SUBSTR(line, INSTR(line, ':') + 1)), 1, 2) || SUBSTR(TRIM(SUBSTR(line, INSTR(line, ':') + 1)), 6)
            ELSE TRIM(SUBSTR(line, INSTR(line, ':') + 1))
          END
        END
        ELSE NULL
      END AS tap_date,
      CASE
        WHEN line LIKE '# Execution Time:%' THEN TRIM(SUBSTR(line, INSTR(line, ':') + 1))
        ELSE NULL
      END AS tap_time,
      CASE
        WHEN LOWER(TRIM(line)) LIKE 'ok [SURVEILR%'
        OR LOWER(TRIM(line)) LIKE 'not ok [SURVEILR%' THEN line
        ELSE NULL
      END AS test_line
    FROM
      tap_lines_recursive
    WHERE
      line IS NOT NULL
  ),
  tap_dates AS (
    SELECT
      uniform_resource_id,
      ingest_session_id,
      file_basename,
      MAX(tap_date) AS tap_date,
      MAX(tap_time) AS tap_time
    FROM
      tap_extracted
    WHERE
      tap_date IS NOT NULL
    GROUP BY
      uniform_resource_id,
      ingest_session_id,
      file_basename
  ),
  tap_parsed AS (
    SELECT
      uniform_resource_id,
      ingest_session_id,
      file_basename,
      TRIM(test_line) as raw_line,
      CASE
        WHEN LOWER(TRIM(test_line)) LIKE 'not ok%' THEN 'not ok'
        ELSE 'ok'
      END AS status,
      TRIM(
        SUBSTR(
          test_line,
          INSTR(test_line, '[') + 1,
          INSTR(test_line, ']') - INSTR(test_line, '[') - 1
        )
      ) AS test_case_id
    FROM
      tap_extracted
    WHERE
      test_line IS NOT NULL
      AND INSTR(LOWER(test_line), '[surveilr') > 0
  )
SELECT
  tp.uniform_resource_id,
  tp.ingest_session_id,
  tp.file_basename,
  tp.test_case_id,
  tp.status,
  td.tap_date,
  CASE
    WHEN td.tap_date IS NOT NULL
    AND td.tap_time IS NOT NULL THEN td.tap_date || ' ' || td.tap_time
    ELSE COALESCE(td.tap_date, td.tap_time)
  END AS execution_time
FROM
  tap_parsed tp
  JOIN tap_dates td ON tp.uniform_resource_id = td.uniform_resource_id
  AND tp.ingest_session_id = td.ingest_session_id
  INNER JOIN (
    SELECT
      tp_in.test_case_id,
      td_in.tap_date,
      MAX(tp_in.ingest_session_id) as latest_session
    FROM
      tap_parsed tp_in
      JOIN tap_dates td_in ON tp_in.uniform_resource_id = td_in.uniform_resource_id
      AND tp_in.ingest_session_id = td_in.ingest_session_id
    GROUP BY
      tp_in.test_case_id,
      td_in.tap_date
  ) latest_tap ON tp.test_case_id = latest_tap.test_case_id
  AND td.tap_date = latest_tap.tap_date
  AND tp.ingest_session_id = latest_tap.latest_session
WHERE
  (
    NULLIF(td.tap_date, '') IS NULL
    OR DATE(
      SUBSTR(td.tap_date, 7, 4) || '-' || SUBSTR(td.tap_date, 1, 2) || '-' || SUBSTR(td.tap_date, 4, 2)
    ) <= DATE('now', 'localtime')
  );
DROP TABLE IF EXISTS qf_evidence_status;
CREATE TABLE qf_evidence_status AS WITH RECURSIVE project_info AS (
    SELECT
      r.uniform_resource_id,
      COALESCE(
        JSON_EXTRACT(r.frontmatter, '$.title'),
        (SELECT title FROM qf_role WHERE role_name = 'project' LIMIT 1)
      ) AS project_name
    FROM
      uniform_resource r
    WHERE
      r.frontmatter IS NOT NULL OR EXISTS (SELECT 1 FROM qf_role WHERE role_name = 'project' LIMIT 1)
  ),
  -- Step 1: get all evidence rows with normalized code_content
  evidence_source AS (
    SELECT
      tas.uniform_resource_id,
      tas.file_basename,
      tas.extracted_id AS test_case_id,
      -- Ensure code_content starts with 'cycle:' so the splitting works uniformly.
      CASE
        WHEN SUBSTR(TRIM(tas.code_content), 1, 6) = 'cycle:' THEN TRIM(tas.code_content)
        WHEN INSTR(tas.code_content, 'cycle:') > 0 THEN SUBSTR(
          tas.code_content,
          INSTR(tas.code_content, 'cycle:')
        )
        ELSE tas.code_content
      END AS code_content
    FROM
      qf_role tas
    WHERE
      tas.role_name = 'evidence'
      AND tas.extracted_id IS NOT NULL
      AND tas.code_content IS NOT NULL
  ),
  -- Step 2: recursively split code_content on CHAR(10)||'cycle:' to get one block per cycle
  cycle_blocks(
    uniform_resource_id,
    test_case_id,
    file_basename,
    remaining,
    block
  ) AS (
    SELECT
      uniform_resource_id,
      test_case_id,
      file_basename,
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          code_content,
          INSTR(code_content, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END AS remaining,
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            code_content,
            1,
            INSTR(code_content, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(code_content)
      END AS block
    FROM
      evidence_source
    UNION ALL
    SELECT
      uniform_resource_id,
      test_case_id,
      file_basename,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          remaining,
          INSTR(remaining, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            remaining,
            1,
            INSTR(remaining, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(remaining)
      END
    FROM
      cycle_blocks
    WHERE
      remaining IS NOT NULL
  ),
  -- Step 3: parse each individual cycle block for its fields
  evidence_details AS (
    SELECT
      cb.uniform_resource_id,
      cb.file_basename,
      cb.test_case_id,
      pi.project_name,
      -- cycle
      TRIM(
        REPLACE(
          SUBSTR(
            cb.block,
            INSTR(cb.block, 'cycle:') + 6,
            CASE
              WHEN INSTR(
                SUBSTR(cb.block, INSTR(cb.block, 'cycle:') + 6),
                CHAR(10)
              ) = 0 THEN LENGTH(cb.block)
              ELSE INSTR(
                SUBSTR(cb.block, INSTR(cb.block, 'cycle:') + 6),
                CHAR(10)
              )
            END
          ),
          CHAR(10),
          ''
        )
      ) AS val_cycle,
      -- cycle-date
      CASE
        WHEN INSTR(cb.block, 'cycle-date:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              cb.block,
              INSTR(cb.block, 'cycle-date:') + 11,
              CASE
                WHEN INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'cycle-date:') + 11),
                  CHAR(10)
                ) = 0 THEN LENGTH(cb.block)
                ELSE INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'cycle-date:') + 11),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS val_cycle_date,
      -- severity
      CASE
        WHEN INSTR(cb.block, 'severity:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              cb.block,
              INSTR(cb.block, 'severity:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'severity:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(cb.block)
                ELSE INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'severity:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS val_severity,
      -- assignee
      CASE
        WHEN INSTR(cb.block, 'assignee:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              cb.block,
              INSTR(cb.block, 'assignee:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'assignee:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(cb.block)
                ELSE INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'assignee:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS val_assignee,
      -- status
      CASE
        WHEN INSTR(cb.block, 'status:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              cb.block,
              INSTR(cb.block, 'status:') + 7,
              CASE
                WHEN INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'status:') + 7),
                  CHAR(10)
                ) = 0 THEN LENGTH(cb.block)
                ELSE INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'status:') + 7),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS val_status,
      -- issue_id
      CASE
        WHEN INSTR(cb.block, 'issue_id:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              cb.block,
              INSTR(cb.block, 'issue_id:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'issue_id:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(cb.block)
                ELSE INSTR(
                  SUBSTR(cb.block, INSTR(cb.block, 'issue_id:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE ''
      END AS val_issue_id
    FROM
      cycle_blocks cb
      LEFT JOIN project_info pi ON pi.uniform_resource_id = cb.uniform_resource_id
    WHERE
      cb.block IS NOT NULL
      AND TRIM(cb.block) != ''
      AND INSTR(cb.block, 'cycle:') > 0
      AND (
        NULLIF(val_cycle_date, '') IS NULL
        OR DATE(
          SUBSTR(val_cycle_date, 7, 4) || '-' || SUBSTR(val_cycle_date, 1, 2) || '-' || SUBSTR(val_cycle_date, 4, 2)
        ) <= DATE('now', 'localtime')
      )
  ),
  -- Check whether a TAP result exists for this test case in the same ingest session
  tap_exists AS (
    SELECT
      DISTINCT ingest_session_id,
      UPPER(test_case_id) AS test_case_id,
      tap_date
    FROM
      qf_tap_results
  ),
  ranked_evidence AS (
    SELECT
      ed.*,
      ROW_NUMBER() OVER (
        PARTITION BY ed.uniform_resource_id,
        ed.test_case_id
        ORDER BY
          -- If TAP exists, prioritize the cycle whose date matches the TAP execution date
          CASE
            WHEN te.test_case_id IS NOT NULL
            AND TRIM(ed.val_cycle_date) = TRIM(te.tap_date) THEN 0
            WHEN te.test_case_id IS NOT NULL THEN 1 -- No TAP: no status-based preference; fall through to date sort below
            ELSE 2
          END ASC,
          -- When no TAP: pick the most recent cycle-date (MM-DD-YYYY → YYYY-MM-DD for correct ordering)
          CASE
            WHEN te.test_case_id IS NULL
            AND ed.val_cycle_date IS NOT NULL THEN SUBSTR(ed.val_cycle_date, 7, 4) || SUBSTR(ed.val_cycle_date, 1, 2) || SUBSTR(ed.val_cycle_date, 4, 2)
            ELSE NULL
          END DESC,
          -- Final fallback: latest cycle name
          ed.val_cycle DESC
      ) AS rn
    FROM
      evidence_details ed
      LEFT JOIN qf_markdown_master mm ON ed.uniform_resource_id = mm.uniform_resource_id
      LEFT JOIN tap_exists te ON UPPER(ed.test_case_id) = te.test_case_id
      AND mm.ingest_session_id = te.ingest_session_id
  )
SELECT
  uniform_resource_id,
  project_name,
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
DROP VIEW IF EXISTS qf_role_with_project;
CREATE VIEW qf_role_with_project AS
select
  tbl.rownum,
  tbl.extracted_id as project_id,
  tbl.depth,
  tbl.file_basename,
  tbl.uniform_resource_id,
  tbl.role_name,
  tbl.title -- ,
  -- trim(
  --     replace(
  --         SUBSTR(tbl.code_content, INSTR(tbl.code_content, 'tenantID:') + 10,
  --             case when  INSTR( substr(tbl.code_content,INSTR(tbl.code_content, 'tenantID:') + 10,length(tbl.code_content)), CHAR(10)  ) =0 then length(tbl.code_content)
  --             else INSTR( substr(tbl.code_content,INSTR(tbl.code_content, 'tenantID:') +10,length(tbl.code_content)), CHAR(10)  ) end
  --             )
  --     ,char(10),'')
  --     )   as tenantID
from
  qf_role tbl
where
  role_name = 'project';
DROP VIEW IF EXISTS qf_role_with_evidence;
CREATE VIEW qf_role_with_evidence AS -- Split each evidence code_content into individual cycle blocks using a recursive CTE,
  -- so that a test case with N HFM evidence blocks produces N rows (one per cycle).
  WITH RECURSIVE -- Step 1: get all evidence rows with normalized code_content
  evidence_rows AS (
    SELECT
      tbl.rownum,
      tbl.extracted_id AS testcaseid,
      tbl.depth,
      tbl.file_basename,
      tbl.uniform_resource_id,
      tbl.role_name,
      -- Ensure code_content starts with 'cycle:' so the splitting works uniformly.
      CASE
        WHEN SUBSTR(TRIM(tbl.code_content), 1, 6) = 'cycle:' THEN TRIM(tbl.code_content)
        WHEN INSTR(tbl.code_content, 'cycle:') > 0 THEN SUBSTR(
          tbl.code_content,
          INSTR(tbl.code_content, 'cycle:')
        )
        ELSE tbl.code_content
      END AS code_content,
      prj.title AS project_name,
      prj.project_id
    FROM
      qf_role tbl
      INNER JOIN qf_role_with_project prj ON prj.uniform_resource_id = tbl.uniform_resource_id
    WHERE
      tbl.role_name = 'evidence'
      AND prj.depth = 1
      AND tbl.code_content IS NOT NULL
      AND tbl.extracted_id IS NOT NULL
  ),
  -- Step 2: recursively split code_content on CHAR(10)||'cycle:' to get one block per cycle
  cycle_blocks(
    rownum,
    testcaseid,
    depth,
    file_basename,
    uniform_resource_id,
    role_name,
    project_name,
    project_id,
    remaining,
    -- text still to be processed
    block -- the current cycle block (starts with 'cycle:')
  ) AS (
    -- Base: emit the first block (everything before the second 'cycle:'), keep the rest
    SELECT
      rownum,
      testcaseid,
      depth,
      file_basename,
      uniform_resource_id,
      role_name,
      project_name,
      project_id,
      -- remaining = what comes after the first 'CHAR(10)cycle:' separator
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          code_content,
          INSTR(code_content, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END AS remaining,
      -- block = everything up to (but not including) the next 'CHAR(10)cycle:' separator
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            code_content,
            1,
            INSTR(code_content, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(code_content)
      END AS block
    FROM
      evidence_rows
    UNION ALL
      -- Recursive: consume remaining text block by block
    SELECT
      rownum,
      testcaseid,
      depth,
      file_basename,
      uniform_resource_id,
      role_name,
      project_name,
      project_id,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          remaining,
          INSTR(remaining, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            remaining,
            1,
            INSTR(remaining, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(remaining)
      END
    FROM
      cycle_blocks
    WHERE
      remaining IS NOT NULL
  ),
  -- Step 3: parse each individual cycle block for its fields
  parsed AS (
    SELECT
      rownum,
      testcaseid,
      depth,
      file_basename,
      uniform_resource_id,
      role_name,
      project_name,
      project_id,
      block,
      -- cycle
      TRIM(
        REPLACE(
          SUBSTR(
            block,
            INSTR(block, 'cycle:') + 6,
            CASE
              WHEN INSTR(
                SUBSTR(block, INSTR(block, 'cycle:') + 6),
                CHAR(10)
              ) = 0 THEN LENGTH(block)
              ELSE INSTR(
                SUBSTR(block, INSTR(block, 'cycle:') + 6),
                CHAR(10)
              )
            END
          ),
          CHAR(10),
          ''
        )
      ) AS cycle,
      -- cycle-date
      CASE
        WHEN INSTR(block, 'cycle-date:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'cycle-date:') + 11,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'cycle-date:') + 11),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'cycle-date:') + 11),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS cycledate,
      -- severity
      CASE
        WHEN INSTR(block, 'severity:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'severity:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'severity:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'severity:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS severity,
      -- assignee
      CASE
        WHEN INSTR(block, 'assignee:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'assignee:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'assignee:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'assignee:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS assignee,
      -- status
      CASE
        WHEN INSTR(block, 'status:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'status:') + 7,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'status:') + 7),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'status:') + 7),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS status
    FROM
      cycle_blocks
    WHERE
      block IS NOT NULL
      AND TRIM(block) != ''
      AND INSTR(block, 'cycle:') > 0
      -- AND (
      --   NULLIF(cycledate, '') IS NULL
      --   OR DATE(
      --     SUBSTR(cycledate, 7, 4) || '-' || SUBSTR(cycledate, 1, 2) || '-' || SUBSTR(cycledate, 4, 2)
      --   ) <= DATE('now', 'localtime')
      -- )
  )
SELECT
  rownum,
  testcaseid,
  depth,
  file_basename,
  uniform_resource_id,
  role_name,
  cycle,
  cycledate,
  severity,
  assignee,
  status,
  project_name,
  project_id
FROM
  parsed;
DROP VIEW IF EXISTS qf_role_with_evidence_refined;
CREATE VIEW qf_role_with_evidence_refined AS WITH raw_refined AS (
    SELECT
      re.*,
      CASE
        WHEN tr.status IS NOT NULL
        AND re.cycledate = tr.tap_date THEN tr.status
        ELSE re.status
      END AS status_refined
    FROM
      qf_role_with_evidence re
      JOIN (
        SELECT
          uniform_resource_id,
          ingest_session_id,
          ROW_NUMBER() OVER (
            PARTITION BY uniform_resource_id
            ORDER BY
              ingest_session_id DESC
          ) as rn
        FROM
          ur_ingest_session_fs_path_entry
      ) urpe ON re.uniform_resource_id = urpe.uniform_resource_id
      AND urpe.rn = 1
      LEFT JOIN qf_tap_results tr ON UPPER(re.testcaseid) = UPPER(tr.test_case_id)
      AND re.cycledate = tr.tap_date
      AND tr.ingest_session_id = urpe.ingest_session_id
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (
        PARTITION BY testcaseid,
        cycle,
        project_name
        ORDER BY
          uniform_resource_id DESC
      ) as rn
    FROM
      raw_refined
  )
SELECT
  *
FROM
  ranked
WHERE
  rn = 1;
DROP VIEW IF EXISTS cycle_data_summary;
CREATE VIEW cycle_data_summary AS
select
  cycle,
  -- Use the latest cycledate across all test cases for this cycle
  MAX(
    SUBSTR(cycledate, 7, 4) || SUBSTR(cycledate, 1, 2) || SUBSTR(cycledate, 4, 2)
  ) AS cycledate_sort,
  -- Convert back to MM-DD-YYYY for display
  SUBSTR(
    MAX(
      SUBSTR(cycledate, 7, 4) || SUBSTR(cycledate, 1, 2) || SUBSTR(cycledate, 4, 2)
    ),
    5,
    2
  ) || '-' || SUBSTR(
    MAX(
      SUBSTR(cycledate, 7, 4) || SUBSTR(cycledate, 1, 2) || SUBSTR(cycledate, 4, 2)
    ),
    7,
    2
  ) || '-' || SUBSTR(
    MAX(
      SUBSTR(cycledate, 7, 4) || SUBSTR(cycledate, 1, 2) || SUBSTR(cycledate, 4, 2)
    ),
    1,
    4
  ) AS cycledate,
  project_name,
  SUM(
    CASE
      WHEN LOWER(status_refined) IN ('passed', 'ok', 'failed', 'not ok', 'closed') THEN 1
      ELSE 0
    END
  ) as totalcases,
  SUM(
    CASE
      WHEN status_refined IN ('passed', 'ok') THEN 1
      ELSE 0
    END
  ) as passed_cases,
  SUM(
    CASE
      WHEN status_refined IN ('failed', 'not ok') THEN 1
      ELSE 0
    END
  ) as failed_cases,
  SUM(
    CASE
      WHEN LOWER(status_refined) = 'closed' THEN 1
      ELSE 0
    END
  ) as closed_cases
from
  qf_role_with_evidence_refined
WHERE (
    NULLIF(cycledate, '') IS NULL
    OR DATE(
      SUBSTR(cycledate, 7, 4) || '-' || SUBSTR(cycledate, 1, 2) || '-' || SUBSTR(cycledate, 4, 2)
    ) <= DATE('now', 'localtime')
  )
group by
  cycle,
  project_name;
DROP VIEW IF EXISTS qf_role_with_case;
CREATE VIEW qf_role_with_case AS
select
  tbl.rownum,
  tbl.extracted_id as testcaseid,
  tbl.depth,
  tbl.file_basename,
  tbl.uniform_resource_id,
  tbl.role_name,
  tbl.title,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'requirementID:') + 15,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as requirementID,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'Execution Type:') + 16,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Execution Type:') + 16,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Execution Type:') + 16,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as execution_type,
  prj.title as project_name,
  prj.project_id
from
  qf_role tbl
  inner join qf_role_with_project prj on prj.uniform_resource_id = tbl.uniform_resource_id
where
  tbl.role_name = 'case'
  and prj.depth = 1;
DROP VIEW IF EXISTS qf_testcase_status;
CREATE VIEW qf_testcase_status AS
select
  T2.testcaseid,
  T2.status,
  T2.project_name,
  T2.cycle,
  1 as rowcount
from
  qf_role_with_evidence T2
  inner join (
    select
      testcaseid,
      max(cycle) as cycle,
      project_name
    from
      qf_role_with_evidence
    where
      status in('passed', 'failed', 'reopen')
    group by
      testcaseid,
      project_name
  ) T on T.cycle = T2.cycle
  and T.testcaseid = T2.testcaseid
  and T.project_name = T2.project_name;
DROP VIEW IF EXISTS qf_case_status_percentage;
CREATE VIEW qf_case_status_percentage AS
SELECT
  COUNT(test_case_id) AS totalcount,
  SUM(
    CASE
      WHEN LOWER(test_case_status) IN ('passed', 'ok') THEN 1
      ELSE 0
    END
  ) AS passed,
  SUM(
    CASE
      WHEN LOWER(test_case_status) IN ('failed', 'reopen', 'not ok') THEN 1
      ELSE 0
    END
  ) AS failed,
  SUM(
    CASE
      WHEN test_case_status IS NULL OR LOWER(test_case_status) IN ('todo', 'to-do', 'to do') THEN 1
      ELSE 0
    END
  ) AS todocount,
  SUM(
    CASE
      WHEN LOWER(test_case_status) = 'closed' THEN 1
      ELSE 0
    END
  ) AS closedcount,
  project_name AS projectname,
  ROUND(
    SUM(CASE WHEN LOWER(test_case_status) IN ('passed', 'ok') THEN 1 ELSE 0 END) * 100.0 / 
    NULLIF(SUM(CASE WHEN LOWER(test_case_status) IN ('passed', 'ok', 'failed', 'reopen', 'not ok') THEN 1 ELSE 0 END), 0),
    2
  ) AS passedpercentage,
  ROUND(
    SUM(CASE WHEN LOWER(test_case_status) IN ('failed', 'reopen', 'not ok') THEN 1 ELSE 0 END) * 100.0 / 
    NULLIF(SUM(CASE WHEN LOWER(test_case_status) IN ('passed', 'ok', 'failed', 'reopen', 'not ok') THEN 1 ELSE 0 END), 0),
    2
  ) AS failedpercentage,
  ROUND(
    SUM(CASE WHEN test_case_status IS NULL OR LOWER(test_case_status) IN ('todo', 'to-do', 'to do') THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(test_case_id), 0),
    2
  ) AS todopercentage,
  ROUND(
    SUM(CASE WHEN LOWER(test_case_status) = 'closed' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(test_case_id), 0),
    2
  ) AS closedpercentage
FROM
  qf_case_status_tap
GROUP BY
  project_name;
DROP VIEW IF EXISTS qf_case_execution_status_percentage;
CREATE VIEW qf_case_execution_status_percentage AS with tblproject_testcases as(
    select
      project_name,
      count(*) as test_case_total_count
    from
      qf_role_with_case -- where (upper(execution_type)='AUTOMATION' or upper(execution_type)='MANUAL')
    group by
      project_name
  )
select
  tbl1.project_name,
  tbl1.execution_type,
  tbl2.test_case_total_count,
  count(tbl1.project_name) as test_case_count,
  round(
    (
      round(count(tbl1.project_name), 2) / round(tbl2.test_case_total_count, 2)
    ) * 100,
    2
  ) as test_case_percentage
from
  qf_role_with_case tbl1
  inner join tblproject_testcases tbl2 on tbl1.project_name = tbl2.project_name
where
  (
    upper(execution_type) = 'AUTOMATION'
    or upper(execution_type) = 'MANUAL'
  )
group by
  tbl1.project_name,
  tbl1.execution_type;
DROP VIEW IF EXISTS qf_role_with_suite;
CREATE VIEW qf_role_with_suite AS
select
  tbl.rownum,
  tbl.extracted_id as suiteid,
  tbl.depth,
  tbl.file_basename,
  tbl.uniform_resource_id,
  tbl.role_name,
  tbl.title,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'requirementID:') + 15,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as requirementID,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'Priority:') + 10,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Priority:') + 10,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Priority:') + 10,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as priority,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'Scenario Type:') + 15,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Scenario Type:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Scenario Type:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as scenario_type,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'suite-name:') + 12,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'suite-name:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'suite-name:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as suite_name,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'suite-date:') + 12,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'suite-date:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'suite-date:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as suite_date,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'created-by:') + 12,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'created-by:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'created-by:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as created_by,
  prj.title as project_name,
  prj.project_id
from
  qf_role tbl
  inner join qf_role_with_project prj on prj.uniform_resource_id = tbl.uniform_resource_id
where
  tbl.role_name = 'suite'
  and prj.depth = 1
  and tbl.depth = 3;
DROP VIEW IF EXISTS qf_role_with_plan;
CREATE VIEW qf_role_with_plan AS
select
  tbl.rownum,
  tbl.extracted_id as planid,
  tbl.depth,
  tbl.file_basename,
  tbl.uniform_resource_id,
  tbl.role_name,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'requirementID:') + 15,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as requirementID,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'Priority:') + 10,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Priority:') + 10,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Priority:') + 10,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as priority,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'Scenario Type:') + 15,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Scenario Type:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Scenario Type:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as scenario_type,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'plan-name:') + 11,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'plan-name:') + 11,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'plan-name:') + 11,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as plan_name,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'plan-date:') + 11,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'plan-date:') + 11,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'plan-date:') + 11,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as plan_date,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'created-by:') + 12,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'created-by:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'created-by:') + 12,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as created_by,
  prj.title as project_name,
  prj.project_id
from
  qf_role tbl
  inner join qf_role_with_project prj on prj.uniform_resource_id = tbl.uniform_resource_id
where
  tbl.role_name = 'plan'
  and prj.depth = 1;
DROP TABLE IF EXISTS qf_markdown_master_history;
CREATE TABLE qf_markdown_master_history as WITH ranked AS (
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
      ) AS rn,
      urt.uniform_resource_transform_id,
      urt.created_at
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
  cleaned_json_text,
  rn,
  uniform_resource_transform_id,
  created_at
FROM
  ranked;
------
  DROP TABLE IF EXISTS qf_depth_history;
CREATE TABLE qf_depth_history AS
SELECT
  td.uniform_resource_id,
  td.file_basename,
  td.rn,
  td.uniform_resource_transform_id,
  td.created_at,
  jt_title.value AS title,
  CAST(jt_depth.value AS INTEGER) AS depth,
  jt_body.value AS body_json_string
FROM
  qf_markdown_master_history td,
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
DROP TABLE IF EXISTS qf_role_history;
CREATE TABLE qf_role_history AS
SELECT
  ROW_NUMBER() OVER (
    ORDER BY
      s.uniform_resource_id
  ) AS rownum,
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
  ) AS code_content,
  rm.role_name,
  s.rn,
  s.uniform_resource_transform_id,
  s.created_at
FROM
  qf_depth_history s
  LEFT JOIN qf_depth_master rm ON s.uniform_resource_id = rm.uniform_resource_id
  AND s.depth = rm.role_depth
  and s.depth != 5
union ALL
SELECT
  ROW_NUMBER() OVER (
    ORDER BY
      s.uniform_resource_id
  ) AS rownum,
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
                      REPLACE(
                        REPLACE(
                          json_extract(value, '$.code_block'),
                          '{"code":"',
                          ''
                        ),
                        '","type":"code","language":"yaml","metadata":"HFM"}',
                        ''
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
  ) AS code_content,
  rm.role_name,
  s.rn,
  s.uniform_resource_transform_id,
  s.created_at
FROM
  qf_depth_history s
  LEFT JOIN qf_depth_master rm ON s.uniform_resource_id = rm.uniform_resource_id
  AND s.depth = rm.role_depth,
  json_each(s.body_json_string)
WHERE
  json_type(value, '$.code_block') IS NOT NULL
  and s.depth = 5;
DROP VIEW IF EXISTS qf_role_with_evidence_history;
CREATE VIEW qf_role_with_evidence_history AS -- Split each evidence code_content into individual cycle blocks using a recursive CTE,
  -- so that a test case with N HFM evidence blocks produces N rows (one per cycle).
  WITH RECURSIVE -- Step 1: get all evidence rows from history (one row per file ingestion × test case)
  evidence_rows AS (
    SELECT
      tbl.rownum,
      tbl.extracted_id AS testcaseid,
      tbl.depth,
      tbl.file_basename,
      tbl.uniform_resource_id,
      tbl.role_name,
      -- Ensure code_content starts with 'cycle:' so the splitting works uniformly.
      -- If code_content starts with a leading newline before the first 'cycle:', strip it.
      CASE
        WHEN SUBSTR(TRIM(tbl.code_content), 1, 6) = 'cycle:' THEN TRIM(tbl.code_content)
        WHEN INSTR(tbl.code_content, 'cycle:') > 0 THEN SUBSTR(
          tbl.code_content,
          INSTR(tbl.code_content, 'cycle:')
        )
        ELSE tbl.code_content
      END AS code_content,
      prj.title AS project_name,
      prj.project_id,
      CAST(tbl.rn AS INTEGER) AS rn,
      tbl.uniform_resource_transform_id,
      tbl.created_at
    FROM
      qf_role_history tbl
      INNER JOIN qf_role_with_project_history prj ON prj.uniform_resource_id = tbl.uniform_resource_id
    WHERE
      tbl.role_name = 'evidence'
      AND prj.depth = 1
      AND tbl.code_content IS NOT NULL
      AND tbl.extracted_id IS NOT NULL
  ),
  -- Step 2: recursively split code_content on CHAR(10)||'cycle:' to get one block per cycle
  cycle_blocks(
    rownum,
    testcaseid,
    depth,
    file_basename,
    uniform_resource_id,
    role_name,
    project_name,
    project_id,
    rn,
    uniform_resource_transform_id,
    created_at,
    remaining,
    -- text still to be processed
    block -- the current cycle block (starts with 'cycle:')
  ) AS (
    -- Base: emit the first block (everything before the second 'cycle:'), keep the rest
    SELECT
      rownum,
      testcaseid,
      depth,
      file_basename,
      uniform_resource_id,
      role_name,
      project_name,
      project_id,
      rn,
      uniform_resource_transform_id,
      created_at,
      -- remaining = what comes after the first 'CHAR(10)cycle:' separator
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          code_content,
          INSTR(code_content, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END AS remaining,
      -- block = everything up to (but not including) the next 'CHAR(10)cycle:' separator
      CASE
        WHEN INSTR(code_content, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            code_content,
            1,
            INSTR(code_content, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(code_content)
      END AS block
    FROM
      evidence_rows
    UNION ALL
      -- Recursive: consume remaining text block by block
    SELECT
      rownum,
      testcaseid,
      depth,
      file_basename,
      uniform_resource_id,
      role_name,
      project_name,
      project_id,
      rn,
      uniform_resource_transform_id,
      created_at,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN SUBSTR(
          remaining,
          INSTR(remaining, CHAR(10) || 'cycle:') + 1
        )
        ELSE NULL
      END,
      CASE
        WHEN INSTR(remaining, CHAR(10) || 'cycle:') > 0 THEN TRIM(
          SUBSTR(
            remaining,
            1,
            INSTR(remaining, CHAR(10) || 'cycle:') - 1
          )
        )
        ELSE TRIM(remaining)
      END
    FROM
      cycle_blocks
    WHERE
      remaining IS NOT NULL
  ),
  -- Step 3: parse each individual cycle block for its fields
  parsed AS (
    SELECT
      rownum,
      testcaseid,
      depth,
      file_basename,
      uniform_resource_id,
      role_name,
      project_name,
      project_id,
      rn,
      uniform_resource_transform_id,
      created_at,
      block,
      -- cycle
      TRIM(
        REPLACE(
          SUBSTR(
            block,
            INSTR(block, 'cycle:') + 6,
            CASE
              WHEN INSTR(
                SUBSTR(block, INSTR(block, 'cycle:') + 6),
                CHAR(10)
              ) = 0 THEN LENGTH(block)
              ELSE INSTR(
                SUBSTR(block, INSTR(block, 'cycle:') + 6),
                CHAR(10)
              )
            END
          ),
          CHAR(10),
          ''
        )
      ) AS cycle,
      -- cycle-date
      CASE
        WHEN INSTR(block, 'cycle-date:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'cycle-date:') + 11,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'cycle-date:') + 11),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'cycle-date:') + 11),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS cycledate,
      -- severity
      CASE
        WHEN INSTR(block, 'severity:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'severity:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'severity:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'severity:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS severity,
      -- assignee
      CASE
        WHEN INSTR(block, 'assignee:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'assignee:') + 9,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'assignee:') + 9),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'assignee:') + 9),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS assignee,
      -- status
      CASE
        WHEN INSTR(block, 'status:') > 0 THEN TRIM(
          REPLACE(
            SUBSTR(
              block,
              INSTR(block, 'status:') + 7,
              CASE
                WHEN INSTR(
                  SUBSTR(block, INSTR(block, 'status:') + 7),
                  CHAR(10)
                ) = 0 THEN LENGTH(block)
                ELSE INSTR(
                  SUBSTR(block, INSTR(block, 'status:') + 7),
                  CHAR(10)
                )
              END
            ),
            CHAR(10),
            ''
          )
        )
        ELSE NULL
      END AS status
    FROM
      cycle_blocks
    WHERE
      block IS NOT NULL
      AND TRIM(block) != ''
      AND INSTR(block, 'cycle:') > 0
      AND (
        NULLIF(cycledate, '') IS NULL
        OR DATE(
          SUBSTR(cycledate, 7, 4) || '-' || SUBSTR(cycledate, 1, 2) || '-' || SUBSTR(cycledate, 4, 2)
        ) <= DATE('now', 'localtime')
      )
  )
SELECT
  rownum,
  testcaseid,
  depth,
  file_basename,
  uniform_resource_id,
  role_name,
  cycle,
  cycledate,
  severity,
  assignee,
  status,
  project_name,
  project_id,
  rn,
  uniform_resource_transform_id,
  created_at
FROM
  parsed;
DROP VIEW IF EXISTS qf_role_with_project_history;
CREATE VIEW qf_role_with_project_history AS
select
  distinct tbl.extracted_id as project_id,
  tbl.depth,
  tbl.file_basename,
  tbl.uniform_resource_id,
  tbl.role_name,
  tbl.title
from
  qf_role_history tbl
where
  role_name = 'project';
-- Drop any accidental table creation from prior scripts

CREATE VIEW IF NOT EXISTS github_issues AS
  SELECT
    NULL AS number,
    NULL AS assignee,
    NULL AS title,
    NULL AS body,
    NULL AS html_url,
    NULL AS author_association,
    NULL AS created_at,
    NULL AS updated_at,
    NULL AS state,
    NULL AS user
  WHERE 1=0;
-- Drop target view first (safe)
  DROP VIEW IF EXISTS qf_role_with_case_history;
CREATE VIEW qf_role_with_case_history AS
select
  tbl.rownum,
  tbl.extracted_id as testcaseid,
  tbl.depth,
  tbl.file_basename,
  tbl.uniform_resource_id,
  tbl.role_name,
  tbl.title,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'requirementID:') + 15,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'requirementID:') + 15,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as requirementID,
  trim(
    replace(
      SUBSTR(
        tbl.code_content,
        INSTR(tbl.code_content, 'Execution Type:') + 16,
        case
          when INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Execution Type:') + 16,
              length(tbl.code_content)
            ),
            CHAR(10)
          ) = 0 then length(tbl.code_content)
          else INSTR(
            substr(
              tbl.code_content,
              INSTR(tbl.code_content, 'Execution Type:') + 16,
              length(tbl.code_content)
            ),
            CHAR(10)
          )
        end
      ),
      char(10),
      ''
    )
  ) as execution_type,
  prj.title as project_name,
  prj.project_id
from
  qf_role_history tbl
  inner join qf_role_with_project_history prj on prj.uniform_resource_id = tbl.uniform_resource_id
where
  tbl.role_name = 'case'
  and prj.depth = 1;

  DROP VIEW IF EXISTS qf_issue_detail;
-- Create only if github_issues exists
  CREATE VIEW qf_issue_detail AS
SELECT
  *
FROM
  (
    SELECT
      number AS id,
      -- Robustly parse the assignee login string (removes structural JSON quotes)
      COALESCE(
        json_extract(assignee, '$.login'),
        REPLACE(
          substr(
            assignee,
            instr(assignee, '"login":"') + 9,
            instr(substr(assignee, instr(assignee, '"login":"') + 9), '"') - 1
          ),
          '"', ''
        )
      ) AS assignee,
      substr(
        substr(body, instr(body, '**Test Case ID : [') + 18),
        1,
        instr(
          substr(body, instr(body, '**Test Case ID : [') + 18),
          ']**'
        ) - 1
      ) AS testcase_id,
      title AS testcase_description,
      body,
      CASE
        WHEN instr(substr(body, instr(body, 'http')), '"') > 0 THEN substr(
          substr(body, instr(body, 'http')),
          1,
          instr(substr(body, instr(body, 'http')), '"') - 1
        )
        ELSE substr(
          substr(body, instr(body, 'http')),
          1,
          instr(substr(body, instr(body, 'http')), ')') - 1
        )
      END AS attachment_url,
      html_url,
      author_association,
      created_at,
      updated_at,
      state,
      'GIT' AS external_source,
      -- Cleanly extract the user owner
      COALESCE(
        json_extract(user, '$.login'),
        REPLACE(
          substr(user, instr(user, '"login":"') + 9, instr(substr(user, instr(user, '"login":"') + 9), '"') - 1),
          '"', ''
        )
      ) AS owner,
      -- Extract the repo name directly from the URL. Example: https://github.com/owner/repo/issues/...
      -- This fixes the bug where an issue assigned to someone else breaks the project mapping.
      REPLACE(
        substr(
          html_url,
          instr(substr(html_url, 20), '/') + 20, 
          instr(html_url, '/issues') - (instr(substr(html_url, 20), '/') + 20)
        ),
        '/', ''
      ) AS project_name,
      -- Rank rows per issue number: latest state wins, ordered by GitHub's
      -- updated_at (bumped on every close/reopen) then by created_at as
      -- a tie-breaker. This deduplicates across multiple ingest sessions so
      -- only the most recent state is shown — prevents ghost rows in Open
      -- and Closed views after an issue is closed then re-opened.
      ROW_NUMBER() OVER (
        PARTITION BY number
        ORDER BY updated_at DESC, created_at DESC
      ) AS _rn
    FROM
      github_issues
  )
WHERE
  _rn = 1
  AND EXISTS (
    SELECT
      1
    FROM
      sqlite_master
    WHERE
      type = 'view'
      AND name = 'github_issues'
  );

-- Create a view to safely extract file changes from raw GitHub commit records
-- if the standard adapt-singer flattening didn't capture them.
-- Create a view to safely extract file changes from raw GitHub commit records
-- if the standard adapt-singer flattening didn't capture them.
-- Clean view for commit metadata showing Documentation-related changes
DROP VIEW IF EXISTS qf_github_commits;
CREATE VIEW qf_github_commits AS
SELECT 
    sha,
    message,
    author_name,
    commit_date,
    html_url
FROM (
    SELECT 
        sha, 
        json_extract("commit", '$.message') as message,
        json_extract("commit", '$.author.name') as author_name,
        json_extract("commit", '$.author.date') as commit_date,
        html_url,
        ROW_NUMBER() OVER (PARTITION BY sha ORDER BY id DESC) as _rn
    FROM github_commits
) gc WHERE _rn = 1;

-- Create a view to link commits to actual documentation artifacts
DROP VIEW IF EXISTS qf_github_commit_files;
CREATE VIEW qf_github_commit_files AS
SELECT 
    sha,
    filename,
    'modified' as status,
    NULL as patch,
    0 as additions,
    0 as deletions
FROM (
  -- Prefer GitHub provided files if any
  SELECT 
      sha,
      json_extract(f.value, '$.filename') as filename
  FROM github_commits, json_each(files) f
  WHERE filename LIKE '%.md'

  UNION ALL

  -- Fallback to local files modified within 30 days of commit author date
  -- This bridges the gap when the GitHub tap didn't fetch files
  SELECT 
      c.sha,
      ur.uri as filename
  FROM qf_github_commits c
  JOIN uniform_resource ur ON ur.uri LIKE '%.md'
  WHERE (
    ABS(strftime('%s', ur.last_modified_at) - strftime('%s', c.commit_date)) < 2592000
    OR c.message LIKE '%' || replace(replace(ur.uri, replace(ur.uri, ltrim(ur.uri, '/'), ''), ''), '.md', '') || '%'
  )
    AND NOT EXISTS (SELECT 1 FROM github_commits gc WHERE gc.sha = c.sha AND json_array_length(gc.files) > 0)
)
GROUP BY sha, filename;

DROP VIEW IF EXISTS qf_plan_requirement_summary;
CREATE VIEW qf_plan_requirement_summary AS with tbldata as (
    SELECT
      substring(
        body_json_string,
        1,
        instr(body_json_string, ',{"section":{"depth":3')
      ) as body_string,
      r.rownum,
      r.uniform_resource_id,
      COALESCE(
        (SELECT title FROM qf_role_with_project p WHERE p.uniform_resource_id = r.uniform_resource_id LIMIT 1),
        (SELECT title FROM qf_role_with_project LIMIT 1),
        'Unknown'
      ) as project_name
    FROM
      qf_role r
    where
      role_name = 'plan'
  ),
  tblsubdata as (
    select
      *,
      substring(
        body_string,
        instr(body_string, '"paragraph":"@id') + 14,
        instr(
          substring(body_string, instr(body_string, '"paragraph":"@id') + 14),
          '"'
        ) - 1
      ) as PlanID,
      substring(
        body_string,
        instr(body_string, 'plan-name:') + 10,
        CASE 
          WHEN instr(substring(body_string, instr(body_string, 'plan-name:') + 10), 'plan-date:') > 0 
          THEN instr(substring(body_string, instr(body_string, 'plan-name:') + 10), 'plan-date:') - 1
          ELSE length(body_string)
        END
      ) as PlanName,
      TRIM(REPLACE(REPLACE(substring(
        body_string,
        instr(body_string, 'requirementID:') + 14,
        CASE 
          WHEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), 'title:') > 0 
          THEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), 'title:') - 1
          WHEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), CHAR(10)) > 0 
          THEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), CHAR(10)) - 1
          WHEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), '"') > 0
          THEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), '"') - 1
          WHEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), ',') > 0
          THEN instr(substring(lower(body_string), instr(lower(body_string), 'requirementid:') + 14), ',') - 1
          ELSE 50
        END
      ), CHAR(10), ''), CHAR(13), '')) as extracted_requirement_id,
      substring(
        body_string,
        instr(body_string, 'role: requirement'),
        length(body_string)
      ) as body_content
    from
      tbldata
  ),
  ranked_reqs as (
    SELECT 
      *,
      ROW_NUMBER() OVER (
        PARTITION BY project_name, extracted_requirement_id
        ORDER BY rownum DESC
      ) as unique_rn
    FROM tblsubdata
    WHERE extracted_requirement_id IS NOT NULL AND extracted_requirement_id <> ''
  )
select
  rownum,
  uniform_resource_id,
  project_name,
  extracted_requirement_id as requirement_id,
  PlanID,
  PlanName,
  body_content
from
  ranked_reqs
WHERE unique_rn = 1;

DROP VIEW IF EXISTS qf_plan_requirement_details;
CREATE VIEW qf_plan_requirement_details AS WITH RECURSIVE paragraphs(rownum, text, paragraph, pos) AS (
    -- Base case: start with full text and plan info
    SELECT
      rownum,
      body_content,
      NULL,
      0
    FROM
      qf_plan_requirement_summary
    UNION ALL
      -- Recursive step: extract next paragraph
    SELECT
      rownum,
      substr(text, instr(text, '"paragraph":"') + 13),
      substr(
        text,
        instr(text, '"paragraph":"') + 13,
        instr(
          substr(text, instr(text, '"paragraph":"') + 13),
          '"'
        ) - 1
      ),
      pos + 1
    FROM
      paragraphs
    WHERE
      instr(text, '"paragraph":"') > 0
  )
SELECT
  p.rownum,
  p.paragraph AS description,
  p.pos AS rownumdetail
FROM
  paragraphs p
WHERE
  p.paragraph IS NOT NULL;
DROP VIEW IF EXISTS qf_suite_description_summary;
CREATE VIEW qf_suite_description_summary AS with tbldata as (
    SELECT
      substring(
        r.body_json_string,
        1,
        instr(r.body_json_string, ',{"section":{"depth":4')
      ) as body_string,
      r.rownum,
      r.uniform_resource_id
    FROM
      qf_role r
    where
      r.role_name = 'suite'
  ),
  tblsubdata as (
    select
      rownum,
      uniform_resource_id,
      substring(
        body_string,
        instr(body_string, '[{"paragraph":"@id') + 18,
        instr(
          substring(
            body_string,
            instr(body_string, '[{"paragraph":"@id') + 18,
            length(body_string)
          ),
          '"},'
        ) -1
      ) as suite_id,
      substring(
        body_string,
        instr(body_string, '"HFM"}},') + 8,
        length(body_string)
      ) as body_content
    from
      tbldata
  )
select
  rownum,
  uniform_resource_id,
  suite_id,
  body_content
from
  tblsubdata;
DROP VIEW IF EXISTS qf_suite_description_details;
CREATE VIEW qf_suite_description_details AS WITH RECURSIVE paragraphs(rownum, text, paragraph, pos) AS (
    -- Base case: start with full text and plan info
    SELECT
      rownum,
      body_content,
      NULL,
      0
    FROM
      qf_suite_description_summary
    UNION ALL
      -- Recursive step: extract next paragraph
    SELECT
      rownum,
      substr(text, instr(text, '"paragraph":"') + 13),
      substr(
        text,
        instr(text, '"paragraph":"') + 13,
        instr(
          substr(text, instr(text, '"paragraph":"') + 13),
          '"'
        ) - 1
      ),
      pos + 1
    FROM
      paragraphs
    WHERE
      instr(text, '"paragraph":"') > 0
  )
SELECT
  p.pos AS rownumdetail,
  p.rownum,
  p.paragraph AS description
FROM
  paragraphs p
WHERE
  p.paragraph IS NOT NULL;
DROP VIEW IF EXISTS qf_plan_summary;
CREATE VIEW qf_plan_summary AS with tbldata as (
    SELECT
      substring(
        r.body_json_string,
        1,
        instr(r.body_json_string, ',{"section":{"depth":3')
      ) as body_string,
      r.rownum,
      r.uniform_resource_id
    FROM
      qf_role r
    where
      r.role_name = 'plan'
  ),
  tblsubdatal1 as (
    select
      rownum,
      uniform_resource_id,
      substring(
        body_string,
        instr(body_string, 'yaml') + 5,
        length(body_string)
      ) as body_content_l1
    from
      tbldata
  ),
  tblsubdata as (
    select
      rownum,
      uniform_resource_id,
      substring(
        body_content_l1,
        1,
        length(body_content_l1) -- instr(body_content_l1, '"paragraph":"@id')
      ) as body_content
    from
      tblsubdatal1
  )
select
  rownum,
  uniform_resource_id,
  body_content
from
  tblsubdata;
DROP VIEW IF EXISTS qf_plan_detail;
CREATE VIEW qf_plan_detail AS WITH RECURSIVE paragraphs(rownum, text, paragraph, pos) AS (
    -- Base case: start with full text and plan info
    SELECT
      rownum,
      body_content,
      NULL,
      0
    FROM
      qf_plan_summary
    UNION ALL
      -- Recursive step: extract next paragraph
    SELECT
      rownum,
      substr(text, instr(text, '"paragraph":"') + 13),
      substr(
        text,
        instr(text, '"paragraph":"') + 13,
        instr(
          substr(text, instr(text, '"paragraph":"') + 13),
          '"'
        ) - 1
      ),
      pos + 1
    FROM
      paragraphs
    WHERE
      instr(text, '"paragraph":"') > 0
  )
SELECT
  p.pos AS rownumdetail,
  p.rownum,
  p.paragraph AS description
FROM
  paragraphs p
WHERE
  p.paragraph IS NOT NULL;
-- ==============================================================================
  -- qf_case_status_tap
  -- Purpose : Expose test-case status derived from ingested .tap files.
  --           When a .tap file is present in uniform_resource the status for
  --           every test line is resolved by parsing the TAP output:
  --               ok [SURVEILR N] - <description>   → Passed
  --               not ok [SURVEILR N] - <description> → Failed
  --           Test case IDs are normalised to "Test N" format.
  --           For test cases that have NO corresponding .tap entry the rows
  --           still come through from qf_case_status (the markdown-evidence
  --           driven view) so the two sources are united in one place.
  -- ==============================================================================
  DROP VIEW IF EXISTS qf_case_status_tap;
CREATE VIEW qf_case_status_tap AS
SELECT
  cs.uniform_resource_id,
  cs.file_basename,
  cs.test_case_id,
  cs.test_case_title,
  CASE
    WHEN tr.status IS NOT NULL
    AND cs.latest_cycle_date = tr.tap_date THEN tr.status
    ELSE cs.test_case_status
  END AS test_case_status,
  cs.severity,
  cs.latest_cycle AS latest_cycle,
  cs.latest_cycle_date,
  cs.latest_assignee,
  cs.latest_issue_id,
  cs.project_name,
  cs.requirement_ID
FROM
  qf_case_status cs
  JOIN (
    SELECT
      uniform_resource_id,
      ingest_session_id,
      ROW_NUMBER() OVER (
        PARTITION BY uniform_resource_id
        ORDER BY
          ingest_session_id DESC
      ) as rn
    FROM
      ur_ingest_session_fs_path_entry
  ) urpe ON cs.uniform_resource_id = urpe.uniform_resource_id
  AND urpe.rn = 1
  LEFT JOIN qf_tap_results tr ON UPPER(tr.test_case_id) = UPPER(cs.test_case_id)
  AND cs.latest_cycle_date = tr.tap_date
  AND tr.ingest_session_id = urpe.ingest_session_id;
DROP VIEW IF EXISTS qf_requirement_summary;
CREATE VIEW qf_requirement_summary AS
SELECT
  project_name,
  TRIM(requirement_ID) AS requirement_ID,
  COUNT(test_case_id) AS total_test_cases,
  SUM(
    CASE
      WHEN LOWER(test_case_status) IN ('passed', 'ok') THEN 1
      ELSE 0
    END
  ) AS total_passed,
  SUM(
    CASE
      WHEN LOWER(test_case_status) IN ('failed', 'not ok') THEN 1
      ELSE 0
    END
  ) AS total_failed,
  SUM(
    CASE
      WHEN LOWER(test_case_status) = 'closed' THEN 1
      ELSE 0
    END
  ) AS total_closed
FROM
  qf_case_status_tap
WHERE
  requirement_ID IS NOT NULL
  AND requirement_ID <> ''
GROUP BY
  project_name,
  requirement_ID;