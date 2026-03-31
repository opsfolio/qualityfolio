-- Edit test type page
SELECT 'hero' AS component,
       'Edit Test Type' AS title,
       'Update test type information' AS description;

-- Back Button
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Settings' AS title, '/settings.sql?tab=test_types' AS link, 'arrow-left' AS icon, 'outline-primary' AS color;

-- Edit form
SELECT 'form' AS component,
       'update_test_type.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Edit Test Type' AS title;

-- Hidden field for ID
SELECT 'hidden' AS type,
       'edit_id' AS name,
       $id AS value;

SELECT 'Test Type Name' AS label,
       'name' AS name,
       'text' AS type,
       name AS value,
       TRUE AS required
FROM test_types WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);

SELECT 'Description' AS label,
       'description' AS name,
       'textarea' AS type,
       description AS value
FROM test_types WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);
