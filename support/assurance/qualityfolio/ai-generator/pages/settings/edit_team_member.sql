-- edit_team_member.sql
-- Displays a form to edit an existing team member.
-- URL param: $id — the team member ID to edit.

-- Resolve the safe integer ID
SET _id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);

-- Guard: redirect if ID is invalid or record not found
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Error:+Invalid+member+ID' AS link
WHERE $_id = 0 OR NOT EXISTS (SELECT 1 FROM team_members WHERE id = $_id);

-- Shell
SELECT 'shell' AS component,
       'Edit Team Member' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       TRUE AS fluid,
       json_array(
           json_object('title', 'Generator',       'link', 'entries.sql',    'icon', 'pencil'),
           json_object('title', 'Markdown Editor', 'link', 'md_editor.sql',  'icon', 'file-text'),
           json_object('title', 'Settings',        'link', 'settings.sql',   'icon', 'settings')
       ) AS menu_item,
       json_array(
           '/css/theme.css?v='  || CAST(STRFTIME('%s', 'now') AS TEXT),
           '/css/chat.css?v='   || CAST(STRFTIME('%s', 'now') AS TEXT)
       ) AS css;

SELECT 'title' AS component, 2 AS level, 'Edit Team Member' AS contents;

-- Back button
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Settings' AS title,
       '/settings.sql?tab=team_members' AS link,
       'arrow-left' AS icon,
       'outline-secondary' AS color;

-- Edit form — action points to update handler
SELECT 'form' AS component,
       'update_team_member.sql' AS action,
       'POST' AS method,
       'Save Changes' AS validate,
       'save' AS validate_icon,
       'Edit Team Member' AS title;

-- Hidden field carries the ID to the update handler
SELECT 'edit_id' AS name,
       'hidden'  AS type,
       $_id      AS value;

-- Full Name field pre-populated from the database
SELECT 'full_name'   AS name,
       'Full Name'   AS label,
       'text'        AS type,
       full_name     AS value,
       TRUE          AS required,
       'e.g. Jane Smith' AS placeholder
FROM team_members WHERE id = $_id;

-- Designation field pre-populated
SELECT 'designation'  AS name,
       'Designation'  AS label,
       'text'         AS type,
       COALESCE(designation, '') AS value,
       'e.g. QA Engineer' AS placeholder
FROM team_members WHERE id = $_id;