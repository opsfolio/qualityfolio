-- delete_team_member.sql
-- Handles team member deletion with a confirmation step.
-- First visit  (GET ?id=N):         shows confirmation page.
-- Second visit (GET ?id=N&confirm=yes): performs the delete and redirects.

SET _id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);

-- Guard: redirect if ID is invalid
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Error:+Invalid+member+ID' AS link
WHERE $_id = 0;

-- ── STEP 2: perform delete when confirmed ────────────────────────────────────
DELETE FROM team_members
WHERE id = $_id AND $confirm = 'yes';

SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Team+member+deleted+successfully' AS link
WHERE $confirm = 'yes';

-- ── STEP 1: confirmation page (only shown when confirm is not yet set) ────────

-- Shell (only render for confirmation page, not for the delete-and-redirect path)
SELECT 'shell' AS component,
       'Delete Team Member' AS title,
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
       ) AS css
WHERE $confirm IS NULL;

SELECT 'title' AS component, 2 AS level, 'Delete Team Member' AS contents
WHERE $confirm IS NULL;

-- Show the member's details in a card so the user knows what they're deleting
SELECT 'card' AS component, 1 AS columns
WHERE $confirm IS NULL;

SELECT
    full_name AS title,
    'Designation: ' || COALESCE(designation, 'N/A') AS description,
    'user' AS icon,
    'azure' AS color
FROM team_members
WHERE id = $_id AND $confirm IS NULL;

-- Warning alert
SELECT 'alert' AS component,
       'danger' AS color,
       'alert-triangle' AS icon,
       'This action cannot be undone.' AS title,
       'The team member will be permanently deleted from the system.' AS description
WHERE $confirm IS NULL;

-- Confirm / Cancel buttons
SELECT 'button' AS component
WHERE $confirm IS NULL;

SELECT 'Cancel' AS title,
       '/settings.sql?tab=team_members' AS link,
       'x' AS icon,
       'secondary' AS color
WHERE $confirm IS NULL;

SELECT 'Yes, Delete' AS title,
       '/pages/settings/delete_team_member.sql?id=' || $_id || '&confirm=yes' AS link,
       'trash' AS icon,
       'danger' AS color
WHERE $confirm IS NULL;