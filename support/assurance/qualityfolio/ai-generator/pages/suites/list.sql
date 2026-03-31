-- Page to manage Suites for a Project

-- REDIRECTS FIRST (must come before any component output)
SELECT 'redirect' AS component, 'entries.sql' AS link WHERE $project_id IS NULL;

-- Level 5: Enforce Plan Selection (Redirect to Plans if no plan_id)
SELECT 'redirect' AS component, 'plans.sql?project_id=' || $project_id AS link
WHERE (SELECT schema_level FROM project_metadata WHERE project_id = $project_id) = '5_level' AND $plan_id IS NULL;

SELECT 'shell' AS component,
       'Qualityfolio AI' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
        json_array(
            json_object('title', 'Project', 'link', 'entries.sql', 'icon', 'folder'),
            json_object('title', 'Settings', 'link', 'settings.sql', 'icon', 'settings')
        ) AS menu_item,
        json_array(
            '/js/layout.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/js/refine.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/js/chat.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/js/pikaday.js',
            '/js/md-date-picker.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS javascript,
        json_array(
            '/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/css/chat.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
            '/css/pikaday.css'
        ) AS css;

-- Hero
SELECT 'hero' AS component,
       'Manage Suites' AS title;

-- Back Button (Level 5 → Plans, Level 4 → Projects)
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back' AS title,
       CASE 
           WHEN (SELECT schema_level FROM project_metadata WHERE project_id = $project_id) = '5_level'
           THEN 'plans.sql?project_id=' || $project_id
           ELSE 'entries.sql'
       END AS link,
       'arrow-left' AS icon,
       'outline-primary' AS color;

-- Project Details
SELECT 'text' AS component,
       '**Schema:** ' || (SELECT REPLACE(schema_level, '_', '-') FROM project_metadata WHERE project_id = $project_id) || '  ' || CHAR(10) ||
       '**Project:** ' || (SELECT name FROM projects WHERE id = $project_id) ||
       CASE 
           WHEN $plan_id IS NOT NULL THEN 
               '  ' || CHAR(10) || '**Plan:** ' || (SELECT name FROM plans WHERE id = $plan_id)
           ELSE ''
       END AS contents_md;



-- Create New Suite Form
SELECT 'form' AS component,
       'pages/suites/save.sql' AS action,
       'Add Suite' AS validate,
       'Create New Suite' AS title;

SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;

-- Logic for Plan Association (Level 5 Requirement)
-- Case A: Plan ID is already known (navigated from Plans page) -> Hidden Field
SELECT 'plan_id' AS name, 'hidden' AS type, $plan_id AS value
WHERE $plan_id IS NOT NULL;

-- Case B: Level 5 Project but Plan NOT known (navigated from Project list) -> Dropdown
SELECT 'Select Parent Plan' AS label, 
       'plan_id' AS name, 
       'select' AS type,
       '-- Select Plan --' AS placeholder,
       TRUE AS required, 
       12 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id)) FROM plans WHERE project_id = $project_id) AS options
WHERE (SELECT schema_level FROM project_metadata WHERE project_id = $project_id) = '5_level' 
  AND $plan_id IS NULL;

SELECT 'Suite Name' AS label, 'suite_name' AS name, 'text' AS type, 'Generated Suite' AS placeholder, 6 AS width, TRUE AS required;
SELECT 'Suite ID' AS label, 'suite_id' AS name, 'text' AS type, 'SUITE-001' AS placeholder, 6 AS width, TRUE AS required;
SELECT 'Scope' AS label, 'scope' AS name, 'textarea' AS type, 'Describe the scope of this suite...' AS placeholder, 3 AS rows, 12 AS width;

SELECT 'html' AS component, 
  '<div class="col-6"><div class="qfg-field"><label>Suite Date (MM-DD-YYYY)</label>
     <div style="position:relative;display:flex;align-items:center;">
       <input type="text" id="suite_date-display" class="qf-date" placeholder="MM-DD-YYYY" value="' || STRFTIME('%m-%d-%Y', 'now') || '" style="width:100%;cursor:pointer;padding-right:28px;" />
       <input type="hidden" name="suite_date" id="suite_date" value="' || STRFTIME('%Y-%m-%d', 'now') || '" />
       <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
     </div>
   </div></div>' AS html;
SELECT 'Suite Created By' AS label, 'suite_created_by' AS name, 'select' AS type, '-- Select Creator --' AS placeholder, 6 AS width, (SELECT json_group_array(json_object('label', full_name, 'value', id)) FROM team_members) AS options;
SELECT 'Test Cases' AS label, 'test_cases_count' AS name, 'number' AS type, (SELECT COALESCE(test_cases_count, 5) FROM project_metadata WHERE project_id = $project_id) AS value, 12 AS width, TRUE AS required;

SELECT 'divider' AS component;
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown;

SELECT 
    s.name AS 'Suite Name',
    COALESCE(p.name, '-') AS 'Plan Name', -- Show Plan even if hidden? Or dynamically?
    s.suite_date AS 'Date',
    tm.full_name AS 'Creator',
    -- Placeholder Actions
    '[Test Cases](test_cases.sql?project_id=' || $project_id || '&suite_id=' || s.id || ') | [✏️](edit_suite.sql?id=' || s.id || '&project_id=' || $project_id || ')' AS 'Actions'
FROM suites s
LEFT JOIN plans p ON s.plan_id = p.id
LEFT JOIN team_members tm ON s.created_by_id = tm.id
WHERE s.project_id = $project_id
  AND ($plan_id IS NULL OR $plan_id = '' OR s.plan_id = $plan_id)
ORDER BY s.suite_date DESC;

-- Note: In Level 4, Plan Name will be NULL or '-' which is fine.
-- In Level 5, it shows the associated Plan.
