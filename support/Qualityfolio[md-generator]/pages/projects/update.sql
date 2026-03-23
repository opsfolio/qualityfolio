-- Logic to update existing project details

-- 0. Ensure request is valid
SELECT 'redirect' AS component, 'entries.sql' AS link WHERE :project_id IS NULL;

-- 1. Update Project Table
UPDATE projects
SET name = :project_name
WHERE id = :project_id;

-- 2. Update Project Metadata
UPDATE project_metadata
SET 
    schema_level = :schema_level,
    requirement_text = :requirement_text,
    requirement_id = :requirement_id,
    test_cases_count = :test_cases_count,
    default_creator_id = :default_creator,
    default_assignee_id = :default_assignee,
    test_type_id = :test_type,
    cycle = :cycle,
    cycle_date = :cycle_date
WHERE project_id = :project_id AND (SELECT COUNT(*) FROM project_metadata WHERE project_id = :project_id) > 0;

-- 3. Insert if missing (Robustness)
INSERT INTO project_metadata (
    project_id, 
    schema_level, 
    requirement_text, 
    requirement_id, 
    test_cases_count, 
    default_creator_id, 
    default_assignee_id,
    test_type_id, 
    cycle, 
    cycle_date
)
SELECT 
    :project_id, 
    :schema_level, 
    :requirement_text, 
    :requirement_id, 
    :test_cases_count, 
    :default_creator, 
    :default_assignee,
    :test_type, 
    :cycle, 
    :cycle_date
WHERE (SELECT COUNT(*) FROM project_metadata WHERE project_id = :project_id) = 0;

-- 4. Redirect
SELECT 'redirect' AS component, 
       COALESCE(:redirect_url, 'entries.sql') AS link;
