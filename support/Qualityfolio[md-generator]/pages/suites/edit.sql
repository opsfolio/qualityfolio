-- Page to edit an existing Suite
SELECT 'shell' AS component,
       'Edit Suite' AS title,
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
             '/js/chat.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
              '/js/pikaday.js',
             '/js/md-date-picker.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS javascript,
        json_array(
'/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
              '/css/chat.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
              '/css/pikaday.css'
        ) AS css;

SELECT 'redirect' AS component, 'pages/suites/list.sql' AS link WHERE $id IS NULL;

-- Hero
SELECT 'hero' AS component,
       'Edit Suite' AS title,
       'Update suite details.' AS description;

-- Back Button → Suites
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Suites' AS title,
       'suites.sql?project_id=' || $project_id || CASE WHEN $plan_id IS NOT NULL THEN '&plan_id=' || $plan_id ELSE '' END AS link,
       'arrow-left' AS icon,
       'outline-primary' AS color;

-- Edit Form
SELECT 'form' AS component,
       'pages/suites/update.sql' AS action,
       'Update Suite' AS validate,
       'Edit Suite Details' AS title;

-- Hidden Fields
SELECT 'suite_id' AS name, 'hidden' AS type, $id AS value;
SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;
SELECT 'redirect_url' AS name, 'hidden' AS type, 
       'suites.sql?project_id=' || $project_id || '&plan_id=' || COALESCE((SELECT CAST(plan_id AS TEXT) FROM suites WHERE id = $id), '') 
       AS value;

-- Fields
SELECT 'Suite Name' AS label, 'suite_name' AS name, 'text' AS type, 6 AS width, TRUE AS required, (SELECT name FROM suites WHERE id = $id) AS value;
SELECT 'Suite ID' AS label, 'external_id' AS name, 'text' AS type, 6 AS width, TRUE AS required, (SELECT external_id FROM suites WHERE id = $id) AS value;
SELECT 'Scope' AS label, 'scope' AS name, 'textarea' AS type, 3 AS rows, 12 AS width, (SELECT scope FROM suites WHERE id = $id) AS value;

SELECT 'html' AS component, 
  '<div class="col-6"><div class="qfg-field"><label>Suite Date (MM-DD-YYYY)</label>
     <div style="position:relative;display:flex;align-items:center;">
       <input type="text" id="editSuiteDate-display" class="qf-date" placeholder="MM-DD-YYYY" value="' || COALESCE((SELECT STRFTIME('%m-%d-%Y', suite_date) FROM suites WHERE id = $id), STRFTIME('%m-%d-%Y', 'now')) || '" style="width:100%;cursor:pointer;padding-right:28px;" />
       <input type="hidden" name="suite_date" id="editSuiteDate" value="' || COALESCE((SELECT STRFTIME('%Y-%m-%d', suite_date) FROM suites WHERE id = $id), STRFTIME('%Y-%m-%d', 'now')) || '" />
       <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
     </div>
   </div></div>' AS html;
SELECT 'Suite Created By' AS label, 'suite_created_by' AS name, 'select' AS type, 6 AS width, (SELECT json_group_array(json_object('label', full_name, 'value', id, 'selected', id = (SELECT created_by_id FROM suites WHERE id = $id))) FROM team_members) AS options;

-- Note: We generally don't allow moving suites between plans here for simplicity, but could add it.
