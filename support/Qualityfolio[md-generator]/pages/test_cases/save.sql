-- Save new Test Case
INSERT INTO test_cases (project_id, suite_id, title, description, pre_conditions, steps, expected_result, requirement_id, tags, test_type_id, scenario_type_id, execution_type_id, priority, assignee_id, status_id)
VALUES (
    :project_id,
    NULLIF(:suite_id, ''),
    :title,
    :description,
    :pre_conditions,
    :steps,
    :expected_result,
    NULLIF(:requirement_id, ''),
    NULLIF(:tags, ''),
    :test_type,
    :scenario_type,
    :execution_type,
    :priority,
    NULLIF(:assignee_id, ''),
    COALESCE(NULLIF(:status_id, ''), (SELECT id FROM test_case_statuses WHERE name = 'Open' LIMIT 1))
);

-- Create default Evidence record
-- Create default Evidence record (Auto-generated)
INSERT INTO evidence (test_case_id, title, content)
VALUES (
    LAST_INSERT_ROWID(),
    'Evidence for ' || :title,
    'Auto-generated evidence placeholder. Please edit to add specific details.'
);

SELECT 'redirect' AS component, 
       'test_cases.sql?project_id=' || :project_id || '&suite_id=' || COALESCE(:suite_id, '') AS link;
