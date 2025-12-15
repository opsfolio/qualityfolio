---
sqlpage-conf:
  database_url: "sqlite://resource-surveillance.sqlite.db?mode=rwc"
  web_root: "./dev-src.auto"
  allow_exec: true
  port: "9227"
---

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

Execute all Playwright tests inside the `opsfolio` folder.

\`\`\`bash playwright-test -C PlaywrightTest --descr "Run Playwright
tests in the opsfolio folder" #!/usr/bin/env -S bash

# Navigate to the opsfolio directory

cd ../../../../opsfolio

## How To Run Tasks

<!-- # Run Playwright tests in the opsfolio folder

```bash playwright-test -C PlaywrightTest --descr "Run Playwright tests in the opsfolio folder"
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
rm -rf resource-surveillance.sqlite.db
surveilr ingest files -r ../test-artifacts && surveilr orchestrate transform-markdown
```

# SQL query

```bash deploy -C --descr "Generate sqlpage_files table upsert SQL and push them to SQLite"
cat qualityfolio-json-etl.sql | sqlite3 resource-surveillance.sqlite.db
```

```bash prepare-sqlpage-dev --descr "Generate the dev-src.auto directory to work in SQLPage dev mode"
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json
```

# SQL Page

```sql PARTIAL global-layout.sql --inject **/*
-- BEGIN: PARTIAL global-layout.sql
SELECT 'shell' AS component,
       NULL AS icon,
       'https://www.surveilr.com/assets/brand/qf-logo.png' AS favicon,
       'https://www.surveilr.com/assets/brand/qf-logo.png' AS image,
       'fluid' AS layout,
       true AS fixed_top_menu,
       'index.sql' AS link,
       '{"link":"/index.sql","title":"QA Progress & Performance Dashboard"}' AS menu_item;

${ctx.breadcrumbs()}

-- END: PARTIAL global-layout.sql
-- this is the `${cell.info}` cell on line ${cell.startLine}
```

```sql index.sql { route: { caption: "Home Page" } }

SELECT
  'table' AS component;
SELECT 'The dashboard provides a centralized view of your testing efforts, displaying key metrics such as test progress, results, and team productivity. It offers visual insights with charts and reports, enabling efficient tracking of test runs, milestones, and issue trends, ensuring streamlined collaboration and enhanced test management throughout the project lifecycle.
 ' AS "QA Progress & Performance Dashboard" ;

SELECT
    'card' AS component,
    4 AS columns;

-- First Card: Test Case Count
SELECT
    '## Test Case Count:'  AS description_md,
    '# ' || COALESCE(test_case_count, 0) AS description_md,
    'green-lt' AS background_color,
    'file' AS icon
FROM v_section_hierarchy_summary LIMIT 1;

-- Second Card V2: Total Passed
SELECT
    '## Total Passed Cases:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'green-lt' AS background_color,
    'check' AS icon
FROM v_test_case_details
WHERE test_case_status IN ('passed');

-- Second Card: Total Defects
SELECT
    '## Total Defects:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'red-lt' AS background_color,
    'bug' AS icon
FROM v_test_case_details
WHERE test_case_status IN ('reopen', 'failed');



-- Closed Defects
SELECT
    '## Closed Defects:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'blue-lt' AS background_color,
    'x' AS icon
FROM v_test_case_details
WHERE test_case_status IN ('closed');

-- Third Card: Reopened Defects
SELECT
    '## Reopened Defects:'  AS description_md,
    '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
    'yellow-lt' AS background_color,
    'alert-circle' AS icon
FROM v_test_case_details
WHERE test_case_status IN ('reopen');

WITH counts AS (
    SELECT
        COALESCE(test_case_count, 0) AS test_case_count,
        COALESCE(COUNT(test_case_id), 0) AS total_defects
    FROM v_section_hierarchy_summary, v_test_case_details
    WHERE test_case_status IN ('reopen', 'failed')
    LIMIT 1
)
SELECT
    '## Failed Percentage:' AS description_md,
    '# ' ||
    CASE
        WHEN test_case_count = 0 THEN '0%'  -- If no test cases, return 0%
        WHEN total_defects = 0 THEN '0%'    -- If no defects, return 0%
        ELSE
            ROUND((total_defects * 100.0) / test_case_count) || '%'  -- Calculate and round to 2 decimal places
    END AS description_md,
    'red-lt' AS background_color,
      'alert-circle' AS icon
FROM counts;

WITH counts AS (
    SELECT
        COALESCE(test_case_count, 0) AS test_case_count,
        COALESCE(COUNT(test_case_id), 0) AS total_defects
    FROM v_section_hierarchy_summary, v_test_case_details
    WHERE test_case_status IN ('reopen', 'failed')
    LIMIT 1
)

SELECT
    '## Success Percentage:' AS description_md,
    '# ' ||
    CASE
        WHEN test_case_count = 0 THEN '0%'  -- If no test cases, return 0%
        ELSE
            ROUND(((test_case_count - total_defects) * 100.0) / test_case_count) || '%'  -- Calculate and round to 2 decimal places
    END AS description_md,
    'green-lt' AS background_color,
    'check' AS icon
FROM counts;


```
