-- Delete tag handler with confirmation

-- If no confirmation yet, show warning page
SELECT 'hero' AS component,
       'Delete Tag' AS title,
       'Are you sure you want to delete this tag?' AS description
WHERE $confirm IS NULL;

-- Show tag details
SELECT 'card' AS component,
       'Tag Details' AS title
WHERE $confirm IS NULL;

SELECT 
    'Name: **' || name || '**' AS description_md
FROM tags 
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
       '/settings.sql?tab=tags' AS link,
       'gray' AS color
WHERE $confirm IS NULL;

SELECT 'Delete' AS title,
       '/pages/settings/delete_tag.sql?id=' || REPLACE(COALESCE($id, '0'), ',', '') || '&confirm=yes' AS link,
       'red' AS color
WHERE $confirm IS NULL;

-- Perform delete if confirmed
DELETE FROM tags 
WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER) AND $confirm = 'yes';

-- Redirect back to settings after delete
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&success=Tag+deleted+successfully' AS link
WHERE $confirm = 'yes';
