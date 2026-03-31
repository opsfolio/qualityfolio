-- Page to manage Test Cases for a Suite

-- ============================================================
-- STEP 1: All SET + REDIRECT logic BEFORE any component output
-- ============================================================

-- Ensure suite_configs table exists (safe plain SQL — no output, runs before redirect)
CREATE TABLE IF NOT EXISTS suite_configs (
    suite_id INTEGER PRIMARY KEY REFERENCES suites(id) ON DELETE CASCADE,
    test_cases_count INTEGER
);

-- Determine Schema Level and Default Creator (no output)
SET schema_level = (SELECT schema_level FROM project_metadata WHERE project_id = $project_id);
SET default_creator_id = (SELECT default_creator_id FROM project_metadata WHERE project_id = $project_id);

-- (No redirect to suites — all schema levels can land here from the project list)

-- AUTO AI GENERATION: Only redirect to generate if a specific suite is selected
-- and that suite has no real test cases yet
SELECT 'redirect' AS component,
       'generate_test_cases.sql?project_id=' || $project_id ||
       CASE WHEN $suite_id IS NOT NULL AND $suite_id != '' THEN '&suite_id=' || $suite_id ELSE '' END ||
       '&count=' || COALESCE(
           (SELECT test_cases_count FROM suite_configs WHERE suite_id = $suite_id),
           (SELECT test_cases_count FROM project_metadata WHERE project_id = $project_id),
           5
       )
       AS link
WHERE $suite_id IS NOT NULL AND $suite_id != ''
  AND NOT EXISTS (
    SELECT 1 FROM test_cases tc
    WHERE tc.project_id = $project_id
      AND tc.suite_id = $suite_id
      AND tc.title NOT LIKE 'Manual Test Case (AI Generation Failed)%'
      AND tc.title NOT LIKE 'AI Generation Failed%'
);

-- ============================================================
-- STEP 2: Shell (first component output — after all redirects)
-- ============================================================
SELECT 'shell' AS component,
       'Qualityfolio AI' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
        json_array(
             'css/table_wrap.css',
             '/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/css/chat.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/css/pikaday.css'
        ) AS css,
        json_array(
             '/js/layout.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/js/refine.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/js/chat.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
              '/js/pikaday.js',
             '/js/md-date-picker.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS javascript,
        json_array(
            json_object('title', 'Project', 'link', 'entries.sql', 'icon', 'folder'),
            json_object('title', 'Settings', 'link', 'settings.sql', 'icon', 'settings')
        ) AS menu_item;

-- Ensure test_case_statuses table exists (after shell is fine)
SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/027_create_test_case_statuses.sql') AS properties;

-- ============================================================
-- STEP 3: Page content
-- ============================================================

-- Hero
SELECT 'hero' AS component,
       'Manage Test Cases' AS title;

-- Back Button (contextual: go to suites if suite_id known, else go to project list)
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back' AS title,
       CASE 
           WHEN NULLIF($suite_id, '') IS NOT NULL THEN
               'suites.sql?project_id=' || $project_id ||
               CASE WHEN (SELECT plan_id FROM suites WHERE id = $suite_id) IS NOT NULL 
                    THEN '&plan_id=' || (SELECT plan_id FROM suites WHERE id = $suite_id)
                    ELSE '' END
           ELSE 'entries.sql'
       END AS link,
       'arrow-left' AS icon,
       'outline-primary' AS color;

-- Bulk Assign Button
SELECT 'Bulk Assign' AS title,
       'bulk_assign_test_cases.sql?project_id=' || $project_id || 
       CASE WHEN $suite_id IS NOT NULL AND $suite_id != '' THEN '&suite_id=' || $suite_id ELSE '' END AS link,
       'users' AS icon,
       'outline-success' AS color;

-- Header Context: Schema → Project → Plan → Suite (schema-level aware)
SELECT 'text' AS component,
       '**Schema:** ' || REPLACE($schema_level, '_', '-') || '  ' || CHAR(10) ||
       '**Project:** ' || COALESCE((SELECT name FROM projects WHERE id = $project_id), 'Unknown') ||
       -- Level 5: add Plan
       CASE 
           WHEN $schema_level = '5_level' AND NULLIF($suite_id, '') IS NOT NULL THEN
               '  ' || CHAR(10) || '**Plan:** ' || 
               COALESCE((SELECT p.name FROM plans p 
                         INNER JOIN suites s ON s.plan_id = p.id 
                         WHERE s.id = $suite_id), 'N/A')
           ELSE ''
       END ||
       -- Level 4 + 5: add Suite
       CASE 
           WHEN NULLIF($suite_id, '') IS NOT NULL THEN
               '  ' || CHAR(10) || '**Suite:** ' || 
               COALESCE((SELECT name FROM suites WHERE id = $suite_id), 'Unknown')
           ELSE ''
       END
       AS contents_md;

-- Create New Test Case Form
SELECT 'form' AS component,
       'pages/test_cases/save.sql' AS action,
       'Add Test Case' AS validate,
       'Create New Test Case' AS title;

-- Hidden fields
SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;
SELECT 'suite_id' AS name, 'hidden' AS type, $suite_id AS value;

-- ROW 1: Assignee (Default Creator) + Test Type
SELECT 'Assignee' AS label, 'assignee_id' AS name, 'select' AS type, 6 AS width,
       (SELECT json_group_array(json_object('label', full_name, 'value', id, 'selected', id = $default_creator_id)) FROM team_members) AS options;
SELECT 'Test Type' AS label, 'test_type' AS name, 'select' AS type, '-- Select Type --' AS placeholder, 6 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id)) FROM test_types) AS options;

-- ROW 2: Cycle + Cycle Date
SELECT 'Cycle' AS label, 'cycle' AS name, 'text' AS type,
       COALESCE((SELECT cycle FROM suites WHERE id = $suite_id), '1.0') AS value,
       6 AS width;

SELECT 'html' AS component, 
  '<div class="col-6"><div class="qfg-field"><label>Cycle Date (MM-DD-YYYY)</label>
     <div style="position:relative;display:flex;align-items:center;">
       <input type="text" id="cycle_date-display" class="qf-date" placeholder="MM-DD-YYYY" value="' || STRFTIME('%m-%d-%Y', 'now') || '" style="width:100%;cursor:pointer;padding-right:28px;" />
       <input type="hidden" name="cycle_date" id="cycle_date" value="' || STRFTIME('%Y-%m-%d', 'now') || '" />
       <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
     </div>
   </div></div>' AS html;

-- ROW 3: Title (full width)
SELECT 'Title' AS label, 'title' AS name, 'text' AS type, 'Enter Test Case Title' AS placeholder, 12 AS width, TRUE AS required;

-- ROW 4: Requirements / Description with AI Refine button injected via JS
SELECT 'Requirements' AS label, 'description' AS name, 'textarea' AS type,
       'Enter topic (e.g. "Login") and click AI Refine, or paste full requirements...' AS placeholder,
       5 AS rows, 12 AS width;

-- ROW 5: Pre-conditions + Steps side by side
SELECT 'Pre-conditions' AS label, 'pre_conditions' AS name, 'textarea' AS type, 'Pre-conditions for this test case' AS placeholder, 4 AS rows, 6 AS width;
SELECT 'Steps' AS label, 'steps' AS name, 'textarea' AS type, 'Step 1: ...&#10;Step 2: ...&#10;Step 3: ...' AS placeholder, 4 AS rows, 6 AS width;

-- ROW 6: Expected Result (full width)
SELECT 'Expected Result' AS label, 'expected_result' AS name, 'textarea' AS type, 'Expected Result' AS placeholder, 3 AS rows, 12 AS width;

-- ROW 7: Requirement ID + Tags
SELECT 'Requirement ID' AS label, 'requirement_id' AS name, 'text' AS type, 'e.g. REGM-001' AS placeholder, 6 AS width;
SELECT 'Tags' AS label, 'tags' AS name, 'text' AS type, 'e.g. Login, Dropdown, Navigation' AS placeholder, 6 AS width;

-- ROW 8: Scenario Type + Execution Type + Priority
SELECT 'Scenario Type' AS label, 'scenario_type' AS name, 'select' AS type, '-- Select Scenario --' AS placeholder, 4 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id)) FROM scenario_types) AS options;
SELECT 'Execution Type' AS label, 'execution_type' AS name, 'select' AS type, '-- Select Execution --' AS placeholder, 4 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id)) FROM execution_types) AS options;
SELECT 'Priority' AS label, 'priority' AS name, 'select' AS type, 4 AS width,
       json_array(
           json_object('label', 'High', 'value', 'High'),
           json_object('label', 'Medium', 'value', 'Medium'),
           json_object('label', 'Low', 'value', 'Low')
       ) AS options;

-- ROW 9: Status
SELECT 'Status' AS label, 'status_id' AS name, 'select' AS type, 6 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id, 'selected', name = 'Open')) FROM test_case_statuses ORDER BY name) AS options;

-- Divider
SELECT 'divider' AS component;

-- Test Cases List
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown;

SELECT 
    tc.title AS 'Title',
    COALESCE(tm.full_name, 'Unassigned') AS 'Assignee',
    tc.priority AS 'Priority',
    COALESCE(tcs.name, '—') AS 'Status',
    '[Evidence](evidence.sql?test_case_id=' || tc.id || '&project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') || ') | [✏️](edit_test_case.sql?id=' || tc.id || '&project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') || ') | [🗑️](delete_test_case.sql?id=' || tc.id || '&project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') || ')' AS 'Actions'
FROM test_cases tc
LEFT JOIN team_members tm ON tc.assignee_id = tm.id
LEFT JOIN test_case_statuses tcs ON tc.status_id = tcs.id
WHERE tc.project_id = $project_id 
  AND (
    -- If no suite_id given, show ALL test cases for the project
    NULLIF($suite_id, '') IS NULL
    -- If suite_id given, show only that suite's test cases
    OR tc.suite_id = CAST($suite_id AS INTEGER)
  )
ORDER BY tc.id DESC;
