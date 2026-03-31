-- Edit execution type page
SELECT 'hero' AS component,
       'Edit Execution Type' AS title,
       'Update execution type information' AS description;

-- Back Button
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Settings' AS title, '/settings.sql?tab=execution_types' AS link, 'arrow-left' AS icon, 'outline-primary' AS color;

-- Edit form
SELECT 'form' AS component,
       'update_execution_type.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Edit Execution Type' AS title;

-- Hidden field for ID
SELECT 'hidden' AS type,
       'edit_id' AS name,
       $id AS value;

SELECT 'Execution Type Name' AS label,
       'name' AS name,
       'text' AS type,
       name AS value,
       TRUE AS required
FROM execution_types WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);
