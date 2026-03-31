-- Page to edit an existing Evidence
SELECT 'shell' AS component,
       'Edit Evidence' AS title,
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

SELECT 'redirect' AS component, 'evidence.sql?test_case_id=' || $test_case_id || '&project_id=' || $project_id || '&suite_id=' || $suite_id AS link WHERE $id IS NULL;

-- Hero
SELECT 'hero' AS component,
       'Edit Evidence' AS title;

-- Back Button → Evidence
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Evidence' AS title,
       'evidence.sql?test_case_id=' || $test_case_id || '&project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') AS link,
       'arrow-left' AS icon,
       'outline-primary' AS color;

-- Form
SELECT 'form' AS component,
       'pages/evidence/update.sql' AS action,
       'Update Evidence' AS validate,
       'Edit Details' AS title;

SELECT 'id' AS name, 'hidden' AS type, $id AS value;
SELECT 'test_case_id' AS name, 'hidden' AS type, $test_case_id AS value;
SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;
SELECT 'suite_id' AS name, 'hidden' AS type, $suite_id AS value;

SELECT 'Title' AS label, 'title' AS name, 'text' AS type, 12 AS width, TRUE AS required, (SELECT title FROM evidence WHERE id = $id) AS value;
SELECT 'Content' AS label, 'content' AS name, 'textarea' AS type, 4 AS rows, 12 AS width, TRUE AS required, (SELECT content FROM evidence WHERE id = $id) AS value;

SELECT 'html' AS component, 
  '<div class="qfg-field"><label>Date (MM-DD-YYYY)</label>
     <div style="position:relative;display:flex;align-items:center;">
       <input type="text" id="ev-date-display" class="qf-date" placeholder="MM-DD-YYYY" value="' || COALESCE((SELECT STRFTIME('%m-%d-%Y', created_at) FROM evidence WHERE id = $id), STRFTIME('%m-%d-%Y', 'now')) || '" style="width:100%;cursor:pointer;padding-right:28px;" />
       <input type="hidden" name="cycle_date" id="ev-date" value="' || COALESCE((SELECT STRFTIME('%Y-%m-%d', created_at) FROM evidence WHERE id = $id), STRFTIME('%Y-%m-%d', 'now')) || '" />
       <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
     </div>
   </div>' AS html;

SELECT 'Attachment URL' AS label, 'attachments' AS name, 'text' AS type, 12 AS width, (SELECT attachments FROM evidence WHERE id = $id) AS value;
