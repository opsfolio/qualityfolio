---
sqlpage-conf:
  database_url: "${DATABASE_URL}"
  web_root: "${WEB_ROOT}"
  allow_exec: ${ALLOW_EXEC}
  port: "${PORT}"
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
       '/style.css' as css;
   
SET resource_json = sqlpage.read_file_as_text('spry.d/auto/resource/${path}.auto.json');
SET page_title  = json_extract($resource_json, '$.route.caption');
SET page_description  = json_extract($resource_json, '$.route.description');
SET page_path = json_extract($resource_json, '$.route.path');

${ctx.breadcrumbs()}

```

---
```contribute sqlpage_files --base .
./style.css .
```
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
    FROM qf_evidence_status 
    WHERE project_name IS NOT NULL AND project_name <> ''
);

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
       'green-lt' AS background_color,
       'file' AS icon,      
       'test-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_title, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_count
WHERE 
  project_title = :project_name;

-- Passed Cases
SELECT '## Total Passed Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'green-lt' AS background_color,
       'check' AS icon,
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
       'red-lt' AS background_color,
       'alert-circle' AS icon
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
       'green-lt' AS background_color,
       'check' AS icon
FROM counts;

-- Open Defects
SELECT '## Open Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'yellow-lt' AS background_color,
       'alert-circle' AS icon,
       'open.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status = 'failed'
  AND project_name = :project_name;

-- Reopened Defects
SELECT '## Reopened Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'yellow-lt' AS background_color,
       'alert-circle' AS icon,
       'reopen.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status = 'reopen'
  AND project_name = :project_name;

-- Total Defects
SELECT '## Total Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'red-lt' AS background_color,
       'bug' AS icon,
       'defects.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status IN ('reopen', 'failed')
  AND project_name =:project_name;

-- Closed Defects
SELECT '## Closed Defects' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'blue-lt' AS background_color,
       'x' AS icon,
       'closed.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status = 'closed'
  AND project_name = :project_name;

-- Todo Test cases
SELECT '## Todo Test cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'red-lt' AS background_color,
       'alert-circle' AS icon,
       'todo-cycle.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '')), ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE test_case_status IN ('pending','')
  AND project_name = :project_name;

-- Non assigned test cases
SELECT '## Non Assigned Test cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'red-lt' AS background_color,
       'alert-circle' AS icon,
       'non-assigned-test-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '')), ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE (latest_assignee IS NULL OR latest_assignee = '')
  AND project_name = :project_name;

  -- Automation percentage
 



  
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

SELECT '/chart/chart.sql?project_name=' || :project_name AS embed;
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
    SELECT DISTINCT assignee AS label_text,
           assignee AS value_text,
           1 AS sort_order
    FROM qf_assignee_master
    WHERE assignee <> ''
      AND assignee IN (
          SELECT DISTINCT latest_assignee
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
      )
   
    ORDER BY sort_order, label_text
);

${paginate("qf_assignee_master")}

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
        ["'cycletotaltestcase.sql?cycle='", "cycle"])} AS "CYCLE",  
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
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL TEST CASES",
    ${md.link("SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=passed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL PASSED",
    ${md.link("SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=failed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL FAILED",
    ${md.link("SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=reopen&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL RE-OPEN",
    ${md.link("SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END)",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=closed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL CLOSED"
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
WHERE project_name = CASE 
      WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '') = 1 
      THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> ''))
      ELSE :project_name
  END
  AND (
      (SELECT COUNT(DISTINCT project_name) FROM qf_evidence_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
      OR (:project_name IS NOT NULL AND :project_name <> '')
  )
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
    '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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
 
SELECT '[' || tbl1.testcaseid || '](testcasedetails.sql?testcaseid=' || tbl1.testcaseid || ')' AS "Test Case ID",
       tbl2.title  AS "Title",
       tbl1.status AS "Status",
       tbl1.cycle AS "Latest Cycle"
FROM qf_role_with_evidence tbl1
inner join qf_role_with_case tbl2
on tbl1.testcaseid=tbl2.testcaseid
and tbl1.uniform_resource_id=tbl2.uniform_resource_id
WHERE ($cycle IS NULL OR tbl1.cycle = $cycle)
  AND ($status IS NULL OR tbl1.status = $status)
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

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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

SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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
  'get'     AS method,
  'Submit'  AS validate;

-- From date (retains value after submission)
SELECT
  'from_date'  AS name,
  'From date'  AS label,
  'date'       AS type,
  $from_date AS value;

-- To date (retains value after submission)
SELECT
  'to_date'    AS name,
  'To date'    AS label,
  'date'       AS type,
  $to_date AS value;
SELECT 'table' AS component,
       'CYCLE' AS markdown,
       'TOTAL TEST CASES' AS markdown,
       'TOTAL PASSED' AS markdown,
       'TOTAL FAILED' AS markdown,
       'TOTAL RE-OPEN' AS markdown,
       'TOTAL CLOSED' AS markdown,
       1 AS sort,
       1 AS search;
 
SELECT latest_cycle AS "CYCLE",
    '[' || COUNT(test_case_id) || '](cycletotaltestcase.sql?cycle=' || latest_cycle ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')' AS "TOTAL TEST CASES",
    '[' || SUM(CASE WHEN status = 'passed' THEN 1 ELSE 0 END) || '](cycletotaltestcase.sql?cycle=' || latest_cycle || '&status=passed' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')' AS "TOTAL PASSED",
    '[' || SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) || '](cycletotaltestcase.sql?cycle=' || latest_cycle || '&status=failed' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')' AS "TOTAL FAILED",
    '[' || SUM(CASE WHEN status = 'reopen' THEN 1 ELSE 0 END) || '](cycletotaltestcase.sql?cycle=' || latest_cycle || '&status=reopen' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')' AS "TOTAL RE-OPEN",
    '[' || SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) || '](cycletotaltestcase.sql?cycle=' || latest_cycle || '&status=closed' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')' AS "TOTAL CLOSED",
    cycle_date AS "CYCLE DATE CREATED"
FROM qf_evidence_history_all
WHERE latest_cycle != ''
 
AND (
      ($from_date IS NULL OR $from_date = '')
  AND ($to_date   IS NULL OR $to_date   = '')
   OR (
        DATE(
          SUBSTR(cycle_date, 7, 4) || '-' ||
          SUBSTR(cycle_date, 1, 2) || '-' ||
          SUBSTR(cycle_date, 4, 2)
        )
        BETWEEN DATE($from_date) AND DATE($to_date)
      )
)
GROUP BY ingestion_timestamp, latest_cycle, cycle_date
ORDER BY ingestion_timestamp DESC, latest_cycle DESC;
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
FROM qf_case_master
WHERE test_case_id = $testcaseid
ORDER BY test_case_id;
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
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee"])} AS "TOTAL TEST CASES",
    ${md.link("SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=passed'"])} AS "TOTAL PASSED",
    ${md.link("SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=failed'"])} AS "TOTAL FAILED",
    ${md.link("SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=reopen'"])} AS "TOTAL REOPEN",
    ${md.link("SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee", "'&status=closed'"])} AS "TOTAL CLOSED"
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
 
SELECT '[' || test_case_id || '](testcasedetails.sql?testcaseid=' || test_case_id || ')' AS "Test Case ID",
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
       "TOTAL PENDING/EMPTY" AS markdown,
       1 AS sort,
       1 AS search;

SELECT
  latest_cycle,
  
  ${md.link("COUNT(test_case_id)",
      ["'todo-test-cases.sql?project_name='","project_name"])} AS "TOTAL PENDING/EMPTY"
   
FROM qf_case_status 
WHERE (test_case_status = 'pending' OR test_case_status = '' OR test_case_status IS NULL)
  AND project_name = $project_name

GROUP BY latest_cycle



```
