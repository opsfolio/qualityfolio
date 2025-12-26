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

# **Core Test Management Tasks**

## **Run Playwright Tests**

### **Purpose:**

<!-- Execute all Playwright tests inside the `opsfolio` folder.

\`\`\`bash playwright-test -C PlaywrightTest --descr "Run Playwright
tests in the opsfolio folder" #!/usr/bin/env -S bash -->

# Navigate to the opsfolio directory

<!-- cd ../../../../opsfolio -->

## How To Run Tasks

# Run Playwright tests in the opsfolio folder

<!-- ```bash playwright-test -C PlaywrightTest --descr "Run Playwright tests in the opsfolio folder"
#!/usr/bin/env -S bash

# Navigate to the opsfolio directory
cd ../../../../opsfolio

# Installation and configuration
npm install
npx playwright install

# Run Playwright tests
npx playwright test


``` -->

# Surveilr Ingest Files

```bash ingest --descr "Ingest Files"
#!/usr/bin/env -S bash
# rm -rf resource-surveillance.sqlite.db
surveilr ingest files -r ./test-artifacts && surveilr orchestrate transform-markdown
```

# SQL query

```bash deploy -C --descr "Generate sqlpage_files table upsert SQL and push them to SQLite"
cat qualityfolio-json-etl.sql | sqlite3 resource-surveillance.sqlite.db
```

```bash prepare-sqlpage-dev --descr "Generate the dev-src.auto directory to work in SQLPage dev mode"
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json
```

# SQL Page

```sql PARTIAL global-layout.sql --inject *.sql*
SELECT 'shell' AS component,
       NULL AS icon,
      --  'https://www.surveilr.com/assets/brand/qf-logo.png' AS favicon,
       'https://www.surveilr.com/assets/brand/qf-logo.png' AS image,
       'fluid' AS layout,
       true AS fixed_top_menu,
       'index.sql' AS link,
       '{"link":"/index.sql"}' AS menu_item;

${ctx.breadcrumbs()}

select
    'divider'            as component,
    'QA Progress & Performance Dashboard' as contents,
    5                  as size,
    'blue'               as color;

```

```sql index.sql { route: { caption: "Home Page" } }

SELECT
  'text' AS component,
  'The dashboard provides a centralized view of your testing efforts, displaying key metrics such as test progress, results, and team productivity. It offers visual insights with charts and reports, enabling efficient tracking of test runs, milestones, and issue trends, ensuring streamlined collaboration and enhanced test management throughout the project lifecycle' AS contents;

SELECT
    'card' AS component,
    4 AS columns;

SELECT
  '## Test Case Count' AS description_md,
  '# ' || COALESCE(SUM(test_case_count), 0) AS description_md,
  'green-lt' AS background_color,
  'file' AS icon,
  'test-cases.sql' AS link
FROM v_section_hierarchy_summary;

-- Second Card V2: Total Passed
SELECT
    '## Total Passed Cases:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'green-lt' AS background_color,
    'check' AS icon,
    'passed.sql' AS link
FROM v_test_case_details
WHERE test_case_status IN ('passed','pending');

-- Second Card: Total Defects
SELECT
    '## Total Defects:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'red-lt' AS background_color,
    'bug' AS icon,
    'defects.sql' AS link
FROM v_test_case_details
WHERE test_case_status IN ('reopen', 'failed');

-- Closed Defects
SELECT
    '## Closed Defects:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'blue-lt' AS background_color,
    'x' AS icon,
    'closed.sql' AS link
FROM v_test_case_details
WHERE test_case_status IN ('closed');


SELECT
    '## Reopened Defects:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'yellow-lt' AS background_color,
    'alert-circle' AS icon,
    'reopen.sql' AS link
FROM v_test_case_details
WHERE test_case_status IN ('reopen');

WITH counts AS (
  SELECT
    (SELECT COUNT(DISTINCT test_case_id) FROM v_test_case_details) AS total_tests,
    (SELECT COUNT(DISTINCT test_case_id)
       FROM v_test_case_details
      WHERE test_case_status IN ('reopen','failed')
    ) AS total_defects
)
SELECT
  '## Failed Percentage:' AS description_md,
  '# ' ||
  CASE
    WHEN total_tests = 0 THEN '0%'
    ELSE ROUND((total_defects * 100.0) / total_tests) || '%'
  END AS description_md,
  'red-lt' AS background_color,
  'alert-circle' AS icon
FROM counts;

WITH counts AS (
  SELECT
    (SELECT COUNT(DISTINCT test_case_id) FROM v_test_case_details) AS total_tests,
    (SELECT COUNT(DISTINCT test_case_id)
       FROM v_test_case_details
      WHERE test_case_status IN ('reopen','failed')
    ) AS total_defects
)
SELECT
  '## Success Percentage:' AS description_md,
  '# ' ||
  CASE
    WHEN total_tests = 0 THEN '0%'
    ELSE ROUND(((total_tests - total_defects) * 100.0) / total_tests) || '%'
  END AS description_md,
  'green-lt' AS background_color,
  'check' AS icon
FROM counts;

select
    'divider'            as component,
    'Comprehensive Test Status' as contents,
    5                  as size,
    'blue'               as color;


select
    'card' as component,
    2      as columns;
select
    '/chart/pie-chart-left.sql?color=green&n=42&_sqlpage_embed' as embed;
select
    '/chart/pie-chart-left.sql?_sqlpage_embed' as embed;

select
    'divider'            as component,
    'ASSIGNEE WISE TEST CASE DETAILS' as contents,
    5                  as size,
    'blue'               as color;

SELECT 'form' AS component,
'Submit' as validate,
'true' as auto_submit ;

SELECT
    'assignee' AS name,
    'true' as autofocus,
    'Assignee' AS label,
    'select'   AS type,
    (
        SELECT assignee
        FROM v_test_assignee
        WHERE assignee = :assignee
    ) AS value,
    json_group_array(
        json_object('label', assignee, 'value', assignee)
    ) AS options
FROM v_test_assignee;

${paginate("v_test_assignee ")}
SELECT
  'table' AS component,
  "TOTAL TEST CASES" AS markdown,
  "TOTAL PASSED" AS markdown,
  "TOTAL FAILED" AS markdown,
  "TOTAL REOPEN" AS markdown,
  "TOTAL CLOSED" AS markdown,
  -- "CYCLE" AS markdown,
  "ASSIGNEE" AS markdown,
  1 AS search,
  1 AS sort;

SELECT
    latest_assignee AS "ASSIGNEE",

    ${md.link(
        "COUNT(test_case_id)",
        [`'assigneetotaltestcase.sql?assignee='`, "latest_assignee"]
    )} AS "TOTAL TEST CASES",

    ${md.link(
        "SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END)",
        [`'assigneetotalpassed.sql?assignee='`, "latest_assignee"]
    )} AS "TOTAL PASSED",

    ${md.link(
        "SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END)",
        [`'assigneetotalfailed.sql?assignee='`, "latest_assignee"]
    )} AS "TOTAL FAILED",

    ${md.link(
        "SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END)",
        [`'assigneetotalreopen.sql?assignee='`, "latest_assignee"]
    )} AS "TOTAL REOPEN",

    ${md.link(
        "SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END)",
        [`'assigneetotalclosed.sql?assignee='`, "latest_assignee"]
    )} AS "TOTAL CLOSED"

FROM v_test_case_details
WHERE
  CASE
    WHEN :assignee IS NULL THEN 1=1
    WHEN :assignee = 'ALL' THEN 1=1
    ELSE latest_assignee = :assignee
  END
GROUP BY latest_assignee
${pagination.limit};
${pagination.navigation}

select
'divider' as component,
'TEST CYCLE DETAILS' as contents,
5 as size,
'blue' as color;

select
    'button' as component,
      'end' as justify;
select
    '/test-case-history.sql' as link,
    'Test Case History'            as title,'blue' as color;

-- SELECT
-- 'table' AS component,
-- -- "CYCLE" AS markdown,
-- "TOTAL TEST CASES" AS markdown,
-- "TOTAL PASSED" AS markdown,
-- "TOTAL FAILED" AS markdown,
-- "TOTAL RE-OPEN" AS markdown,
-- "TOTAL CLOSED" AS markdown,

-- 1 AS sort,
-- 1 AS search;

-- SELECT
-- -- '[' || latest_cycle || '](test-cases.sql?cycle=' || latest_cycle || ')' AS "CYCLE",
-- latest_cycle AS "CYCLE",
-- '[' || COUNT(test_case_id) || '](cycletotaltestcase.sql?' ||'cycle=' || latest_cycle || ')' AS "TOTAL TEST CASES",
-- '[' || SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END) || '](cycletotalpassed.sql?' ||'cycle=' || latest_cycle || ')' AS "TOTAL PASSED",
-- '[' || SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END) || '](cycletotalfailed.sql?' ||'cycle=' || latest_cycle || ')' AS "TOTAL FAILED",
-- '[' || SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END) || '](cycletotalreopen.sql?' ||'cycle=' || latest_cycle || ')' AS "TOTAL RE-OPEN",
-- '[' || SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END) || '](cycletotalclosed.sql?' ||'cycle=' || latest_cycle || ')' AS "TOTAL CLOSED"

-- FROM
-- v_test_case_details
-- GROUP BY
-- latest_cycle;

SELECT
'table' AS component,
"CYCLE" AS markdown,
"TOTAL TEST CASES" AS markdown,
"TOTAL PASSED" AS markdown,
"TOTAL FAILED" AS markdown,
"TOTAL RE-OPEN" AS markdown,
"TOTAL CLOSED" AS markdown,
1 AS sort,
1 AS search;
 
SELECT
    latest_cycle AS "CYCLE",
 
    '[' || test_count || '](cycletotaltestcase.sql?cycle=' || latest_cycle || ')'
        AS "TOTAL TEST CASES",
 
    '[' || passed_count || '](cycletotalpassed.sql?cycle=' || latest_cycle || ')'
        AS "TOTAL PASSED",
 
    '[' || failed_count || '](cycletotalfailed.sql?cycle=' || latest_cycle || ')'
        AS "TOTAL FAILED",
 
    '[' || reopen_count || '](cycletotalreopen.sql?cycle=' || latest_cycle || ')'
        AS "TOTAL RE-OPEN",
 
    '[' || closed_count || '](cycletotalclosed.sql?cycle=' || latest_cycle || ')'
        AS "TOTAL CLOSED"
 
FROM v_latest_ingested_cycle_summary;

-- REQUIREMENT

select
'divider' as component,
'REQUIREMENT TRACEABILITY' as contents,
5 as size,
'blue' as color;

${paginate("v_test_case_details", "GROUP BY  requirement_ID")}
SELECT
'table' AS component,
"TOTAL TEST CASES" AS markdown,
"TOTAL PASSED" AS markdown,
"TOTAL FAILED" AS markdown,
"TOTAL RE-OPEN" AS markdown,
"TOTAL CLOSED" AS markdown,
1 AS sort,
1 AS search;

SELECT
-- '[' || requirementID || '](test-cases.sql?cycle=' || requirementID || ')' AS "REQUIREMENTS",
requirement_ID AS "REQUIREMENTS",
'[' || COUNT(test_case_id) || '](requirementtotaltestcase.sql?'||'req=' || requirement_ID || ')' AS "TOTAL TEST CASES",
'[' || SUM(CASE WHEN test_case_status = 'passed' THEN 1 ELSE 0 END) || '](requirementpassedtestcase.sql?' ||'req=' || requirement_ID || ')' AS "TOTAL PASSED",
'[' || SUM(CASE WHEN test_case_status = 'failed' THEN 1 ELSE 0 END) || '](requirementfailedtestcase.sql?' ||'req=' || requirement_ID || ')' AS "TOTAL FAILED",
'[' || SUM(CASE WHEN test_case_status = 'reopen' THEN 1 ELSE 0 END) || '](requirementreopentestcase.sql?' ||'req=' || requirement_ID || ')' AS "TOTAL RE-OPEN",
'[' || SUM(CASE WHEN test_case_status = 'closed' THEN 1 ELSE 0 END) || '](requirementclosedtestcase.sql?' ||'req=' || requirement_ID || ')' AS "TOTAL CLOSED"

FROM
v_test_case_details
GROUP BY
requirement_ID
${pagination.limit};
${pagination.navigation}

select
'divider' as component,
'OPEN ISSUES' as contents,
5 as size,
'blue' as color;

SELECT
'table' AS component,
1 AS sort,
1 AS search;

SELECT
  issue_id    AS "Issue ID",
  test_case_id AS "Test Case ID",
  test_case_description AS "Description",
  created_date    AS "Created Date",
  total_days    AS "Issue Age"

FROM v_open_issues_age
ORDER BY test_case_id;
```

```sql test-cases.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  1 AS search,
  1 AS sort;

SELECT
  test_case_id     AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM v_test_case_details
ORDER BY test_case_id;

```

```sql passed.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  1 AS search,
  1 AS sort;

SELECT
  test_case_id     AS "Test Case ID",
  test_case_title  AS "Title",
  latest_cycle     AS "Latest Cycle"
FROM v_test_case_details
WHERE test_case_status='passed'
ORDER BY test_case_id;

```

```sql defects.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  1 AS search,
  1 AS sort;

SELECT
  test_case_id     AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM v_test_case_details
WHERE test_case_status IN ('reopen', 'failed')
ORDER BY test_case_id;

```

```sql closed.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  1 AS search,
  1 AS sort;

SELECT
  test_case_id     AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM v_test_case_details
WHERE test_case_status IN ('closed')
ORDER BY test_case_id;

```

```sql reopen.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  1 AS search,
  1 AS sort;

SELECT
  test_case_id     AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM v_test_case_details
WHERE test_case_status IN ('reopen')
ORDER BY test_case_id;

```

```sql cycletotaltestcase.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Case ID' as markdown,
  'Test Cases' AS title,
  1 AS search,
  1 AS sort;

SELECT
   '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_cycle = $cycle
ORDER BY
  test_case_id;

```

```sql cycletotalpassed.sql { route: { caption: "Test Passed" } }

SELECT
  'table' AS component, 
  'Test Cases' AS title,
   'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_cycle = $cycle
  and test_case_status='passed'
ORDER BY
  test_case_id;

```

```sql cycletotalfailed.sql { route: { caption: "Test Passed" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
 '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_cycle = $cycle
  and test_case_status='failed'
ORDER BY
  test_case_id;

```

```sql cycletotalreopen.sql { route: { caption: "Test Passed" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_cycle = $cycle
  and test_case_status='reopen'
ORDER BY
  test_case_id;

```

```sql cycletotalclosed.sql { route: { caption: "Test Passed" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
 '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_cycle = $cycle
  and test_case_status='closed'
ORDER BY
  test_case_id;


```

```sql requirementtotaltestcase.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle",
  requirement_ID    AS "Requirement"

FROM
  v_test_case_details
WHERE
  requirement_ID = $req
ORDER BY
  test_case_id;

```

```sql requirementpassedtestcase.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle",
  requirement_ID    AS "Requirement"

FROM
  v_test_case_details
WHERE
  requirement_ID = $req
  and test_case_status='passed'
ORDER BY
  test_case_id;

```

```sql requirementfailedtestcase.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle",
  requirement_ID    AS "Requirement"

FROM
  v_test_case_details
WHERE
  requirement_ID = $req
  and test_case_status='failed'
ORDER BY
  test_case_id;

```

```sql requirementreopentestcase.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle",
  requirement_ID    AS "Requirement"

FROM
  v_test_case_details
WHERE
  requirement_ID = $req
  and test_case_status='reopen'
ORDER BY
  test_case_id;

```

```sql requirementclosedtestcase.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle",
  requirement_ID    AS "Requirement"

FROM
  v_test_case_details
WHERE
  requirement_ID = $req
  and test_case_status='closed'
ORDER BY
  test_case_id;

```

```sql chart/pie-chart-left.sql { route: { caption: "" } }
SELECT
'chart' AS component,
'pie' AS type,
TRUE AS labels,
'green' as color,
'red' as color,
'chart-left' AS class;

select
'Passed' as label,
success_percentage as value
from v_success_percentage;

select
'Failed' as label,
failed_percentage as value
from v_success_percentage;
```

```sql chart/pie-chart-right.sql { route: { caption: "" } }
SELECT
'chart' AS component,
'pie' AS type,
TRUE AS labels,
'green' as color,
'red' as color,
'chart-left' AS class;

select
'Passed' as label,
success_percentage as value
from v_success_percentage;

select
'Failed' as label,
failed_percentage as value
from v_success_percentage;
```

```sql assigneetotaltestcase.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
  'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;
 
SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_assignee = $assignee
ORDER BY
  test_case_id;

```

```sql assigneetotalpassed.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
   'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_assignee = $assignee
  and test_case_status='passed'
ORDER BY
  test_case_id;

```

```sql assigneetotalfailed.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
   'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_assignee = $assignee
  and test_case_status='failed'
ORDER BY
  test_case_id;

```

```sql assigneetotalreopen.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
   'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_assignee = $assignee
  and test_case_status='reopen'
ORDER BY
  test_case_id;

```

```sql assigneetotalreopen.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
   'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_assignee = $assignee
  and test_case_status='reopen'
ORDER BY
  test_case_id;

```

```sql assigneetotalclosed.sql { route: { caption: "Test Cases" } }

SELECT
  'table' AS component,
  'Test Cases' AS title,
   'Test Case ID' as markdown,
  1 AS search,
  1 AS sort;

SELECT
  '[' ||  test_case_id || '](testcasedetails.sql?'||'testcaseid=' || test_case_id || ')' AS "Test Case ID",
  test_case_title  AS "Title",
  test_case_status AS "Status",
  latest_cycle     AS "Latest Cycle"
FROM
  v_test_case_details
WHERE
  latest_assignee = $assignee
  and test_case_status='closed'
ORDER BY
  test_case_id;

```

```sql test-case-history.sql { route: { caption: "Test Case History" } }


-- Calendar filter card


SELECT
  'table' AS component,
  'CYCLE' AS markdown,
  'TOTAL TEST CASES' AS markdown,
  'TOTAL PASSED' AS markdown,
  'TOTAL FAILED' AS markdown,
  'TOTAL RE-OPEN' AS markdown,
  'TOTAL CLOSED' AS markdown,

  1 AS sort,
  1 AS search;

SELECT
    latest_cycle AS "CYCLE",

    -- ALL test cases for this cycle (with date parameters)
    '[' || COUNT(test_case_id) || ']' ||
    '(cycletotaltestcase.sql?cycle=' || latest_cycle ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')'
    AS "TOTAL TEST CASES",

    -- PASSED (with date parameters)
    '[' || SUM(CASE WHEN status = 'passed' THEN 1 ELSE 0 END) || ']' ||
    '(results.sql?cycle=' || latest_cycle || '&status=passed' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')'
    AS "TOTAL PASSED",

    -- FAILED (with date parameters)
    '[' || SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) || ']' ||
    '(results.sql?cycle=' || latest_cycle || '&status=failed' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')'
    AS "TOTAL FAILED",

    -- REOPEN (with date parameters)
    '[' || SUM(CASE WHEN status = 'reopen' THEN 1 ELSE 0 END) || ']' ||
    '(results.sql?cycle=' || latest_cycle || '&status=reopen' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')'
    AS "TOTAL RE-OPEN",

    -- CLOSED (with date parameters)
    '[' || SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) || ']' ||
    '(results.sql?cycle=' || latest_cycle || '&status=closed' ||
    CASE WHEN :from_date IS NOT NULL AND :to_date IS NOT NULL
         THEN '&from_date=' || :from_date || '&to_date=' || :to_date
         ELSE '' END || ')'
    AS "TOTAL CLOSED",

    cycle_date AS "CYCLE DATE CREATED"

FROM v_evidence_history_complete

GROUP BY latest_cycle, cycle_date
ORDER BY latest_cycle DESC;
```

```sql results.sql { route: { caption: "Test cases" } }
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
SELECT
  'table' AS component,
  'Test Cases Details' AS title,
  1 AS search,
  1 AS sort;

SELECT
  test_case_id     AS "Test Case ID",
  test_case_title  AS "Title",
  status AS "Status",
  latest_cycle     AS "Latest Cycle",
   cycle_date AS "created date"
FROM
  v_evidence_history_complete
WHERE
  latest_cycle = $cycle
  and status= $status
 and
    CASE
      WHEN :from_date IS NULL OR :to_date IS NULL THEN 1=1
      ELSE date(cycle_date) BETWEEN date(:from_date) AND date(:to_date)
    END
ORDER BY
  test_case_id;

```


```sql testcasedetails.sql { route: { caption: "Test Cases Details" } }

SELECT 'card' AS component,
       'Test Cases Details' AS title,
       1 AS columns;

SELECT
    'Test Case ID: ' || test_case_id AS title,
    '**Description:** ' || description || '  
  
' ||
    '**Preconditions:**  
  
' ||
    (
      SELECT group_concat(
               (CAST(j.key AS INTEGER) + 1) || '. ' ||
               json_extract(j.value, '$.item[0].paragraph'),
               char(10)
             )
      FROM json_each(preconditions) AS j
    ) || '  
  
' ||
    '**Steps:**  
  
' ||
    (
      SELECT group_concat(
               (CAST(j.key AS INTEGER) + 1) || '. ' ||
               json_extract(j.value, '$.item[0].paragraph'),
               char(10)
             )
      FROM json_each(steps) AS j
    ) || '  
  
' ||
    '**Expected Results:**  
  
' ||
    (
      SELECT group_concat(
               (CAST(j.key AS INTEGER) + 1) || '. ' ||
               json_extract(j.value, '$.item[0].paragraph'),
               char(10)
             )
      FROM json_each(expected_results) AS j
    )
    AS description_md
FROM v_case_summary
WHERE test_case_id = $testcaseid
ORDER BY test_case_id;


```