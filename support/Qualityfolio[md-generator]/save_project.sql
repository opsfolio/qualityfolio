-- 0. Ensure metadata table exists (Robustness)
CREATE TABLE IF NOT EXISTS project_metadata (
    project_id INTEGER PRIMARY KEY,
    schema_level TEXT,
    requirement_text TEXT,
    requirement_id TEXT,
    test_cases_count INTEGER,
    default_creator_id INTEGER,
    test_type_id INTEGER,
    cycle TEXT,
    cycle_date TEXT,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

-- Ensure debug_log table exists (Immediate fix)
CREATE TABLE IF NOT EXISTS debug_log (
    id INTEGER PRIMARY KEY,
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Ensure columns exist (Migration for existing tables)
-- If requirement_id is missing, redirect to the one-time migration script
SELECT 'redirect' AS component, 'init_metadata.sql' AS link
WHERE (SELECT COUNT(*) FROM pragma_table_info('project_metadata') WHERE name='requirement_id') = 0;

-- 1. Insert Project
INSERT INTO projects (name, description, objectives, risks, full_docs_json)
SELECT :project_name, 'Generated project', :objectives, :risks, :full_docs_json
WHERE :project_name IS NOT NULL;

SET project_id = LAST_INSERT_ROWID();

-- 2. Save Project Metadata
INSERT INTO project_metadata (
    project_id, 
    schema_level, 
    requirement_text, 
    requirement_id, 
    test_cases_count, 
    default_creator_id, 
    test_type_id, 
    cycle, 
    cycle_date
)
SELECT 
    $project_id, 
    :schema_level, 
    :requirement_text, 
    :requirement_id, 
    :test_cases_count, 
    :default_creator, 
    :test_type, 
    :cycle, 
    :cycle_date
WHERE $project_id > 0;

-- 3. Plan Handling (Dynamic Level 5)
-- We no longer insert a single Global Plan for Level 5 here. 
-- Instead, we handle it via the config table below.

-- 4. Prepare Configuration Table
-- 3. Redirect (No longer generating defaults)
-- SELECT 'redirect' AS component, 
--        'entries.sql' AS link;

-- 3. LEVEL 3 AUTO-GENERATION (AI Powered)
-- Only run if schema_level is '3_level' and project was created successfully
-- Fetch count/test type from metadata (already inserted above)

-- Build AI Prompt for Level 3
SET prompt = 'Generate ' || :test_cases_count || ' test cases for: ' || COALESCE(:requirement_text, 'General software') || '
Test Type: ' || (SELECT name FROM test_types WHERE id = :test_type LIMIT 1) || '

Return ONLY a JSON array with these fields: title, priority, scenario_type, execution_type, description, pre_conditions, steps, expected_result.
No introductory text.
Example: [{"title": "Login", "priority": "High", "steps": "1. Enter user\n2. Click Login", "expected_result": "Success"}]';

-- Call Groq API (Use faster model)
SET api_key = COALESCE(sqlpage.environment_variable('GROQ_API_KEY'), sqlpage.environment_variable('API_KEY'));
SET api_model = 'llama3-8b-8192'; -- Force faster model to prevent timeouts

SET api_response = CASE WHEN :schema_level = '3_level' THEN
    sqlpage.fetch(json_object(
        'url', 'https://api.groq.com/openai/v1/chat/completions',
        'method', 'POST',
        'headers', json_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || $api_key
        ),
        'body', json_object(
            'model', $api_model,
            'messages', json_array(
                json_object('role', 'user', 'content', $prompt)
            )
        )
    ))
    ELSE NULL
END;

-- Parse AI Response
SET generated_content = CASE WHEN :schema_level = '3_level' AND $api_response IS NOT NULL THEN
    REPLACE(REPLACE(REPLACE(json_extract($api_response, '$.choices[0].message.content'), '```json', ''), '```', ''), char(10), '')
    ELSE NULL
END;

INSERT INTO debug_log (content) VALUES ('L3 Response: ' || COALESCE($api_response, 'NULL'));
INSERT INTO debug_log (content) VALUES ('L3 Generated: ' || COALESCE($generated_content, 'NULL'));

-- Insert Generated Test Cases for Level 3 (No Suite)
INSERT INTO test_cases (project_id, suite_id, title, description, pre_conditions, steps, expected_result, priority, test_type_id, scenario_type_id, execution_type_id, status_id, assignee_id)
SELECT 
    $project_id, 
    NULL, 
    json_extract(value, '$.title'),
    json_extract(value, '$.description'),
    json_extract(value, '$.pre_conditions'),
    json_extract(value, '$.steps'),
    json_extract(value, '$.expected_result'),
    COALESCE(json_extract(value, '$.priority'), 'Medium'),
    (SELECT id FROM test_types WHERE name = json_extract(value, '$.test_type') LIMIT 1),
    (SELECT id FROM scenario_types WHERE name = json_extract(value, '$.scenario_type') LIMIT 1),
    (SELECT id FROM execution_types WHERE name = json_extract(value, '$.execution_type') LIMIT 1),
    (SELECT id FROM test_case_statuses WHERE name = 'Open' LIMIT 1),
    :default_creator
FROM json_each($generated_content)
WHERE :schema_level = '3_level' AND $project_id > 0 AND json_valid($generated_content);

-- Fallback/Placeholder for Level 3 if AI fails
INSERT INTO test_cases (project_id, suite_id, title, test_type_id, scenario_type_id, execution_type_id, status_id, assignee_id)
SELECT 
    $project_id, 
    NULL,
    'Manual Test Case (AI Generation Failed)', 
    :test_type,
    1, 1,
    (SELECT id FROM test_case_statuses WHERE name = 'Open' LIMIT 1),
    :default_creator
WHERE :schema_level = '3_level' AND $project_id > 0 AND ($generated_content IS NULL OR NOT json_valid($generated_content));



-- 10. Redirect
-- SELECT 'redirect' AS component, 
--        COALESCE(:redirect_url, 'generate_results.sql?project_id=' || COALESCE($project_id, 0)) AS link;

-- 4. LEVEL 4 & 5 AUTO-GENERATION (Default Plan/Suite)

-- 4a. Create Default Plan (Level 5 Only)
INSERT INTO plans (project_id, name, description, plan_date, created_by_id, scope)
SELECT $project_id, 'Default Plan', 'Auto-generated plan', CURRENT_DATE, :default_creator, :plan_scope
WHERE :schema_level = '5_level';

SET new_plan_id = CASE WHEN :schema_level = '5_level' THEN LAST_INSERT_ROWID() ELSE NULL END;

-- 4b. Create Default Suite (Level 4 & 5)
INSERT INTO suites (project_id, plan_id, name, description, suite_date, created_by_id)
SELECT 
    $project_id, 
    $new_plan_id, -- NULL for Level 4, Valid ID for Level 5
    'Default Suite', 
    'Auto-generated suite', 
    CURRENT_DATE, 
    :default_creator
WHERE :schema_level IN ('4_level', '5_level');

SET new_suite_id = CASE WHEN :schema_level IN ('4_level', '5_level') THEN LAST_INSERT_ROWID() ELSE NULL END;

-- 4c. Generate Test Cases for Suite (Level 4 & 5)
-- Build Prompt
SET prompt_suite = 'Generate ' || :test_cases_count || ' test cases for: ' || COALESCE(:requirement_text, 'General software') || '
Context: ' || CASE WHEN :schema_level = '5_level' THEN 'Part of Default Plan -> Default Suite' ELSE 'Part of Default Suite' END || '
Test Type: ' || (SELECT name FROM test_types WHERE id = :test_type LIMIT 1) || '

Return ONLY a JSON array with these fields: title, priority, scenario_type, execution_type, description, pre_conditions, steps, expected_result.
No introductory text.
Example: [{"title": "Verify module", "priority": "High", "steps": "1. Open module\n2. Check", "expected_result": "Loads"}]';

-- Call AI (Reuse API setup with faster model)
SET api_response_suite = CASE WHEN :schema_level IN ('4_level', '5_level') THEN
    sqlpage.fetch(json_object(
        'url', 'https://api.groq.com/openai/v1/chat/completions',
        'method', 'POST',
        'headers', json_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || $api_key
        ),
        'body', json_object(
            'model', 'llama3-8b-8192', -- Faster model
            'messages', json_array(
                json_object('role', 'user', 'content', $prompt_suite)
            )
        )
    ))
    ELSE NULL
END;

-- Parse Response
SET generated_content_suite = CASE WHEN :schema_level IN ('4_level', '5_level') AND $api_response_suite IS NOT NULL THEN
    REPLACE(REPLACE(REPLACE(json_extract($api_response_suite, '$.choices[0].message.content'), '```json', ''), '```', ''), char(10), '')
    ELSE NULL
END;

INSERT INTO debug_log (content) VALUES ('L4/5 Response: ' || COALESCE($api_response_suite, 'NULL'));
INSERT INTO debug_log (content) VALUES ('L4/5 Generated: ' || COALESCE($generated_content_suite, 'NULL'));

-- Insert Test Cases (Level 4/5)
INSERT INTO test_cases (project_id, suite_id, title, description, pre_conditions, steps, expected_result, priority, test_type_id, scenario_type_id, execution_type_id, status_id, assignee_id)
SELECT 
    $project_id, 
    $new_suite_id, 
    json_extract(value, '$.title'),
    json_extract(value, '$.description'),
    json_extract(value, '$.pre_conditions'),
    json_extract(value, '$.steps'),
    json_extract(value, '$.expected_result'),
    COALESCE(json_extract(value, '$.priority'), 'Medium'),
    (SELECT id FROM test_types WHERE name = json_extract(value, '$.test_type') LIMIT 1),
    (SELECT id FROM scenario_types WHERE name = json_extract(value, '$.scenario_type') LIMIT 1),
    (SELECT id FROM execution_types WHERE name = json_extract(value, '$.execution_type') LIMIT 1),
    (SELECT id FROM test_case_statuses WHERE name = 'Open' LIMIT 1),
    :default_creator
FROM json_each($generated_content_suite)
WHERE :schema_level IN ('4_level', '5_level') AND $project_id > 0 AND json_valid($generated_content_suite);

-- Fallback (Level 4/5)
INSERT INTO test_cases (project_id, suite_id, title, test_type_id, scenario_type_id, execution_type_id, status_id, assignee_id)
SELECT 
    $project_id, 
    $new_suite_id,
    'Manual Test Case (AI Generation Failed)', 
    :test_type,
    1, 1,
    (SELECT id FROM test_case_statuses WHERE name = 'Open' LIMIT 1),
    :default_creator
WHERE :schema_level IN ('4_level', '5_level') AND $project_id > 0 AND ($generated_content_suite IS NULL OR NOT json_valid($generated_content_suite));

-- Evidence (Level 4/5)



-- Final Redirect
SELECT 'redirect' AS component, 
       COALESCE(:redirect_url, 'generate_results.sql?project_id=' || COALESCE($project_id, 0)) AS link;
