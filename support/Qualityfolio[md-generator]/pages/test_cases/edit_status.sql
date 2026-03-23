-- Edit test case status page
SELECT 'hero' AS component,
       'Edit Test Case Status' AS title,
       'Update test case status information' AS description;

-- Back Button
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Settings' AS title, '/settings.sql?tab=test_case_statuses' AS link, 'arrow-left' AS icon, 'outline-primary' AS color;

-- Edit form
SELECT 'form' AS component,
       'update_status.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Edit Test Case Status' AS title;

-- Hidden field for ID
SELECT 'hidden' AS type,
       'edit_id' AS name,
       $id AS value;

SELECT 'Status Name' AS label,
       'name' AS name,
       'text' AS type,
       name AS value,
       TRUE AS required
FROM test_case_statuses WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);
