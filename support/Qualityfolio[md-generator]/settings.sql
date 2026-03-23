-- Settings page for managing master data
SELECT 'shell' AS component,
       '' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
       json_array(
           json_object('title', 'Project', 'link', 'entries.sql', 'icon', 'folder'),
           json_object('title', 'Settings', 'link', 'settings.sql', 'icon', 'settings')
       ) AS menu_item,
        json_array(
             '/js/layout.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/js/chat.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS javascript,
        json_array(
'/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
              '/css/chat.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)    
        ) AS css;

-- Run migrations
-- SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/002_create_master_data.sql') AS properties;
-- SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/003_create_team_members.sql') AS properties;
-- SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/004_create_test_types.sql') AS properties;
-- SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/005_create_scenario_types.sql') AS properties;
-- SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/006_create_execution_types.sql') AS properties;
-- SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/027_create_test_case_statuses.sql') AS properties;
-- SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/033_create_app_settings.sql') AS properties;

-- Display success message if present
SELECT 'alert' AS component,
       'success' AS color,
       'Success!' AS title,
       $success AS description
WHERE $success IS NOT NULL;

-- Page header
SELECT 'hero' AS component,
       'Settings' AS title,
       'Manage master data for your application' AS description;

-- Back Button → Projects
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Projects' AS title, 'entries.sql' AS link, 'arrow-left' AS icon, 'outline-primary' AS color;



-- Tabs
SELECT 'tab' AS component,
       TRUE AS center;
SELECT 'Team Members' AS title, 'team_members' AS value, CASE WHEN $tab = 'team_members' OR $tab IS NULL THEN TRUE ELSE FALSE END AS active, 'settings.sql?tab=team_members' AS link;
SELECT 'Test Types' AS title, 'test_types' AS value, CASE WHEN $tab = 'test_types' THEN TRUE ELSE FALSE END AS active, 'settings.sql?tab=test_types' AS link;
SELECT 'Scenario Types' AS title, 'scenario_types' AS value, CASE WHEN $tab = 'scenario_types' THEN TRUE ELSE FALSE END AS active, 'settings.sql?tab=scenario_types' AS link;
SELECT 'Execution Types' AS title, 'execution_types' AS value, CASE WHEN $tab = 'execution_types' THEN TRUE ELSE FALSE END AS active, 'settings.sql?tab=execution_types' AS link;
SELECT 'Tags' AS title, 'tags' AS value, CASE WHEN $tab = 'tags' THEN TRUE ELSE FALSE END AS active, 'settings.sql?tab=tags' AS link;
SELECT 'Test Case Status' AS title, 'test_case_statuses' AS value, CASE WHEN $tab = 'test_case_statuses' THEN TRUE ELSE FALSE END AS active, 'settings.sql?tab=test_case_statuses' AS link;
SELECT 'ID Formats' AS title, 'id_formats' AS value, CASE WHEN $tab = 'id_formats' THEN TRUE ELSE FALSE END AS active, 'settings.sql?tab=id_formats' AS link;

-- 
-- TEAM MEMBERS TAB CONTENT
--
SELECT 'card' AS component,
       'Team Members' AS title,
       'Configure the team members available for test case assignment' AS description
WHERE $tab = 'team_members' OR $tab IS NULL;

-- Add new team member form
SELECT 'form' AS component,
       '/pages/settings/save_team_member.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Add New Team Member' AS title
WHERE $tab = 'team_members' OR $tab IS NULL;

SELECT 'Full Name' AS label,
       'full_name' AS name,
       'text' AS type,
       'Full Name' AS placeholder,
       TRUE AS required
WHERE $tab = 'team_members' OR $tab IS NULL;

SELECT 'Designation (e.g., QA Engineer)' AS label,
       'designation' AS name,
       'text' AS type,
       'Designation (e.g., QA Engineer)' AS placeholder
WHERE $tab = 'team_members' OR $tab IS NULL;

-- Display team members as table
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown
WHERE $tab = 'team_members' OR $tab IS NULL;

SELECT 
    id AS 'ID',
    full_name AS 'Full Name',
    designation AS 'Designation',
    datetime(created_at, 'localtime') AS 'Created',
    '[✏️](/pages/settings/edit_team_member.sql?id=' || id || ') &nbsp; [🗑️](/pages/settings/delete_team_member.sql?id=' || id || ')' AS 'Actions'
FROM team_members
WHERE $tab = 'team_members' OR $tab IS NULL
ORDER BY full_name;

-- 
-- TEST TYPES TAB CONTENT
--
SELECT 'card' AS component,
       'Test Types' AS title,
       'Configure the types of tests available' AS description
WHERE $tab = 'test_types';

-- Add new test type form
SELECT 'form' AS component,
       '/pages/settings/save_test_type.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Add New Test Type' AS title
WHERE $tab = 'test_types';

SELECT 'Test Type Name' AS label,
       'name' AS name,
       'text' AS type,
       'e.g., Integration' AS placeholder,
       TRUE AS required
WHERE $tab = 'test_types';

-- Display test types as table
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown
WHERE $tab = 'test_types';

SELECT 
    id AS 'ID',
    name AS 'Name',
    datetime(created_at, 'localtime') AS 'Created',
    '[✏️](/pages/settings/edit_test_type.sql?id=' || id || ') &nbsp; [🗑️](/pages/settings/delete_test_type.sql?id=' || id || ')' AS 'Actions'
FROM test_types
WHERE $tab = 'test_types'
ORDER BY name;

-- 
-- SCENARIO TYPES TAB CONTENT
--
SELECT 'card' AS component,
       'Scenario Types' AS title,
       'Configure the types of scenarios available' AS description
WHERE $tab = 'scenario_types';

-- Add new scenario type form
SELECT 'form' AS component,
       '/pages/settings/save_scenario_type.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Add New Scenario Type' AS title
WHERE $tab = 'scenario_types';

SELECT 'Scenario Type Name' AS label,
       'name' AS name,
       'text' AS type,
       'e.g., Happy Path' AS placeholder,
       TRUE AS required
WHERE $tab = 'scenario_types';

-- Display scenario types as table
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown
WHERE $tab = 'scenario_types';

SELECT 
    id AS 'ID',
    name AS 'Name',
    datetime(created_at, 'localtime') AS 'Created',
    '[✏️](/pages/settings/edit_scenario_type.sql?id=' || id || ') &nbsp; [🗑️](/pages/settings/delete_scenario_type.sql?id=' || id || ')' AS 'Actions'
FROM scenario_types
WHERE $tab = 'scenario_types'
ORDER BY name;

-- 
-- EXECUTION TYPES TAB CONTENT
--
SELECT 'card' AS component,
       'Execution Types' AS title,
       'Configure the execution types available (e.g., Manual, Automated)' AS description
WHERE $tab = 'execution_types';

-- Add new execution type form
SELECT 'form' AS component,
       '/pages/settings/save_execution_type.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Add New Execution Type' AS title
WHERE $tab = 'execution_types';

SELECT 'Execution Type Name' AS label,
       'name' AS name,
       'text' AS type,
       'e.g., Automated' AS placeholder,
       TRUE AS required
WHERE $tab = 'execution_types';

-- Display execution types as table
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown
WHERE $tab = 'execution_types';

SELECT 
    id AS 'ID',
    name AS 'Name',
    datetime(created_at, 'localtime') AS 'Created',
    '[✏️](/pages/settings/edit_execution_type.sql?id=' || id || ') &nbsp; [🗑️](/pages/settings/delete_execution_type.sql?id=' || id || ')' AS 'Actions'
FROM execution_types
WHERE $tab = 'execution_types'
ORDER BY name;

-- 
-- TAGS TAB CONTENT
--
SELECT 'card' AS component,
       'Tags' AS title,
       'Configure common tags for your items' AS description
WHERE $tab = 'tags';

-- Add new tag form
SELECT 'form' AS component,
       '/pages/settings/save_tag.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Add New Tag' AS title
WHERE $tab = 'tags';

SELECT 'Tag Name' AS label,
       'name' AS name,
       'text' AS type,
       'e.g., Important' AS placeholder,
       TRUE AS required
WHERE $tab = 'tags';

-- Display tags as table
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown
WHERE $tab = 'tags';

SELECT 
    id AS 'ID',
    name AS 'Name',
    datetime(created_at, 'localtime') AS 'Created',
    '[✏️](/pages/settings/edit_tag.sql?id=' || id || ') &nbsp; [🗑️](/pages/settings/delete_tag.sql?id=' || id || ')' AS 'Actions'
FROM tags
WHERE $tab = 'tags'
ORDER BY name;

-- 
-- TEST CASE STATUSES TAB CONTENT
--
SELECT 'card' AS component,
       'Test Case Status' AS title,
       'Manage the status values available for test cases (e.g., Open, Passed, Failed)' AS description
WHERE $tab = 'test_case_statuses';

-- Add new status form
SELECT 'form' AS component,
       '/pages/test_cases/save_status.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Add New Status' AS title
WHERE $tab = 'test_case_statuses';

SELECT 'Status Name' AS label,
       'name' AS name,
       'text' AS type,
       'e.g., Passed' AS placeholder,
       TRUE AS required
WHERE $tab = 'test_case_statuses';

-- Display statuses as table
SELECT 'table' AS component,
       TRUE AS sort,
       TRUE AS search,
       'Actions' AS markdown
WHERE $tab = 'test_case_statuses';

SELECT 
    name AS 'Name',
    '[✏️](/pages/test_cases/edit_status.sql?id=' || id || ') &nbsp; [🗑️](/pages/test_cases/delete_status.sql?id=' || id || ')' AS 'Actions'
FROM test_case_statuses
WHERE $tab = 'test_case_statuses'
ORDER BY name;

-- 
-- ID FORMATS TAB CONTENT
--
SELECT 'card' AS component,
       'ID Format Settings' AS title,
       'Define the formats used to generate IDs for different items (e.g. TC-0001, PL-001, etc.)' AS description
WHERE $tab = 'id_formats';

-- Current values
SET _tc_id_format = (SELECT value FROM app_settings WHERE key = 'tc_id_format');
SET _plan_id_format = (SELECT value FROM app_settings WHERE key = 'plan_id_format');
SET _suite_id_format = (SELECT value FROM app_settings WHERE key = 'suite_id_format');
SET _req_id_format = (SELECT value FROM app_settings WHERE key = 'req_id_format');

-- Form to save the formats
SELECT 'form' AS component,
       '/pages/settings/save_tc_id_format.sql' AS action,
       'POST' AS method,
       'Save Formats' AS validate,
       'ID Format Patterns' AS title
WHERE $tab = 'id_formats';

SELECT 'Test Case ID Format Pattern' AS label,
       'tc_id_format' AS name,
       'text' AS type,
       'TC-{NUM}' AS placeholder,
       COALESCE($_tc_id_format, 'TC-{NUM}') AS value,
       'col-6' AS width,
       'Tokens: {REQ}, {NUM}, {PRJ}, {SUITE}' AS description
WHERE $tab = 'id_formats';

SELECT 'Plan ID Format Pattern' AS label,
       'plan_id_format' AS name,
       'text' AS type,
       'PL-{NUM}' AS placeholder,
       COALESCE($_plan_id_format, 'PL-{NUM}') AS value,
       'col-6' AS width,
       'Tokens: {NUM}, {PRJ}' AS description
WHERE $tab = 'id_formats';

SELECT 'Suite ID Format Pattern' AS label,
       'suite_id_format' AS name,
       'text' AS type,
       'ST-{NUM}' AS placeholder,
       COALESCE($_suite_id_format, 'ST-{NUM}') AS value,
       'col-6' AS width,
       'Tokens: {NUM}, {PRJ}' AS description
WHERE $tab = 'id_formats';

SELECT 'Requirement ID Format Pattern' AS label,
       'req_id_format' AS name,
       'text' AS type,
       'RQ-{NUM}' AS placeholder,
       COALESCE($_req_id_format, 'RQ-{NUM}') AS value,
       'col-6' AS width,
       'Tokens: {NUM}, {PRJ}, {SUITE}' AS description
WHERE $tab = 'id_formats';

-- Help table showing available tokens
SELECT 'table' AS component,
       'Available Tokens' AS title,
       'Reference guide for pattern tokens' AS description
WHERE $tab = 'id_formats';

SELECT '{NUM}' AS 'Token', 'Auto-incremented sequence number (zero-padded to 3 or 4 digits)' AS 'Description', '001 or 0001' AS 'Example Value'
WHERE $tab = 'id_formats'
UNION ALL
SELECT '{REQ}', 'Requirement ID (if applicable)', 'RQ-001'
WHERE $tab = 'id_formats'
UNION ALL
SELECT '{PRJ}', 'Project name (slug, lowercase, hyphenated)', 'login-page'
WHERE $tab = 'id_formats'
UNION ALL
SELECT '{SUITE}', 'Suite name (first 3 letters, uppercase)', 'REG'
WHERE $tab = 'id_formats';
