-- Action to delete project and cascade
-- 1. Metadata has cascading delete on FK
-- 2. Plans, Suites, Test Cases should also cascade if FKs are set correctly.
-- We will enforce explicit deletion just in case or rely on ON DELETE CASCADE if defined in schema.
-- According to schema, most have user_id, project_id. 
-- We should delete children explicitly first if cascading is not guaranteed.

DELETE FROM evidence WHERE test_case_id IN (SELECT id FROM test_cases WHERE project_id = :id);
DELETE FROM test_cases WHERE project_id = :id;
DELETE FROM suites WHERE project_id = :id;
DELETE FROM plans WHERE project_id = :id;
DELETE FROM project_metadata WHERE project_id = :id;
DELETE FROM projects WHERE id = :id;

SELECT 'redirect' AS component, 'entries.sql' AS link;
