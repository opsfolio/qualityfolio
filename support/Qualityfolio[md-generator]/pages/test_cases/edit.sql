-- Page to edit an existing Test Case
SELECT 'shell' AS component,
       'Edit Test Case' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
        json_array(
            json_object('title', 'Project', 'link', 'entries.sql', 'icon', 'folder'),
            json_object('title', 'Settings', 'link', 'settings.sql', 'icon', 'settings')
        ) AS menu_item;

SELECT 'redirect' AS component, 'suites.sql?project_id=' || $project_id AS link WHERE $id IS NULL;

-- Hero
SELECT 'hero' AS component,
       'Edit Test Case' AS title;

-- Back Button → Test Cases
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Test Cases' AS title,
       'test_cases.sql?project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') AS link,
       'arrow-left' AS icon,
       'outline-primary' AS color;

-- Form
SELECT 'form' AS component,
       'pages/test_cases/update.sql' AS action,
       'Update Test Case' AS validate,
       'Edit Details' AS title;

SELECT 'id' AS name, 'hidden' AS type, $id AS value;
SELECT 'project_id' AS name, 'hidden' AS type, $project_id AS value;
SELECT 'suite_id' AS name, 'hidden' AS type, $suite_id AS value;

SELECT 'Title' AS label, 'title' AS name, 'text' AS type, 12 AS width, TRUE AS required, (SELECT title FROM test_cases WHERE id = $id) AS value;

SELECT 'Description' AS label, 'description' AS name, 'textarea' AS type, 3 AS rows, 12 AS width, (SELECT description FROM test_cases WHERE id = $id) AS value;

SELECT 'Pre-conditions' AS label, 'pre_conditions' AS name, 'textarea' AS type, 3 AS rows, 12 AS width, 
    (SELECT 
        CASE 
            WHEN json_valid(pre_conditions) AND json_type(pre_conditions) = 'array' THEN 
                (SELECT group_concat(value, CHAR(10)) FROM json_each(test_cases.pre_conditions))
            ELSE pre_conditions 
        END 
     FROM test_cases WHERE id = $id) AS value;

SELECT 'Steps' AS label, 'steps' AS name, 'textarea' AS type, 8 AS rows, 12 AS width, 
    (SELECT 
        CASE 
            WHEN json_valid(steps) AND json_type(steps) = 'array' THEN 
                (SELECT group_concat(value, CHAR(10)) FROM json_each(test_cases.steps))
            ELSE steps 
        END 
     FROM test_cases WHERE id = $id) AS value;
SELECT 'Expected Result' AS label, 'expected_result' AS name, 'textarea' AS type, 3 AS rows, 12 AS width, (SELECT expected_result FROM test_cases WHERE id = $id) AS value;

SELECT 'Requirement ID' AS label, 'requirement_id' AS name, 'text' AS type, 'e.g. REGM-001' AS placeholder, 6 AS width, (SELECT requirement_id FROM test_cases WHERE id = $id) AS value;
SELECT 'Tags' AS label, 'tags' AS name, 'text' AS type, 'e.g. Login, Dropdown, Navigation' AS placeholder, 6 AS width, (SELECT tags FROM test_cases WHERE id = $id) AS value;

SELECT 'Test Type' AS label, 'test_type' AS name, 'select' AS type, 4 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id, 'selected', id = (SELECT test_type_id FROM test_cases WHERE id = $id))) FROM test_types) AS options;

SELECT 'Scenario Type' AS label, 'scenario_type' AS name, 'select' AS type, 4 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id, 'selected', id = (SELECT scenario_type_id FROM test_cases WHERE id = $id))) FROM scenario_types) AS options;

SELECT 'Execution Type' AS label, 'execution_type' AS name, 'select' AS type, 4 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id, 'selected', id = (SELECT execution_type_id FROM test_cases WHERE id = $id))) FROM execution_types) AS options;

SELECT 'Priority' AS label, 'priority' AS name, 'select' AS type, 4 AS width,
       json_array(
           json_object('label', 'High', 'value', 'High', 'selected', 'High' = (SELECT priority FROM test_cases WHERE id = $id)),
           json_object('label', 'Medium', 'value', 'Medium', 'selected', 'Medium' = (SELECT priority FROM test_cases WHERE id = $id)),
           json_object('label', 'Low', 'value', 'Low', 'selected', 'Low' = (SELECT priority FROM test_cases WHERE id = $id))
       ) AS options;

SELECT 'Assignee' AS label, 'assignee_id' AS name, 'select' AS type, 4 AS width,
       (SELECT json_group_array(json_object('label', full_name, 'value', id, 'selected', id = (SELECT assignee_id FROM test_cases WHERE id = $id))) FROM team_members) AS options;

SELECT 'Status' AS label, 'status_id' AS name, 'select' AS type, 4 AS width,
       (SELECT json_group_array(json_object('label', name, 'value', id, 'selected', id = (SELECT status_id FROM test_cases WHERE id = $id))) FROM test_case_statuses ORDER BY name) AS options;
