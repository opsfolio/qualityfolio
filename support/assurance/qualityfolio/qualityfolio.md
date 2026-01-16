---
sqlpage-conf:
  database_url: "sqlite://resource-surveillance.sqlite.db?mode=rwc"
  web_root: "./dev-src.auto"
  allow_exec: true
  port: "9227"
---
 

```code DEFAULTS
sql * --interpolate --injectable
```

# **Spry for Test Management**

Spry helps QA and Test Engineering teams **unify documentation,
automation, and execution** into a single, always-accurate workflow.
Instead of maintaining scattered test scripts, wiki pages, CI pipelines,
and notes, Spry allows you to write Markdown that is both **readable**
and **executable** --- keeping your test processes consistent,
automated, and audit-ready.

## What Spry Solves

Test workflows often become fragmented across tools, repos, and teams.
Spry fixes:

- Outdated test documentation\
- Manual steps in test execution\
- Test scripts stored without explanations\
- Lack of standard test-run procedures\
- No single place for evidence capture\
- Difficulty onboarding QA and new engineers

Spry ensures tests, execution buttons, and documentation all stay in
sync.

## Who Should Use Spry?

Spry is ideal for teams managing:

- Manual + automated testing\
- Regression test cycles\
- Playwright / Selenium / API test suites\
- QA operations\
- DevOps-driven test automation\
- CI/CD test runs\
- Evidence capture for audits (SOC 2, HIPAA, ISO)

## Why Spry for Test Management

- **Keeps test documentation executable & up to date**\
- **Unifies test scripts, workflows, and evidence**\
- **Accelerates QA cycles** through instant automation\
- **Reduces manual execution errors**\
- **Improves visibility** across QA, DevOps, and Production teams

## Unified QA Workflow With Spry

Spry ties all critical QA components together:

### Human-Readable Test Documentation

Describe test purpose, scope, and expected results in Markdown.

### Embedded Test Execution

Run Playwright, API tests, or CLI tools directly from the same file.

### Evidence Capture

Save logs, screenshots, and test output for audits or reviews.

### Reporting

Generate complete test execution reports automatically.

---

# Surveilr Ingest Files

```bash ingest --descr "Ingest Files"
#!/usr/bin/env -S bash
surveilr ingest files -r ./test-artifacts && surveilr orchestrate transform-markdown
```
# SQL query

```bash deploy -C --descr "Generate sqlpage_files table upsert SQL and push them to SQLite"
surveilr shell qualityfolio-json-etl.sql
```

```bash deploy-sqlpage --descr "Generate the dev-src.auto directory to work in SQLPage dev mode"
spry sp spc --package --conf sqlpage/sqlpage.json -m qualityfolio.md | sqlite3 resource-surveillance.sqlite.db
```

# SQL Page

```sql PARTIAL global-layout.sql --inject *.sql*


SELECT 'shell' AS component,
       NULL AS icon,
       'https://www.surveilr.com/assets/brand/qf-logo.png' AS favicon,
       'https://www.surveilr.com/assets/brand/qf-logo.png' AS image,
       'fluid' AS layout,
       true AS fixed_top_menu,
       'index.sql' AS link,
       '/opsfolio-integration.js' AS javascript;    

        
       
SET resource_json = sqlpage.read_file_as_text('spry.d/auto/resource/${path}.auto.json');
SET page_title  = json_extract($resource_json, '$.route.caption');
SET page_description  = json_extract($resource_json, '$.route.description');
SET page_path = json_extract($resource_json, '$.route.path');

${ctx.breadcrumbs()}

```

```contribute sqlpage_files --base .
./opsfolio-integration.js .

```
---

# Dashboard Routes

## Home Dashboard

```sql index.sql { route: { } }


-- Project Filter

select
    'divider'            as component,
    'QA Progress & Performance Dashboard' as contents,
    6                  as size,
    'blue'               as color;
-- Introduction

SELECT 'text' AS component,
  'The dashboard provides a centralized view of your testing efforts, displaying key metrics such as test progress, results, and team productivity. It offers visual insights with charts and reports, enabling efficient tracking of test runs, milestones, and issue trends, ensuring streamlined collaboration and enhanced test management throughout the project lifecycle' AS contents;

-- Set the project_name parameter when only one project exists
SET project_name = (
    SELECT CASE 
        WHEN COUNT(DISTINCT project_name) = 1 
        THEN MIN(project_name)
        ELSE :project_name
    END
    FROM qf_role_with_evidence 
    WHERE project_name IS NOT NULL AND project_name <> ''
);
SELECT
  'html' AS component,
  '
  <style>
    .project-dropdown {
        display: flex;
        justify-content: flex-end;
        align-items: center;
        margin-top: 0 !important;
        margin-bottom: 6px !important;
        background: transparent !important;
        border: none !important;
        box-shadow: none !important;
    }

    .project-dropdown fieldset,
    .project-dropdown form {
        margin: 0 !important;
        padding: 0 !important;
        border: 0 !important;
        background: transparent !important;
    }

    .project-dropdown select {
        width: 100%;
        height: 42px;
        font-size: 14px;
        font-weight: 500;
    }

    /* Kill orange spacing */
    .page-body > form.project-dropdown {
        padding: 0 !important;
        margin: 0 !important;
    }

    .form-fieldset .row {
        justify-content: end !important;
    }
  </style>
  ' AS html;


-- Now show the form
SELECT 'form' AS component,
       'true' AS auto_submit,
       'project-dropdown' as class;

SELECT
       'project_name' AS name,
       '' AS label,
       'select' AS type,
       :project_name AS value,  -- Now this will work
       json_group_array(
           json_object(
               'label', label_text,
               'value', value_text
           )
       ) AS options
FROM (
    SELECT 'Select a project...' AS label_text, 
           '' AS value_text, 
           0 AS sort_order
    WHERE (SELECT COUNT(DISTINCT project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '') > 1
    
    UNION ALL
    
    SELECT DISTINCT project_name AS label_text, 
           project_name AS value_text, 
           1 AS sort_order
    FROM qf_evidence_status
    WHERE project_name IS NOT NULL AND project_name <> ''
    
    ORDER BY sort_order, label_text
);


-- Metrics Cards
SELECT 'card' AS component, 4 AS columns;

-- Total Test Cases
SELECT '## Test Case Count' AS description_md,
       '# ' || COALESCE(SUM(test_case_count), 0) AS description_md,
        'white' as background_color,
        'red' as color,
        '12' as width,
        'brand-speedtest'       as icon,      
       'test-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_title, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_count
WHERE 
  project_title = :project_name;

-- Passed Cases
SELECT '## Total Passed Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'check' AS icon,
        'blue' AS color,
       'passed.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status IN ('passed','pending')
  AND 
  project_name = :project_name;

-- Failed Percentage
WITH counts AS (
  SELECT COUNT(DISTINCT test_case_id) AS total_tests,
         COUNT(DISTINCT CASE WHEN test_case_status IN ('reopen','failed')
               THEN test_case_id END) AS total_defects
  FROM qf_case_status
  WHERE project_name = :project_name
)
SELECT '## Failed Percentage' AS description_md,
       '# ' || CASE WHEN total_tests = 0 THEN '0%'
                    ELSE ROUND((total_defects * 100.0) / total_tests) || '%' END AS description_md,
       'white' AS background_color,
       'alert-circle' AS icon,
       'red' AS color
FROM counts;

-- Success Percentage
WITH counts AS (
  SELECT COUNT(DISTINCT test_case_id) AS total_tests,
         COUNT(DISTINCT CASE WHEN test_case_status IN ('reopen','failed')
               THEN test_case_id END) AS total_defects
  FROM qf_case_status
  WHERE project_name = :project_name
)
SELECT '## Success Percentage' AS description_md,
       '# ' || CASE WHEN total_tests = 0 THEN '0%'
                    ELSE ROUND(((total_tests - total_defects) * 100.0) / total_tests) || '%' END AS description_md,
       'white' AS background_color,
        'lime' as color,
    'circle-dashed-check'       as icon
FROM counts;

-- Open Defects
SELECT '## Open Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
         'orange' as color,
    'details-off'       as icon,
       'open.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status = 'failed'
  AND project_name = :project_name;

-- Reopened Defects
SELECT '## Reopened Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'blue' AS color,
        'details-off'       as icon,
       'reopen.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status = 'reopen'
  AND project_name = :project_name;

-- Total Defects
SELECT '## Total Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'red' AS color,
        'details-off'       as icon,
       'defects.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status IN ('reopen', 'failed')
  AND project_name =:project_name;

-- Closed Defects
SELECT '## Closed Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
        'purple' as color,
    'details-off'       as icon,
       'closed.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status = 'closed'
  AND project_name = :project_name;

-- Todo Test cases
SELECT '## Cycle Todo Test Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'alert-circle' AS icon,
       'yellow' AS color,
       'todo-cycle.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status IN ('pending','')
  AND project_name = :project_name;

-- Non assigned test cases
SELECT '## Non Assigned Test cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'alert-circle' AS icon,
       'purple' AS color,
       'non-assigned-test-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE (latest_assignee IS NULL OR latest_assignee = '')
  AND project_name = :project_name;

  -- Automation percentage
 SELECT
    '## Automation Coverage' AS description_md,
    'white' AS background_color,
    '# ' || COALESCE(
        (
            SELECT test_case_percentage
            FROM qf_case_execution_status_percentage
            WHERE project_name = :project_name
              AND UPPER(execution_type) = 'AUTOMATION'
        ),
        0
    ) || '%' AS description_md,
     'automation.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link,
    'green' AS color,
    'brand-ansible' AS icon;



 SELECT
    '## Manual Coverage' AS description_md,
    'white' AS background_color,
    '# ' || COALESCE(
        (
            SELECT test_case_percentage
            FROM qf_case_execution_status_percentage
            WHERE project_name = :project_name
              AND UPPER(execution_type) = 'MANUAL'
        ),
        0
    ) || '%' AS description_md,
        'manual.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link,
    'orange' AS color,
    'brand-ansible' AS icon;

-- Test suite count
SELECT '## Test Suite Count' AS description_md,
         '# ' || COALESCE(COUNT(suiteid), 0) AS description_md,
       'white' AS background_color,
          'pink' as color,
    'timeline-event'       as icon,    
       'test-suite-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_role_with_suite
WHERE 
  project_name = :project_name HAVING COUNT(suiteid) > 0;

-- Test plan count
SELECT '## Test Plan Count' AS description_md,
         '# ' || COALESCE(COUNT(planid), 0) AS description_md,
       'white' AS background_color,
       'timeline-event'       as icon,
        'green' as color,      
       'test-plan-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_role_with_plan
WHERE 
  project_name = :project_name HAVING COUNT(planid) > 0;

-- History test cases
SELECT '## Test Cycle History' AS description_md,
       'white' AS background_color,
       'alert-circle' AS icon,
       'blue' AS color,
       'test-case-history.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link;

  
-- Test Status Visualization
SELECT 'divider' AS component,
       'Comprehensive Test Status' AS contents,
       5 AS size,
       'blue' AS color;

-- SELECT 'card' AS component, 2 AS columns;
-- SELECT '/chart/pie-chart-left.sql?color=green&n=42&_sqlpage_embed' AS embed;
-- SELECT '/chart/chart.sql?' AS embed;

SELECT 'card' AS component, 2 AS columns;

-- Pass parameters in the URL
SELECT '/chart/pie-chart-left.sql?project_name=' || :project_name ||'&status=Passed&color=green&_sqlpage_embed' AS embed;

SELECT '/chart/pie-chart-autostatus.sql?project_name=' || :project_name ||'&status=AUTOMATION&color=green&_sqlpage_embed' AS embed;
-- Assignee Breakdown
SELECT 'divider' AS component,
       'ASSIGNEE WISE TEST CASE DETAILS' AS contents,
       5 AS size,
       'blue' AS color;

-- Assignee Filter
SELECT 'form' AS component,
       'Submit' AS validate,
       'true' AS auto_submit;

SELECT 'hidden' AS type,
       'project_name' AS name,
       COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '')) AS value;

SELECT 'assignee' AS name,
       'Assignee' AS label,
       'select' AS type,
       :assignee AS value,
       json_group_array(
         json_object('label', label_text, 'value', value_text)
       ) AS options
FROM (
    -- Default "ALL" option
    SELECT 'ALL' AS label_text,
           'ALL' AS value_text,
           0 AS sort_order
   
    UNION ALL
   
    -- Individual assignees

    select tbl.assignee AS label_text,
tbl.assignee AS value_text,
 1 AS sort_order
  from qf_role_with_evidence tbl
where project_name=:project_name  and
 tbl.assignee!='' and tbl.assignee is not null
group by tbl.assignee
   
    ORDER BY sort_order, label_text
);



SELECT 'table' AS component,
       "ASSIGNEE" AS markdown,
       "TOTAL TEST CASES" AS markdown,
       "TOTAL PASSED" AS markdown,
       "TOTAL FAILED" AS markdown,
       "TOTAL REOPEN" AS markdown,
       "TOTAL CLOSED" AS markdown,
       1 AS search,
       1 AS sort;

SELECT
    latest_assignee AS "ASSIGNEE",
 
    ${md.link("COUNT(test_case_id)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL TEST CASES",
 
    ${md.link("SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&status=passed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL PASSED",
 
    ${md.link("SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&status=failed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL FAILED",
 
    ${md.link("SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&status=reopen&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL REOPEN",
 
    ${md.link("SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&status=closed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL CLOSED"
 
FROM qf_case_status
WHERE project_name = CASE 
      WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '') = 1 
      THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))
      ELSE :project_name
  END
  AND (
      (SELECT COUNT(DISTINCT project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
      OR (:project_name IS NOT NULL AND :project_name <> '')
  )
  AND latest_assignee IS NOT NULL
  AND TRIM(latest_assignee) <> ''
  AND (
        :assignee IS NULL
     OR :assignee = 'ALL'
     OR latest_assignee = :assignee
  )
 
GROUP BY latest_assignee
${pagination.limit};
${pagination.navigation};

-- Test Cycle Summary Details
SELECT 'divider' AS component,
       'TEST CYCLE SUMMARY DETAILS ' AS contents,
       5 AS size,
       'blue' AS color;

SELECT 'table' AS component,
       "CYCLE" as markdown,
       "CYCLE DATE" as markdown,
       "TOTAL TEST CASES" as markdown,
       1 AS sort,
       1 AS search;

SELECT  
  ${md.link("cycle",
        ["'cycletotaltestcase.sql?cycle='", "cycle","'&project_name='",":project_name"])} AS "CYCLE",  
  cycledate as 'CYCLE DATE',
  totalcases as 'TOTAL TEST CASES'
FROM cycle_data_summary
WHERE project_name = CASE 
      WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '') = 1 
      THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))
      ELSE :project_name
  END
  AND (
      (SELECT COUNT(DISTINCT project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
      OR (:project_name IS NOT NULL AND :project_name <> '')
  );

-- Requirement Traceability
SELECT 'divider' AS component,
       'REQUIREMENT TRACEABILITY' AS contents,
       5 AS size,
       'blue' AS color;

${paginate("qf_case_status", "WHERE project_name = COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '')) GROUP BY requirement_ID")}

SELECT 'table' AS component,
       "REQUIREMENT ID" AS markdown,
       "TOTAL TEST CASES" AS markdown,
       "TOTAL PASSED" AS markdown,
       "TOTAL FAILED" AS markdown,
       "TOTAL RE-OPEN" AS markdown,
       "TOTAL CLOSED" AS markdown,
       1 AS sort,
       1 AS search;

SELECT
    requirement_ID AS "REQUIREMENT ID",
    ${md.link("COUNT(test_case_id)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&project_name='", ":project_name"])} AS "TOTAL TEST CASES",
    ${md.link("SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=passed&project_name='", ":project_name"])} AS "TOTAL PASSED",
    ${md.link("SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=failed&project_name='", ":project_name"])} AS "TOTAL FAILED",
    ${md.link("SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=reopen&project_name='", ":project_name"])} AS "TOTAL RE-OPEN",
    ${md.link("SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=closed&project_name='", ":project_name"])} AS "TOTAL CLOSED"
FROM qf_case_status
WHERE project_name = :project_name
GROUP BY requirement_ID
${pagination.limit};
${pagination.navigation};

-- Open Issues
SELECT 'divider' AS component,
       'OPEN ISSUES' AS contents,
       5 AS size,
       'blue' AS color;

SELECT 'table' AS component,
       "ISSUE ID" AS markdown,
       "TEST CASE ID" AS markdown,
       "DESCRIPTION" AS markdown,
       "CREATED DATE" AS markdown,
       "ISSUE AGE IN DAYS" AS markdown,
       1 AS sort,
       1 AS search;

SELECT issue_id AS "ISSUE ID",
       test_case_id AS "TEST CASE ID",
       test_case_description AS "DESCRIPTION",
       created_date AS "CREATED DATE",
       total_days AS "ISSUE AGE IN DAYS"
FROM qf_open_issue_age
WHERE project_name = :project_name
ORDER BY test_case_id;
```

---

# Test Case List Views

## All Test Cases

 <!--  -->

```sql test-cases.sql { route: { caption: "Test Cases" } }
-- @route.description "An overview of all test cases showing the test case ID, title, current status, and the latest execution cycle, allowing quick review and tracking of test case progress."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT 
  ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
    test_case_title AS "Title",
    test_case_status AS "Status",
    latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE project_name = $project_name
ORDER BY test_case_id;
```

## Passed Test Cases

<!-- Lists all test cases that have passed -->

```sql passed.sql { route: { caption: "Passed Test Cases" } }
-- @route.description "Lists all test cases with a passed status, showing their test case ID, title, and latest execution cycle for quick status review"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Passed Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT 

  ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE test_case_status = 'passed'
AND project_name = $project_name
ORDER BY test_case_id;
```

## Defects (Failed & Reopened)

```sql defects.sql { route: { caption: "Defects Test Cases" } }
-- @route.description "Shows test cases with defects, including failed and reopened cases, along with their test case ID, title, current status, and latest cycle for effective defect tracking"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Defects' AS title,
       1 AS search,
       1 AS sort;

SELECT 
 ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE test_case_status IN ('reopen', 'failed')
AND project_name = $project_name
ORDER BY test_case_id;
```

## Closed Cases

```sql closed.sql { route: { caption: "Closed Test Cases" } }
-- @route.description "List of all test cases that have closed"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Closed Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT 
 ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE test_case_status = 'closed'
AND project_name = $project_name
ORDER BY test_case_id;
```

## Open Cases

```sql open.sql { route: { caption: "Open Test Cases" } }
-- @route.description "Displays all open test cases with their test case ID, title, current status, and latest cycle to help monitor issues "

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Reopened Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT 
 ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE test_case_status = 'failed'
AND project_name = $project_name
ORDER BY test_case_id;
```

## Reopened Cases

```sql reopen.sql { route: { caption: "Reopened Test Cases" } }
-- @route.description "Displays all reopened test cases with their test case ID, title, current status, and latest cycle to help monitor issues "

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Reopened Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT 
 ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE test_case_status = 'reopen'
AND project_name = $project_name
ORDER BY test_case_id;
```

---

# Filtered Views

## Cycle-Filtered Test Cases
```sql cycletotaltestcase.sql { route: { caption: "Test Cases" } }
-- @route.description "Shows test cases filtered by selected cycle and status, displaying the test case ID, title, current status, and latest cycle for focused analysis and tracking "
 
SELECT 'text' AS component,
$page_description AS contents_md;
 
SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Test Cases' AS title,
       1 AS search,
       1 AS sort;
 
SELECT 
 ${md.link("tbl1.testcaseid ",
        ["'testcasedetails.sql?testcaseid='", "tbl1.testcaseid",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       tbl2.title  AS "Title",
       tbl1.status AS "Status",
       tbl1.cycle AS "Latest Cycle"
FROM qf_role_with_evidence tbl1
inner join qf_role_with_case tbl2
on tbl1.testcaseid=tbl2.testcaseid
and tbl1.uniform_resource_id=tbl2.uniform_resource_id
WHERE ($cycle IS NULL OR tbl1.cycle = $cycle)
  AND ($status IS NULL OR tbl1.status = $status) AND tbl1.project_name=$project_name
ORDER BY tbl1.testcaseid;
```

## Requirement-Filtered Test Cases

```sql requirementtotaltestcase.sql { route: { caption: "Requirement Cases" } }
-- @route.description "Lists test cases associated with a specific requirement, showing their test case ID, title, current status, latest cycle, and requirement for requirement-wise tracking"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Cases' AS title,
       'Test Case ID' AS markdown,
       1 AS search,
       1 AS sort;

SELECT 
 ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle",
       requirement_ID AS "Requirement"
FROM qf_case_status
WHERE requirement_ID = $req
  AND ($status IS NULL OR test_case_status = $status)
ORDER BY test_case_id;
```

## Assignee-Filtered Test Cases

```sql assigneetotaltestcase.sql { route: { caption: "Assignee Cases" } }
-- @route.description "Displays test cases filtered by assignee and status, showing the test case ID, title, current status, and latest cycle to support ownership-based tracking and review "

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Cases' AS title,
       'Test Case ID' AS markdown,
       1 AS search,
       1 AS sort;

SELECT 
 ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE ($assignee IS NULL OR latest_assignee = $assignee)
  AND ($status IS NULL OR test_case_status = $status)
ORDER BY test_case_id;
```

---

# Historical Views

## Test Cycle History with Date Filtering

```sql test-case-history.sql { route: { caption: "Test Cycle History" } }
-- @route.description "Provides a cycle-wise summary of test execution, showing total test cases and status-wise counts (passed, failed, reopened, closed), with optional date-range filtering to analyze results by cycle creation and ingestion time."

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT
  'form'    AS component,
  'get' AS method,
  'TRUE' AS auto_submit;

-- From date (retains value after submission)
SELECT
  'from_date'  AS name,
  'From date'  AS label,
  'date'       AS type,
  6 as width,
  strftime('%Y-%m-%d', $from_date) AS value;

-- To date (retains value after submission)
SELECT
  'to_date'    AS name,
  'To date'    AS label,
  'date'       AS type,
  6 as width,
  $to_date AS value;

  SELECT
  'project_name' AS name,
  'hidden' AS type,
  $project_name AS value;

SELECT
  'table' AS component,
  'CYCLE' AS markdown,
  'TOTAL TEST CASES' AS markdown,
  'TOTAL PASSED' AS markdown,
  'TOTAL FAILED' AS markdown,
  'TOTAL RE-OPEN' AS markdown,
  'TOTAL CLOSED' AS markdown,
  'TOTAL PENDING' AS markdown,
  1 AS sort,
  1 AS search;


WITH tblevidence AS (
  SELECT
  DISTINCT
    tbl.assignee,
    -- tbl.created_at,
    tbl.cycle,
    tbl.project_name,
    tbl.status,
    tbl.severity,
    tbl.testcaseid,
  
  tbl.cycledate
  FROM qf_role_with_evidence_history tbl
  WHERE tbl.project_name = $project_name
)

SELECT
  tbl3.cycle,
 tbl3.cycledate
  ,

  tbl3.project_name,
  ${md.link(
      "SUM(tbl3.total_testcases)",
      [
        "'cycletotaltestcase.sql?cycle='", "tbl3.cycle",
        "'&project_name='", "$project_name"
      ]
  )} AS "TOTAL TEST CASES",

  ${md.link(
      "SUM(tbl3.passed_cases)",
      [
        "'cycletotaltestcase.sql?cycle='", "tbl3.cycle",
        "'&status=passed&project_name='", "$project_name"
      ]
  )} AS "TOTAL PASSED",

  ${md.link(
      "SUM(tbl3.failed_cases)",
      [
        "'cycletotaltestcase.sql?cycle='", "tbl3.cycle",
        "'&status=failed&project_name='", "$project_name"
      ]
  )} AS "TOTAL FAILED",

  ${md.link(
      "SUM(tbl3.reopen_cases)",
      [
        "'cycletotaltestcase.sql?cycle='", "tbl3.cycle",
        "'&status=reopen&project_name='", "$project_name"
      ]
  )} AS "TOTAL RE-OPEN",

  ${md.link(
      "SUM(tbl3.closed_cases)",
      [
        "'cycletotaltestcase.sql?cycle='", "tbl3.cycle",
        "'&status=closed&project_name='", "$project_name"
      ]
  )} AS "TOTAL CLOSED",

  ${md.link(
      "SUM(tbl3.pending_cases)",
      [
        "'cycletotaltestcase.sql?cycle='", "tbl3.cycle",
        "'&status=pending&project_name='", "$project_name"
      ]
  )} AS "TOTAL PENDING"



FROM (

  SELECT
    tbl2.cycle,

    tbl2.cycledate,
    tbl2.project_name,
    COUNT(*) AS total_testcases,
    0 AS passed_cases,
    0 AS failed_cases,
    0 AS reopen_cases,
    0 AS closed_cases,
    0 AS pending_cases
  FROM tblevidence tbl2
  GROUP BY tbl2.cycle, tbl2.cycledate, tbl2.project_name

  UNION ALL

  SELECT
    tbl2.cycle,
    tbl2.cycledate,
    tbl2.project_name,
    0 AS total_testcases,
    SUM(CASE WHEN tbl2.status='passed'  THEN 1 ELSE 0 END) AS passed_cases,
    SUM(CASE WHEN tbl2.status='failed'  THEN 1 ELSE 0 END) AS failed_cases,
    SUM(CASE WHEN tbl2.status='reopen'  THEN 1 ELSE 0 END) AS reopen_cases,
    SUM(CASE WHEN tbl2.status='closed'  THEN 1 ELSE 0 END) AS closed_cases,
    SUM(CASE WHEN tbl2.status='pending' THEN 1 ELSE 0 END) AS pending_cases
 
  FROM tblevidence tbl2
  GROUP BY tbl2.cycle, tbl2.cycledate, tbl2.project_name

) tbl3

WHERE
(
  DATE(
   
    SUBSTR(tbl3.cycledate,7,4)||'-'||SUBSTR(tbl3.cycledate,1,2)||'-'||SUBSTR(tbl3.cycledate,4,2)
  ) >= DATE(
     DATE(SUBSTR($from_date,1,4)||'-'||SUBSTR($from_date,6,2)||'-'||SUBSTR($from_date,9,2))
    
    )
)
AND
(DATE(

    SUBSTR(tbl3.cycledate,7,4)||'-'||SUBSTR(tbl3.cycledate,1,2)||'-'||SUBSTR(tbl3.cycledate,4,2)
  ) <= DATE(
    DATE(SUBSTR($to_date,1,4)||'-'||SUBSTR($to_date,6,2)||'-'||SUBSTR($to_date,9,2))
    
   )
)
AND
    $from_date IS NOT NULL
AND $from_date <> ''
AND $to_date   IS NOT NULL
AND $to_date   <> ''

GROUP BY
  tbl3.cycle,
  tbl3.cycledate,
 
  tbl3.project_name


ORDER BY
  tbl3.cycle;

```

---

# Detail Views

## Test Case Details

```sql testcasedetails.sql { route: { caption: "Test Case Details" } }
-- @route.description "Displays detailed information for a selected test case, including its description, preconditions, execution steps, and expected results"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'card' AS component,
       'Test Cases Details' AS title,
       1 AS columns;

SELECT 'Test Case ID: ' || test_case_id AS title,
    '**Description:** ' || description || '

' ||
    '**Preconditions:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(preconditions) AS j) || '

' ||
    '**Steps:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(steps) AS j) || '

' ||
    '**Expected Results:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(expected_results) AS j)
    AS description_md
FROM qf_case_master as qcm
INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid
WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name

ORDER BY qcm.test_case_id;
```

---

# Visualizations

## Pass/Fail Pie Chart

```sql chart/pie-chart-left.sql { route: { caption: "" } }
SELECT 'chart' AS component,
       'pie' AS type,
       'Test case execution status' AS title,
       TRUE AS labels,
       'green' AS color,
       'red' AS color,
       'chart-left' AS class;
 
SELECT  

'Passed' AS label,
       COALESCE( passedpercentage,0) AS value
FROM qf_case_status_percentage  
where projectname =$project_name
 
 SELECT 'Failed' AS label,
       COALESCE( failedpercentage ,0) AS value
FROM qf_case_status_percentage where  projectname = $project_name ;
```

## Open Issues Age Chart

```sql chart/chart.sql { route: { caption: "" } }
SELECT 'chart' AS component,
       'bar' AS type,
       'Age-wise Open Issues' AS title,
       TRUE AS labels,
       'Date' AS xtitle,
       'Age' AS ytitle,
       5 as ystep;

SELECT created_date AS label,
       total_records AS value
FROM qf_agewise_opencases where  projectname = $project_name ;
```

## Non Assigned Test Cases

```sql non-assigned-test-cases.sql { route: { caption: "Non Assigned Test CAses" } }
-- @route.description "Provides the List of Non Assigned Test Cases"

SELECT 'table' AS component,
       "TOTAL TEST CASES" AS markdown,
       "TOTAL PASSED" AS markdown,
       "TOTAL FAILED" AS markdown,
       "TOTAL REOPEN" AS markdown,
       "TOTAL CLOSED" AS markdown,
       1 AS search,
       1 AS sort;

SELECT
    ${md.link("COUNT(test_case_id)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&project_name='", "$project_name"])} AS "TOTAL TEST CASES",
    ${md.link("SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=passed'","'&project_name='", "$project_name"])} AS "TOTAL PASSED",
    ${md.link("SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=failed'","'&project_name='", "$project_name"])} AS "TOTAL FAILED",
    ${md.link("SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=reopen'","'&project_name='", "$project_name"])} AS "TOTAL REOPEN",
    ${md.link("SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=closed'","'&project_name='", "$project_name"])} AS "TOTAL CLOSED"
FROM qf_case_status
WHERE latest_assignee IS NULL OR latest_assignee = ''
GROUP BY latest_assignee;

```
## TODO Test Cases
 
```sql todo-test-cases.sql { route: { caption: "Todo Test Cases" } }
-- @route.description "Provides the List of Non Assigned Test Cases"
 
SELECT 'text' AS component,
$page_description AS contents_md;
 
SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Passed Test Cases' AS title,
       1 AS search,
       1 AS sort;
 
SELECT  ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status
WHERE test_case_status  IN ('pending','')
  AND project_name = $project_name 
 
ORDER BY test_case_id;
 
```
```sql todo-cycle.sql{ route: { caption: "Todo Test Cases" } }
-- @route.description "Provides the List of Non Assigned Test Cases"

${paginate("qf_case_status")}

SELECT 'table' AS component,
       "TOTAL PENDING" AS markdown,
       1 AS sort,
       1 AS search;

SELECT
  latest_cycle,
  
  ${md.link("COUNT(test_case_id)",
      ["'todo-test-cases.sql?project_name='","project_name"])} AS "TOTAL PENDING"
   
FROM qf_case_status 
WHERE (test_case_status = 'pending' OR test_case_status = '' OR test_case_status IS NULL)
  AND project_name = $project_name

GROUP BY latest_cycle

```
```sql test-suite-cases.sql { route: { caption: "Test suite" } }
-- @route.description "Test suite is a collection of test cases designed to verify the functionality, performance, and security of a software application. It ensures that the application meets the specified requirements by executing predefined tests across various scenarios, identifying defects, and validating that the system works as intended.."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'SUITE NAME' AS markdown,
       'Title' AS title,
       1 AS search,
       1 AS sort;
SELECT
  ${md.link(
      "suiteid",
      [
        "'suitecasedetails.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "SUITE NAME",
  title AS "Title"
FROM qf_role_with_suite
WHERE project_name = $project_name
ORDER BY suiteid;

```
```sql suitecasedetails.sql { route: { caption: "Test suite Cases" } }

SELECT 'text' AS component,
$page_description AS contents_md;


SELECT 'table' AS component,
     
       'Test Case ID' AS markdown, 
        'Test Cases' AS title,   
       1 AS search,
       1 AS sort;
SELECT
  ${md.link(
      "tbl.testcaseid",
      [
        "'testcasedetails.sql?testcaseid='",
        "tbl.testcaseid",
        "'&project_name='",
        "$project_name"
      ]
  )} AS "Test Case ID",
  tbl.title
FROM qf_role_with_case tbl
WHERE tbl.uniform_resource_id = $uniform_resource_id
  AND tbl.project_name = $project_name
  AND tbl.rownum > CAST($id AS NUMERIC)  
  AND (
        CASE
          WHEN (
            SELECT MIN(rownum)
            FROM qf_role_with_suite
            WHERE uniform_resource_id = $uniform_resource_id
              AND rownum > CAST($id AS NUMERIC) AND tbl.project_name = $project_name
          ) IS NOT NULL
          THEN tbl.rownum < (
            SELECT MIN(rownum)
            FROM qf_role_with_suite
            WHERE uniform_resource_id = $uniform_resource_id
              AND rownum > CAST($id AS NUMERIC) AND tbl.project_name = $project_name
          )
          ELSE 1 = 1
        END
      );

   
```
```sql automation.sql { route: { caption: "Automation Test Cases" } }
-- @route.description "Displays all automated test cases with their test case ID, title, current status, and latest cycle to help monitor issues "

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Automation Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
       title AS "Title",
       
FROM qf_role_with_case
WHERE execution_type = 'failed'
AND project_name = $project_name
ORDER BY test_case_id;
```


```sql automation.sql { route: { caption: "Automation Test Cases" } }
-- @route.description "An overview of all test cases under type automation execution showing the test case ID, title, current status, and the latest execution cycle, allowing quick review and tracking of test case progress."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT 

     ${md.link("testcaseid",
        ["'automationtestcasedetails.sql?testcaseid='", "testcaseid",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
    qcs.test_case_title AS "Title",
    qcs.test_case_status AS "Status",
    qcs.latest_cycle AS "Latest Cycle"
FROM qf_role_with_case as qrc
INNER JOIN qf_case_status as qcs ON qrc.testcaseid=qcs.test_case_id
AND qcs.project_name=qrc.project_name
WHERE qrc.project_name = $project_name AND UPPER(execution_type)='AUTOMATION'
ORDER BY testcaseid;
```
```sql automationtestcasedetails.sql { route: { caption: "Automation Test Case Details" } }
-- @route.description "Displays detailed information for a selected test case, including its description, preconditions, execution steps, and expected results"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'card' AS component,
       'Test Cases Details' AS title,
       1 AS columns;

SELECT 'Test Case ID: ' ||    qcm.test_case_id AS title,
    '**Description:** ' || description || '

' ||
    '**Preconditions:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(preconditions) AS j) || '

' ||
    '**Steps:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(steps) AS j) || '

' ||
    '**Expected Results:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(expected_results) AS j)
    AS description_md
FROM qf_case_master as qcm
INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid
WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name
AND UPPER(qwc.execution_type)='AUTOMATION'
ORDER BY test_case_id;
```


```sql manual.sql { route: { caption: "Manual Test Cases" } }
-- @route.description "An overview of all test cases under type manual execution showing the test case ID, title, current status, and the latest execution cycle, allowing quick review and tracking of test case progress."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT 

     ${md.link("testcaseid",
        ["'manaultestcasedetails.sql?testcaseid='", "testcaseid",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
    qcs.test_case_title AS "Title",
    qcs.test_case_status AS "Status",
    qcs.latest_cycle AS "Latest Cycle"
FROM qf_role_with_case as qrc
INNER JOIN qf_case_status as qcs ON qrc.testcaseid=qcs.test_case_id
AND qcs.project_name=qrc.project_name
WHERE qrc.project_name = $project_name AND UPPER(execution_type)='MANUAL'
ORDER BY testcaseid;
```
```sql manaultestcasedetails.sql { route: { caption: "Manual Test Case Details" } }
-- @route.description "Displays detailed information for a selected test case, including its description, preconditions, execution steps, and expected results"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'card' AS component,
       'Test Cases Details' AS title,
       1 AS columns;

SELECT 'Test Case ID: ' ||    qcm.test_case_id AS title,
    '**Description:** ' || description || '

' ||
    '**Preconditions:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(preconditions) AS j) || '

' ||
    '**Steps:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(steps) AS j) || '

' ||
    '**Expected Results:**

' ||
    (SELECT group_concat(
        (CAST(j.key AS INTEGER) + 1) || '. ' ||
        json_extract(j.value, '$.item[0].paragraph'),
        char(10))
     FROM json_each(expected_results) AS j)
    AS description_md
FROM qf_case_master as qcm
INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid
WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name
AND UPPER(qwc.execution_type)='MANUAL'
ORDER BY test_case_id;
```

```sql test-plan-cases.sql { route: { caption: "Test Plan" } }
-- @route.description "A test plan is a high-level document that outlines the overall approach to testing a software application. It serves as a blueprint for the testing process."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'PLAN NAME' AS markdown,
       1 AS search,
       1 AS sort;
-- SELECT
--   ${md.link(
--       "planid",
--       [
--         "'plancasedetails.sql?project_name='",
--         "project_name",
--         "'&id='",
--         "rownum","'&uniform_resource_id='","uniform_resource_id"
--       ]
--   )} AS "PLAN NAME"
-- FROM qf_role_with_plan
-- WHERE project_name = $project_name
-- ORDER BY planid;

with tblplansummary as (SELECT
    tbl.project_name,
    tbl.uniform_resource_id,
    tbl.rownum,
    tbl.planid,
   case when (select count(*) from qf_role_with_suite where project_name = tbl.project_name )>0 THEN  
   'SUITE'  
   else
   'CASE'
   end AS "PLAN_DETAILS"  
FROM qf_role_with_plan tbl)
select
case when PLAN_DETAILS='SUITE' THEN
    ${md.link(
      "planid",
      [
        "'plan-test-suite-cases.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )}
else
   ${md.link(
      "planid",
      [
        "'plancasedetails.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )}
end AS "PLAN NAME"
from tblplansummary
where project_name=$project_name;

```

```sql plancasedetails.sql { route: { caption: "Test Plan Details" } }

SELECT 'text' AS component,
$page_description AS contents_md;


SELECT 'table' AS component,
     
       'Test Case ID' AS markdown, 
        'Test Cases' AS title,   
       1 AS search,
       1 AS sort;
SELECT
  ${md.link(
      "tbl.testcaseid",
      [
        "'testcasedetails.sql?testcaseid='",
        "tbl.testcaseid",
        "'&project_name='",
        "$project_name"
      ]
  )} AS "Test Case ID",
  tbl.title
FROM qf_role_with_case tbl
WHERE tbl.uniform_resource_id = $uniform_resource_id
  AND tbl.project_name = $project_name
  AND tbl.rownum > CAST($id AS NUMERIC)  
  AND (
        CASE
          WHEN (
            SELECT MIN(rownum)
            FROM qf_role_with_suite
            WHERE uniform_resource_id = $uniform_resource_id
              AND rownum > CAST($id AS NUMERIC) AND tbl.project_name = $project_name
          ) IS NOT NULL
          THEN tbl.rownum < (
            SELECT MIN(rownum)
            FROM qf_role_with_suite
            WHERE uniform_resource_id = $uniform_resource_id
              AND rownum > CAST($id AS NUMERIC) AND tbl.project_name = $project_name
          )
          ELSE 1 = 1
        END
      );

   
```

```sql plan-test-suite-cases.sql { route: { caption: "Test suite" } }
-- @route.description "Test suite is a collection of test cases designed to verify the functionality, performance, and security of a software application. It ensures that the application meets the specified requirements by executing predefined tests across various scenarios, identifying defects, and validating that the system works as intended.."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'SUITE NAME' AS markdown,
       'Title' AS title,
       1 AS search,
       1 AS sort;
SELECT
  ${md.link(
      "suiteid",
      [
        "'suitecasedetails.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "SUITE NAME",
  title AS "Title"
FROM qf_role_with_suite
WHERE project_name = $project_name AND uniform_resource_id=$uniform_resource_id
ORDER BY suiteid;

```

```sql chart/pie-chart-autostatus.sql { route: { caption: "" } }
SELECT 'chart' AS component,
       'pie' AS type,
       'Test case execution type status' AS title,
       TRUE AS labels,
       'green' AS color,
       'red' AS color,
       'chart-left' AS class;
 
SELECT  
 
'AUTOMATION' AS label,
       COALESCE( test_case_percentage,0) AS value
FROM qf_case_execution_status_percentage  
where project_name =$project_name
 AND  UPPER(execution_type) = 'AUTOMATION'
 
 SELECT 'MANUAL' AS label,
       COALESCE( test_case_percentage ,0) AS value
FROM qf_case_execution_status_percentage where  project_name = $project_name
 AND  UPPER(execution_type) = 'MANUAL';
 ```

