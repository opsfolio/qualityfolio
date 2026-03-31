-- Delete category handler
DELETE FROM categories WHERE id = $id;

-- Redirect back to settings
SELECT 'redirect' AS component,
       'settings.sql?success=Category deleted successfully' AS link;
