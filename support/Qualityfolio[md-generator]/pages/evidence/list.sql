-- Page to manage Evidence for a Test Case
SELECT 'shell' AS component,
       '' AS title,
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
             '/js/chat.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS javascript,
        json_array(
'/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
              '/css/chat.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)    
        ) AS css;

SELECT 'redirect' AS component, 'test_cases.sql?project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') AS link WHERE $test_case_id IS NULL;

-- Hero
SELECT 'hero' AS component,
       'Manage Evidence' AS title;

-- Back Button → Test Cases
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Test Cases' AS title,
       'test_cases.sql?project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') AS link,
       'arrow-left' AS icon,
       'outline-primary' AS color;

-- Context
SELECT 'text' AS component,
    '**Schema:** ' || REPLACE(pm.schema_level, '_', '-') || '  ' || CHAR(10) ||
    '**Project:** ' || p.name || 
    CASE 
        WHEN pm.schema_level = '5_level' THEN 
             '  ' || CHAR(10) || '**Plan:** ' || COALESCE(pl.name, 'N/A')
        ELSE ''
    END ||
    CASE 
        WHEN pm.schema_level IN ('4_level', '5_level') THEN 
             '  ' || CHAR(10) || '**Suite:** ' || COALESCE(s.name, 'N/A')
        ELSE ''
    END ||
    '  ' || CHAR(10) || '**Test Case:** ' || tc.title
    AS contents_md
FROM test_cases tc
JOIN projects p ON tc.project_id = p.id
LEFT JOIN project_metadata pm ON p.id = pm.project_id
LEFT JOIN suites s ON tc.suite_id = s.id
LEFT JOIN plans pl ON s.plan_id = pl.id
WHERE tc.id = $test_case_id;

-- Create New Evidence Form
SELECT 'form' AS component,
       'pages/evidence/save.sql' AS action,
       'Add Evidence' AS validate,
       'Add New Evidence' AS title;

SELECT 'test_case_id' AS name, 'hidden' AS type, $test_case_id AS value;
SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;
SELECT 'suite_id' AS name, 'hidden' AS type, $suite_id AS value;

SELECT 'Title' AS label, 'title' AS name, 'text' AS type, 'Evidence Title' AS placeholder, 12 AS width, TRUE AS required;
SELECT 'Content' AS label, 'content' AS name, 'textarea' AS type, 'Enter evidence details or description...' AS placeholder, 4 AS rows, 12 AS width, TRUE AS required;
SELECT 'Attachment URL' AS label, 'attachments' AS name, 'text' AS type, 'http://example.com/image.png' AS placeholder, 12 AS width;

-- Divider
SELECT 'divider' AS component;

-- Evidence List
SELECT 'table' AS component,
       TRUE AS sort,
       'Evidence' AS markdown,
       'Actions' AS markdown;

SELECT 
    title,
    content AS 'Description',
    attachments AS 'Attachment',
    '[✏️](edit_evidence.sql?id=' || id || '&test_case_id=' || $test_case_id || '&project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') || ') &nbsp; [🗑️](delete_evidence.sql?id=' || id || '&test_case_id=' || $test_case_id || '&project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') || ')' AS 'Actions'
FROM evidence
WHERE test_case_id = $test_case_id;
