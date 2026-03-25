-- Page to manage Plans for a Project
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

SELECT 'redirect' AS component, 'entries.sql' AS link WHERE $project_id IS NULL;

-- Hero
SELECT 'hero' AS component,
       'Manage Plans' AS title;

-- Back Button → Projects
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Projects' AS title, 'entries.sql' AS link, 'arrow-left' AS icon, 'outline-primary' AS color;

-- Project Details
SELECT 'text' AS component,
       '**Schema:** ' || (SELECT REPLACE(schema_level, '_', '-') FROM project_metadata WHERE project_id = $project_id) || '  ' || CHAR(10) ||
       '**Project:** ' || (SELECT name FROM projects WHERE id = $project_id) AS contents_md;

-- Add New Plan Form
SELECT 'form' AS component,
       'pages/plans/save.sql' AS action,
       'Add Plan' AS validate,
       'Create New Plan' AS title;

SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;
-- Requirement Details for AI Scope Generation
SELECT 'requirement_text' AS name, 'hidden' AS type, (SELECT requirement_text FROM project_metadata WHERE project_id = $project_id) AS value;

SELECT 'Plan ID' AS label, 'plan_id' AS name, 'text' AS type, 'PLAN-001' AS placeholder, 6 AS width, TRUE AS required;
SELECT 'Plan Name' AS label, 'plan_name' AS name, 'text' AS type, 'Enter Plan Name' AS placeholder, 6 AS width, TRUE AS required;

SELECT 'html' AS component, 
  '<div class="col-6"><div class="qfg-field"><label>Plan Date (MM-DD-YYYY)</label>
     <div style="position:relative;display:flex;align-items:center;">
       <input type="text" id="plan_date-display" class="qf-date" placeholder="MM-DD-YYYY" value="' || STRFTIME('%m-%d-%Y', 'now') || '" style="width:100%;cursor:pointer;padding-right:28px;" />
       <input type="hidden" name="plan_date" id="plan_date" value="' || STRFTIME('%Y-%m-%d', 'now') || '" />
       <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
     </div>
   </div></div>' AS html;
SELECT 'Plan Created By' AS label, 'plan_created_by' AS name, 'select' AS type, '-- Select Creator --' AS placeholder, 6 AS width, (SELECT json_group_array(json_object('label', full_name, 'value', id)) FROM team_members) AS options;

SELECT 'Plan Scope' AS label,
       'plan_scope' AS name,
       'textarea' AS type,
       'Enter Plan Scope or generate with AI...' AS placeholder,
       12 AS width,
       4 AS rows;

SELECT 'divider' AS component;
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown;

SELECT 
    p.name AS 'Plan Name',
    p.plan_date AS 'Date',
    tm.full_name AS 'Creator',
    -- Placeholder Actions
    '[Suites](suites.sql?project_id=' || $project_id || '&plan_id=' || p.id || ') | [✏️](edit_plan.sql?id=' || p.id || '&project_id=' || $project_id || ')' AS 'Actions'
FROM plans p
LEFT JOIN team_members tm ON p.created_by_id = tm.id
WHERE p.project_id = $project_id
ORDER BY p.plan_date DESC;

-- Note: edit_plan.sql doesn't exist yet, but link is ready.
-- We could also add a "Create New Plan" button/form here later.
