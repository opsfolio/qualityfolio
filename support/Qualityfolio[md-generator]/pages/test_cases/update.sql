-- Save edited Test Case
UPDATE test_cases
SET 
    title = :title,
    description = :description,
    pre_conditions = :pre_conditions,
    steps = :steps,
    expected_result = :expected_result,
    requirement_id = NULLIF(:requirement_id, ''),
    tags = NULLIF(:tags, ''),
    test_type_id = :test_type,
    scenario_type_id = :scenario_type,
    execution_type_id = :execution_type,
    priority = :priority,
    assignee_id = NULLIF(:assignee_id, ''),
    status_id = NULLIF(:status_id, '')
WHERE id = :id;

SELECT 'redirect' AS component, 
       'test_cases.sql?project_id=' || :project_id || '&suite_id=' || COALESCE(:suite_id, '') AS link;
