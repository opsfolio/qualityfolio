-- Edit tag page
SELECT 'hero' AS component,
       'Edit Tag' AS title,
       'Update tag information' AS description;

-- Back Button
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Settings' AS title, '/settings.sql?tab=tags' AS link, 'arrow-left' AS icon, 'outline-primary' AS color;

-- Edit form
SELECT 'form' AS component,
       'update_tag.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Edit Tag' AS title;

-- Hidden field for ID
SELECT 'hidden' AS type,
       'edit_id' AS name,
       $id AS value;

SELECT 'Tag Name' AS label,
       'name' AS name,
       'text' AS type,
       name AS value,
       TRUE AS required
FROM tags WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);
