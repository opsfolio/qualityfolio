-- Action to update an existing Suite
UPDATE suites
SET 
    name = :suite_name,
    external_id = :external_id,
    suite_date = :suite_date,
    created_by_id = :suite_created_by,
    scope = :scope
WHERE id = :suite_id;

SELECT 'redirect' AS component, 
       COALESCE(:redirect_url, 'suites.sql?project_id=' || :project_id) AS link;
