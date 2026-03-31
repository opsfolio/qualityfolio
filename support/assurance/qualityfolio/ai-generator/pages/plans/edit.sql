-- Page to edit an existing Plan
SELECT 'shell' AS component,
       'Edit Plan' AS title,
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

SELECT 'redirect' AS component, 'pages/plans/list.sql' AS link WHERE $id IS NULL;

-- Hero
SELECT 'hero' AS component,
       'Edit Plan' AS title,
       'Update plan details.' AS description;

-- Back Button → Plans
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Plans' AS title,
       'plans.sql?project_id=' || $project_id AS link,
       'arrow-left' AS icon,
       'outline-primary' AS color;

-- Edit Form
SELECT 'form' AS component,
       'pages/plans/update.sql' AS action,
       'Update Plan' AS validate,
       'Edit Plan Details' AS title;

-- Hidden Fields
SELECT 'plan_id' AS name, 'hidden' AS type, $id AS value;
SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;
SELECT 'redirect_url' AS name, 'hidden' AS type, 'plans.sql?project_id=' || $project_id AS value;
-- Requirement Details for AI Scope Generation
SELECT 'requirement_text' AS name, 'hidden' AS type, (SELECT requirement_text FROM project_metadata WHERE project_id = $project_id) AS value;

-- Fields
SELECT 'Plan Name' AS label, 'plan_name' AS name, 'text' AS type, 6 AS width, TRUE AS required, (SELECT name FROM plans WHERE id = $id) AS value;
SELECT 'Plan ID' AS label, 'external_id' AS name, 'text' AS type, 6 AS width, TRUE AS required, (SELECT external_id FROM plans WHERE id = $id) AS value;

SELECT 'html' AS component, 
  '<div class="col-6"><div class="qfg-field"><label>Plan Date (MM-DD-YYYY)</label>
     <div style="position:relative;display:flex;align-items:center;">
       <input type="text" id="editPlanDate-display" class="qf-date" placeholder="MM-DD-YYYY" value="' || COALESCE((SELECT STRFTIME('%m-%d-%Y', plan_date) FROM plans WHERE id = $id), STRFTIME('%m-%d-%Y', 'now')) || '" style="width:100%;cursor:pointer;padding-right:28px;" />
       <input type="hidden" name="plan_date" id="editPlanDate" value="' || COALESCE((SELECT STRFTIME('%Y-%m-%d', plan_date) FROM plans WHERE id = $id), STRFTIME('%Y-%m-%d', 'now')) || '" />
       <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
     </div>
   </div></div>' AS html;
SELECT 'Plan Created By' AS label, 'plan_created_by' AS name, 'select' AS type, 6 AS width, (SELECT json_group_array(json_object('label', full_name, 'value', id, 'selected', id = (SELECT created_by_id FROM plans WHERE id = $id))) FROM team_members) AS options;
SELECT 'Plan Scope' AS label, 'plan_scope' AS name, 'textarea' AS type, 12 AS width, 4 AS rows, (SELECT scope FROM plans WHERE id = $id) AS value;
