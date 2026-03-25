-- Delete team member handler with confirmation

-- If no confirmation yet, show warning page
SELECT 'hero' AS component,
       'Delete Team Member' AS title,
       'Are you sure you want to delete this team member?' AS description
WHERE $confirm IS NULL;

-- Show team member details
SELECT 'card' AS component,
       'Team Member Details' AS title
WHERE $confirm IS NULL;

SELECT
    'Name: **' || full_name || '**  
Designation: **' || COALESCE(designation, 'N/A') || '**' AS description_md
FROM team_members
WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER) AND $confirm IS NULL;

-- Warning alert
SELECT 'alert' AS component,
       'warning' AS color,
       'Warning!' AS title,
       'This action cannot be undone.' AS description
WHERE $confirm IS NULL;

-- Confirmation buttons
SELECT 'button' AS component
WHERE $confirm IS NULL;

SELECT 'Cancel' AS title,
       '/settings.sql?tab=team_members' AS link,
       'gray' AS color
WHERE $confirm IS NULL;

SELECT 'Delete' AS title,
       '/pages/settings/delete_team_member.sql?id=' || REPLACE(COALESCE($id, '0'), ',', '') || '&confirm=yes' AS link,
       'red' AS color
WHERE $confirm IS NULL;

-- Perform delete if confirmed
DELETE FROM team_members
WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER) AND $confirm = 'yes';

-- Redirect back to settings after delete
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Team+member+deleted+successfully' AS link
WHERE $confirm = 'yes';