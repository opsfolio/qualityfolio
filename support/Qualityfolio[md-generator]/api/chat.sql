-- Create usage logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS chat_usage_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    error_code INTEGER
);

-- Get parameters
SET prompt = COALESCE(:message, '');
SET prompt_pattern = '%' || $prompt || '%';
SET prompt_lower = lower($prompt);

-- Calculate Dynamic Stats
SET project_count = (SELECT count(*) FROM projects);
SET plan_count = (SELECT count(*) FROM plans);
SET case_count = (SELECT count(*) FROM test_cases);
SET last_project_name = (SELECT name FROM projects ORDER BY created_at DESC LIMIT 1);
SET last_project_desc = (SELECT description FROM projects ORDER BY created_at DESC LIMIT 1);

-- Rate Limiting Check (Last 1 minute)
SET requests_last_minute = (SELECT count(*) FROM chat_usage_logs WHERE timestamp > datetime('now', '-1 minute'));

-- Check for Recent 429 (Cooldown - 5 minutes)
SET is_recently_blocked = (SELECT count(*) FROM chat_usage_logs WHERE error_code = 429 AND timestamp > datetime('now', '-5 minutes'));

-- 1. Search Chat Keys (Predefined Q&A)
SET search_keys = (
    SELECT group_concat(response, CHAR(10) || CHAR(10))
    FROM chat_keys
    WHERE keyword LIKE $prompt_pattern OR response LIKE $prompt_pattern
    LIMIT 5
);

-- 2. Search Database (Projects, Plans, Suites, Test Cases, Evidence)
SET search_projects = (
    SELECT group_concat('- **Project:** ' || name, CHAR(10)) 
    FROM (SELECT name FROM projects WHERE name LIKE $prompt_pattern LIMIT 5)
);
SET search_plans = (
    SELECT group_concat('- **Plan:** ' || name, CHAR(10)) 
    FROM (SELECT name FROM plans WHERE name LIKE $prompt_pattern LIMIT 5)
);
SET search_suites = (
    SELECT group_concat('- **Suite:** ' || name, CHAR(10)) 
    FROM (SELECT name FROM suites WHERE name LIKE $prompt_pattern LIMIT 5)
);
SET search_cases = (
    SELECT group_concat('- **Test Case:** ' || title, CHAR(10)) 
    FROM (SELECT title FROM test_cases WHERE title LIKE $prompt_pattern LIMIT 5)
);
SET search_evidence = (
    SELECT group_concat('- **Evidence:** ' || title, CHAR(10)) 
    FROM (SELECT title FROM evidence WHERE title LIKE $prompt_pattern OR content LIKE $prompt_pattern LIMIT 5)
);

-- 3. Security Guardrail & Data Extraction
SET security_warning = CASE 
    WHEN $prompt_lower LIKE '%delete%' OR $prompt_lower LIKE '%drop%' OR $prompt_lower LIKE '%update%' OR $prompt_lower LIKE '%insert%' 
         OR $prompt_lower LIKE '%truncate%' OR $prompt_lower LIKE '%alter%' THEN
        '⚠️ **Security Policy Restricted**' || CHAR(10) ||
        'For data safety, I am strictly a **Read-Only Assistant**.' || CHAR(10) ||
        'I cannot execute or suggest any commands that modify, delete, or insert data.'
    ELSE NULL
END;

SET data_json = CASE 
    WHEN $prompt_lower LIKE '%list projects%' OR $prompt_lower LIKE '%show projects%' OR $prompt_lower LIKE '%all projects%' THEN
        (SELECT json_group_array(json_object('ID', id, 'Name', name, 'Created', created_at)) FROM (SELECT id, name, created_at FROM projects ORDER BY created_at DESC LIMIT 20))
    WHEN $prompt_lower LIKE '%list plans%' OR $prompt_lower LIKE '%show plans%' OR $prompt_lower LIKE '%all plans%' THEN
        (SELECT json_group_array(json_object('ID', id, 'Name', name, 'Project ID', project_id)) FROM (SELECT id, name, project_id FROM plans ORDER BY created_at DESC LIMIT 20))
    WHEN $prompt_lower LIKE '%list suite%' OR $prompt_lower LIKE '%show suite%' OR $prompt_lower LIKE '%all suite%' THEN
        (SELECT json_group_array(json_object('ID', id, 'Name', name, 'Project ID', project_id)) FROM (SELECT id, name, project_id FROM suites ORDER BY id DESC LIMIT 20))
    WHEN $prompt_lower LIKE '%list test case%' OR $prompt_lower LIKE '%show test case%' OR $prompt_lower LIKE '%list case%' OR $prompt_lower LIKE '%show case%' OR $prompt_lower LIKE '%all case%' THEN
        (SELECT json_group_array(json_object('ID', id, 'Title', title, 'Priority', priority, 'Project', project_id)) FROM (SELECT id, title, priority, project_id FROM test_cases ORDER BY created_at DESC LIMIT 20))
    WHEN $prompt_lower LIKE '%list evidence%' OR $prompt_lower LIKE '%show evidence%' OR $prompt_lower LIKE '%all evidence%' THEN
        (SELECT json_group_array(json_object('ID', id, 'Title', title, 'Status', status)) FROM (SELECT id, title, status FROM evidence ORDER BY id DESC LIMIT 20))
    WHEN $prompt_lower LIKE '%list team%' OR $prompt_lower LIKE '%show team%' OR $prompt_lower LIKE '%team member%' THEN
        (SELECT json_group_array(json_object('Name', full_name, 'Designation', designation)) FROM team_members LIMIT 20)
    WHEN $prompt_lower LIKE '%recent cases%' OR $prompt_lower LIKE '%latest cases%' THEN
        (SELECT json_group_array(json_object('ID', id, 'Title', title)) FROM (SELECT id, title FROM test_cases ORDER BY created_at DESC LIMIT 10))
    -- Status-wise
    WHEN $prompt_lower LIKE '%by status%' OR $prompt_lower LIKE '%status wise%' OR $prompt_lower LIKE '%cases by status%' THEN
        (SELECT json_group_array(json_object('Status', status_name, 'Count', cnt))
         FROM (SELECT COALESCE(tcs.name, 'Open') AS status_name, COUNT(*) AS cnt
               FROM test_cases tc LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id
               GROUP BY status_name ORDER BY cnt DESC))
    -- Open / closed / specific status
    WHEN $prompt_lower LIKE '%open case%' OR $prompt_lower LIKE '%open test case%' THEN
        (SELECT json_group_array(json_object('ID', tc.id, 'Title', tc.title, 'Priority', tc.priority))
         FROM test_cases tc LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id
         WHERE COALESCE(tcs.name, 'Open') = 'Open' LIMIT 20)
    -- Assignee-wise
    WHEN $prompt_lower LIKE '%by assignee%' OR $prompt_lower LIKE '%assignee wise%' OR $prompt_lower LIKE '%cases by assignee%' OR $prompt_lower LIKE '%who has%' THEN
        (SELECT json_group_array(json_object('Assignee', assignee_name, 'Count', cnt))
         FROM (SELECT COALESCE(tm.full_name, 'Unassigned') AS assignee_name, COUNT(*) AS cnt
               FROM test_cases tc LEFT JOIN team_members tm ON tm.id = tc.assignee_id
               GROUP BY assignee_name ORDER BY cnt DESC))
    -- Unassigned
    WHEN $prompt_lower LIKE '%unassigned%' THEN
        (SELECT json_group_array(json_object('ID', id, 'Title', title, 'Priority', priority))
         FROM test_cases WHERE assignee_id IS NULL LIMIT 20)
    ELSE NULL
END;

SET local_response = CASE 
    WHEN $security_warning IS NOT NULL THEN $security_warning
    
    WHEN $prompt_lower LIKE '%project count%' OR $prompt_lower LIKE '%how many projects%' THEN
        '🔢 **Total Projects**: ' || $project_count
    WHEN $prompt_lower LIKE '%plan count%' OR $prompt_lower LIKE '%how many plans%' THEN
        '📋 **Total Plans**: ' || $plan_count
    WHEN $prompt_lower LIKE '%case count%' OR $prompt_lower LIKE '%test case count%' THEN
        '🧪 **Total Test Cases**: ' || $case_count
    WHEN $prompt_lower LIKE '%last project%' OR $prompt_lower LIKE '%latest project%' THEN
        '🆕 **Last Project**: ' || $last_project_name || CHAR(10) || '_' || COALESCE($last_project_desc, 'No description') || '_'
    WHEN $prompt_lower LIKE '%stats%' OR $prompt_lower LIKE '%summary%' THEN
        '📊 **System Statistics**' || CHAR(10) || CHAR(10) ||
        '- **Projects**: ' || $project_count || CHAR(10) ||
        '- **Plans**: ' || $plan_count || CHAR(10) ||
        '- **Test Cases**: ' || $case_count || CHAR(10) ||
        '- **Last Active**: ' || $last_project_name
    -- Status-wise quick counts
    WHEN $prompt_lower LIKE '%how many open%' OR $prompt_lower LIKE '%open test case%' OR $prompt_lower LIKE '%open cases%' THEN
        '🟢 **Open Test Cases**: ' || (SELECT COUNT(*) FROM test_cases tc LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id WHERE COALESCE(tcs.name,'Open') = 'Open')
    WHEN $prompt_lower LIKE '%how many closed%' OR $prompt_lower LIKE '%closed cases%' THEN
        '🔴 **Closed Test Cases**: ' || (SELECT COUNT(*) FROM test_cases tc LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id WHERE tcs.name = 'Closed')
    WHEN $prompt_lower LIKE '%how many pass%' OR $prompt_lower LIKE '%passed cases%' THEN
        '✅ **Passed Test Cases**: ' || (SELECT COUNT(*) FROM test_cases tc LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id WHERE tcs.name LIKE '%Pass%')
    WHEN $prompt_lower LIKE '%how many fail%' OR $prompt_lower LIKE '%failed cases%' THEN
        '❌ **Failed Test Cases**: ' || (SELECT COUNT(*) FROM test_cases tc LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id WHERE tcs.name LIKE '%Fail%')
    -- Assignee-wise quick count
    WHEN $prompt_lower LIKE '%how many unassigned%' OR $prompt_lower LIKE '%unassigned test%' THEN
        '👤 **Unassigned Test Cases**: ' || (SELECT COUNT(*) FROM test_cases WHERE assignee_id IS NULL)
    WHEN $data_json IS NOT NULL THEN
        '📋 **Here are the results for your request:**'
    WHEN COALESCE($search_keys, '') != '' THEN $search_keys
    WHEN COALESCE($search_projects, '') != '' OR COALESCE($search_plans, '') != '' OR COALESCE($search_suites, '') != '' OR COALESCE($search_cases, '') != '' OR COALESCE($search_evidence, '') != '' THEN
        '### 🔍 Database Matches for "' || $prompt || '"' || CHAR(10) || CHAR(10) ||
        COALESCE($search_projects || CHAR(10), '') ||
        COALESCE($search_plans || CHAR(10), '') ||
        COALESCE($search_suites || CHAR(10), '') ||
        COALESCE($search_cases || CHAR(10), '') ||
        COALESCE($search_evidence, '')
    ELSE NULL
END;

-- 4. AI Interaction
-- API Configuration
SET api_key = COALESCE(
    sqlpage.environment_variable('API_KEY'), 
    sqlpage.environment_variable('GROQ_API_KEY'), 
    sqlpage.environment_variable('GEMINI_API_KEY')
);
SET api_endpoint = COALESCE(
    sqlpage.environment_variable('ANTIGRAVITY_API_ENDPOINT'),
    'https://api.groq.com/openai/v1/chat/completions'
);
SET is_groq = CASE WHEN $api_endpoint LIKE '%groq.com%' THEN 1 ELSE 0 END;
SET api_model = COALESCE(sqlpage.environment_variable('GROQ_MODEL'), 'llama-3.3-70b-versatile');

-- Dynamically fetch full database schema (Tables & Columns)
SET full_db_schema = (
    SELECT group_concat('Table: ' || table_name || ' (Columns: ' || cols || ')', CHAR(10))
    FROM (
        SELECT 
            m.name AS table_name,
            (SELECT group_concat(p.name, ', ') FROM pragma_table_info(m.name) AS p) AS cols
        FROM sqlite_master m
        WHERE type = 'table' 
          AND name NOT LIKE 'sqlite_%' 
          AND name NOT LIKE 'sqlpage_%'
          AND name NOT LIKE '_sqlx_%'
          AND name NOT LIKE 'chat_usage_logs'
    )
);

-- Rich data context from ALL major tables
SET ctx_projects = (
    SELECT 'Projects:' || CHAR(10) || group_concat(
        '  [' || p.id || '] ' || p.name || ' | Schema: ' || COALESCE(pm.schema_level, '?') ||
        ' | TC Count: ' || COALESCE(pm.test_cases_count, '?') ||
        ' | Req: ' || COALESCE(SUBSTR(pm.requirement_text, 1, 60), '-'), CHAR(10)
    )
    FROM projects p
    LEFT JOIN project_metadata pm ON pm.project_id = p.id
    LIMIT 20
);

SET ctx_plans = (
    SELECT 'Plans:' || CHAR(10) || group_concat(
        '  [' || pl.id || '] ' || pl.name || ' | Project: ' || p.name, CHAR(10)
    )
    FROM plans pl
    LEFT JOIN projects p ON p.id = pl.project_id
    LIMIT 20
);

SET ctx_suites = (
    SELECT 'Suites:' || CHAR(10) || group_concat(
        '  [' || s.id || '] ' || s.name || ' | Project: ' || p.name, CHAR(10)
    )
    FROM suites s
    LEFT JOIN projects p ON p.id = s.project_id
    LIMIT 30
);

SET ctx_test_cases = (
    SELECT 'Test Cases (latest 30):' || CHAR(10) || group_concat(
        '  [' || tc.id || '] ' || tc.title ||
        ' | Priority: ' || COALESCE(tc.priority, '-') ||
        ' | Status: ' || COALESCE(tcs.name, 'Open') ||
        ' | Project: ' || COALESCE(p.name, '-'), CHAR(10)
    )
    FROM test_cases tc
    LEFT JOIN projects p ON p.id = tc.project_id
    LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id
    ORDER BY tc.created_at DESC
    LIMIT 30
);

SET ctx_evidence = (
    SELECT 'Evidence (latest 20):' || CHAR(10) || group_concat(
        '  [' || e.id || '] ' || e.title || ' | Status: ' || COALESCE(e.status, '-') ||
        ' | TC: ' || COALESCE(tc.title, '-'), CHAR(10)
    )
    FROM evidence e
    LEFT JOIN test_cases tc ON tc.id = e.test_case_id
    ORDER BY e.id DESC
    LIMIT 20
);

SET ctx_team = (
    SELECT 'Team Members:' || CHAR(10) || group_concat('  - ' || full_name || ' (' || COALESCE(designation, '-') || ')', CHAR(10))
    FROM team_members
);

SET ctx_ref = (
    'Test Types: ' || COALESCE((SELECT group_concat(name, ', ') FROM test_types), '-') || CHAR(10) ||
    'Scenario Types: ' || COALESCE((SELECT group_concat(name, ', ') FROM scenario_types), '-') || CHAR(10) ||
    'Execution Types: ' || COALESCE((SELECT group_concat(name, ', ') FROM execution_types), '-') || CHAR(10) ||
    'Statuses: ' || COALESCE((SELECT group_concat(name, ', ') FROM test_case_statuses), '-')
);

-- Test cases grouped by STATUS
-- Test cases grouped by STATUS
SET ctx_cases_by_status = (
    SELECT 'Test Cases by Status:' || CHAR(10) || group_concat(summary_line, CHAR(10))
    FROM (
        SELECT '  ' || COALESCE(tcs.name, 'Open') || ': ' || COUNT(*) || ' test case(s)' AS summary_line
        FROM test_cases tc
        LEFT JOIN test_case_statuses tcs ON tcs.id = tc.status_id
        GROUP BY COALESCE(tcs.name, 'Open')
        ORDER BY COUNT(*) DESC
    )
);

-- Test cases grouped by ASSIGNEE
-- Test cases grouped by ASSIGNEE
SET ctx_cases_by_assignee = (
    SELECT 'Test Cases by Assignee:' || CHAR(10) || group_concat(summary_line, CHAR(10))
    FROM (
        SELECT '  ' || COALESCE(tm.full_name, 'Unassigned') || ': ' || COUNT(*) || ' test case(s)' AS summary_line
        FROM test_cases tc
        LEFT JOIN team_members tm ON tm.id = tc.assignee_id
        GROUP BY COALESCE(tm.full_name, 'Unassigned')
        ORDER BY COUNT(*) DESC
    )
);

SET suite_count = (SELECT count(*) FROM suites);
SET evidence_count = (SELECT count(*) FROM evidence);
SET team_count = (SELECT count(*) FROM team_members);

SET stats_ctx = 'Summary Stats: ' ||
    $project_count || ' projects, ' || $plan_count || ' plans, ' ||
    $suite_count || ' suites, ' || $case_count || ' test cases, ' ||
    $evidence_count || ' evidence records, ' || $team_count || ' team members.';

SET full_prompt = 'You are a helpful and READ-ONLY assistant for QualityFolio, a test management system.

Database Schema:
' || $full_db_schema || '

' || $stats_ctx || '

' || $ctx_projects || '

' || $ctx_plans || '

' || $ctx_suites || '

' || $ctx_test_cases || '

' || $ctx_evidence || '

' || $ctx_team || '

Assignee-wise Summary:
' || $ctx_cases_by_assignee || '

Status-wise Summary:
' || $ctx_cases_by_status || '

Reference Data:
' || $ctx_ref || '

User Question: ' || $prompt || '

Strict Instructions:
1. Use the full context above to give accurate, specific answers.
2. Reference actual names, IDs, and counts from the data above.
3. ONLY suggest SELECT queries if specifically asked for SQL.
4. NEVER suggest or use DELETE, UPDATE, INSERT, DROP, or ALTER.
5. If asked to modify data, refuse and state your safety policy.
6. Use Markdown formatting. Be concise but complete.';

-- Call API with Strict Rate Limit (3 RPM) and Cooldown check
SET raw_api_response = CASE 
    WHEN $local_response IS NULL AND length($prompt) > 4 AND $api_key IS NOT NULL 
         AND $requests_last_minute < 3 AND $is_recently_blocked = 0 THEN
        CASE 
            WHEN $is_groq = 1 THEN
                -- Groq/OpenAI Format
                sqlpage.fetch(json_object(
                    'url', $api_endpoint,
                    'method', 'POST',
                    'headers', json_object(
                        'Content-Type', 'application/json',
                        'Authorization', 'Bearer ' || $api_key
                    ),
                    'body', json_object(
                        'model', $api_model,
                        'messages', json_array(
                            json_object('role', 'user', 'content', $full_prompt)
                        )
                    )
                ))
            ELSE
                -- Gemini Format
                sqlpage.fetch(json_object(
                    'url', $api_endpoint || '?key=' || $api_key,
                    'method', 'POST',
                    'headers', json_object('Content-Type', 'application/json'),
                    'body', json_object(
                        'contents', json_array(
                            json_object('parts', json_array(json_object('text', $full_prompt)))
                        )
                    )
                ))
        END
    ELSE NULL
END;

-- Track Usage Log (Only if API was called)
INSERT INTO chat_usage_logs (timestamp, error_code)
SELECT current_timestamp, json_extract($raw_api_response, '$.error.code') 
WHERE $raw_api_response IS NOT NULL;

-- Extract Content or Error
SET ai_response = CASE 
    WHEN $is_groq = 1 THEN json_extract($raw_api_response, '$.choices[0].message.content')
    ELSE json_extract($raw_api_response, '$.candidates[0].content.parts[0].text')
END;

SET api_error_code = json_extract($raw_api_response, '$.error.code');
SET api_error_msg = json_extract($raw_api_response, '$.error.message');

-- 5. Suggestions
SET suggested_questions = '### 💡 Try searching for: Project Count, Last Project, help';

-- Final Output logic
SET response_text = CASE 
    WHEN length($prompt) <= 2 THEN '👋 **Hello!**' || CHAR(10) || $suggested_questions
    WHEN $local_response IS NOT NULL THEN $local_response
    WHEN $ai_response IS NOT NULL THEN '🤖 **AI Response**:' || CHAR(10) || CHAR(10) || $ai_response
    WHEN $is_recently_blocked > 0 THEN '⏳ **AI Cooldown**: We received a "Too Many Requests" error from Google recently. Please wait a few minutes before asking more dynamic questions.'
    WHEN $requests_last_minute >= 3 THEN '⚠️ **Rate Limit Reached (3 req/min)**: We blocked this call to protect your API quota. Try again in 60 seconds.'
    WHEN $api_error_code = 429 THEN '🚫 **Google Quota Exhausted**: You have hit your Google Gemini daily limit or total quota. Check your Google AI Studio billing/usage.'
    WHEN $api_error_code IS NOT NULL THEN '⚠️ **AI Error (' || $api_error_code || ')**: ' || $api_error_msg
    ELSE '❌ **No matches found**.'
END;

SELECT 'json' AS component;
SELECT json_object(
    'success', 1, 
    'response', $response_text,
    'data', json(COALESCE($data_json, '[]'))
) AS contents;
