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

# Surveilr Singer Tap Ingestion

```bash singer --descr "Singer Tap Ingestion"
#!/usr/bin/env -S bash
set -euo pipefail

# Load .env if present (supports simple KEY=VALUE lines)
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

required=(GITHUB_ACCESS_TOKEN GITHUB_REPOSITORY GITHUB_START_DATE)
missing=()
for v in "${required[@]}"; do
  [[ -n "${!v:-}" ]] || missing+=("$v")
done

if (( ${#missing[@]} > 0 )); then
  # echo "SKIP: Singer Tap Ingestion (missing env: ${missing[*]})"
  exit 0
fi
chmod +x github.surveilr[singer].py
surveilr ingest files -r "github.surveilr[singer].py"
surveilr orchestrate adapt-singer --stream-prefix github
```

# SQL query

```bash deploy -C --descr "Generate sqlpage_files table upsert SQL and push them to SQLite"
surveilr shell qualityfolio-json-etl.sql
```

```bash deploy-sqlpage --descr "Generate the dev-src.auto directory to work in SQLPage dev mode"
spry sp spc --package --conf sqlpage/sqlpage.json -m qualityfolio.md | sqlite3 resource-surveillance.sqlite.db
```

```bash destroy-devsrc --descr "Destroy the dev-src.auto directory"
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md
```

```contribute sqlpage_files --base .
./index.bbd2bbc9.js .
```

# Qualityfolio

```sql PARTIAL global-layout.sql --inject *.sql*

SELECT 'shell' AS component,
       'Qualityfolio' AS title,
       NULL AS icon,
       'https://qualityfolio.dev/_astro/qualityfolio-logo.CiYk51BF.png' AS favicon,
       'https://qualityfolio.dev/_astro/qualityfolio-logo.CiYk51BF.png' AS image,
       'fluid' AS layout,
       true AS fixed_top_menu,
       'index.sql' AS link,
       '/index.bbd2bbc9.js' AS javascript,
       '© 2026 Qualityfolio. Test assurance as living Markdown.' AS footer;

SET resource_json = sqlpage.read_file_as_text('spry.d/auto/resource/${path}.auto.json');
SET page_title  = json_extract($resource_json, '$.route.caption');
SET page_description  = json_extract($resource_json, '$.route.description');
SET page_path = json_extract($resource_json, '$.route.path');

SELECT 'html' AS component;
SELECT '<style>
  #sqlpage_header .navbar .fs-2 { display: none !important; }
  .apexcharts-legend-series { pointer-events: none !important; }
</style>' AS html;

SELECT 'html' AS component;
SELECT'
<div style="
  position: fixed;
  top: 12px;
  right: 20px;
  z-index: 9999;
  font-family: inherit;
">
  <details style="position: relative;">
    <summary style="
      list-style: none;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 8px 14px;
      border: 1px solid #bdbb66;
      border-radius: 10px;
      background: rgb(255, 255, 255);
      font-weight: 600;
    ">
      <span style="
        width: 34px;
        height: 34px;
        border-radius: 50%;
        background: #2f10a0;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
      ">
        ' || substr(
              COALESCE(
                sqlpage.user_info('name'),
                sqlpage.user_info('email'),
                'U'
              ),
              1, 2
            ) || '
      </span>

      <span>' || COALESCE(
        sqlpage.user_info('name'),
        sqlpage.user_info('email'),
        'User'
      ) || '</span>

      <span style="opacity:0.6;">▾</span>
    </summary>

    <div style="
      position: absolute;
      right: 0;
      margin-top: 8px;
      background: white;
      border: 1px solid #e5e7eb;
      border-radius: 10px;
      min-width: 160px;
      box-shadow: 0 10px 25px rgba(0,0,0,.15);
      overflow: hidden;
    ">
      <a href="' || sqlpage.oidc_logout_url() || '"
         style="
           display: block;
           padding: 10px 14px;
           color: #dc2626;
           text-decoration: none;
           font-weight: 600;
         ">
        ⎋ Logout
      </a>
    </div>
  </details>
</div>
' AS html;

SET resource_json = sqlpage.read_file_as_text('spry.d/auto/resource/${path}.auto.json');
SET page_title  = json_extract($resource_json, '$.route.caption');
SET page_description  = json_extract($resource_json, '$.route.description');
SET page_path = json_extract($resource_json, '$.route.path');

${ctx.breadcrumbs()}

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
    FROM qf_case_status
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
    WHERE (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') > 1

    UNION ALL

    SELECT DISTINCT project_name AS label_text,
           project_name AS value_text,
           1 AS sort_order
    FROM qf_case_status
    WHERE project_name IS NOT NULL AND project_name <> ''

    ORDER BY sort_order, label_text
);


-- Metrics Cards
SELECT 'card' AS component, 4 AS columns;

-- Total Test Cases
SELECT '## Total Test Case Count' AS description_md,
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
        'green' AS color,
       'passed.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status_tap
WHERE LOWER(test_case_status) IN ('passed', 'ok')
  AND
  project_name = :project_name;

-- Failed Cases
SELECT '## Total Failed Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'details-off' AS icon,
        'red' AS color,
       'failed.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status_tap
WHERE LOWER(test_case_status) IN ('failed', 'not ok')
  AND
  project_name = :project_name;

-- Closed Cases
SELECT '## Total Closed Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'circle-check' AS icon,
       'purple' AS color,
       'closed-test-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status_tap
WHERE LOWER(test_case_status) = 'closed'
  AND project_name = :project_name;

-- Failed Percentage
WITH counts AS (
  SELECT COUNT(DISTINCT CASE WHEN COALESCE(LOWER(test_case_status), '') NOT IN ('closed', 'todo', 'to-do', 'to do', '') THEN test_case_id END) AS total_tests,
         COUNT(DISTINCT CASE WHEN LOWER(test_case_status) IN ('reopen', 'failed', 'not ok')
               THEN test_case_id END) AS total_defects
  FROM qf_case_status_tap
  WHERE project_name = :project_name
)
SELECT '## Test Failure Rate (Percentage)' AS description_md,
       '# ' || CASE WHEN total_tests = 0 THEN '0%'
                    ELSE ROUND((total_defects * 100.0) / total_tests,2) || '%' END AS description_md,
       'white' AS background_color,
       'alert-circle' AS icon,
       'red' AS color
FROM counts;

-- Success Percentage
WITH counts AS (
  SELECT COUNT(DISTINCT CASE WHEN COALESCE(LOWER(test_case_status), '') NOT IN ('closed', 'todo', 'to-do', 'to do', '') THEN test_case_id END) AS total_tests,
         COUNT(DISTINCT CASE WHEN LOWER(test_case_status) IN ('passed', 'ok')
               THEN test_case_id END) AS total_passed
  FROM qf_case_status_tap
  WHERE project_name = :project_name
)
SELECT '## Test Success Rate (Percentage)' AS description_md,
       '# ' || CASE WHEN total_tests = 0 THEN '0%'
                    ELSE ROUND((total_passed * 100.0) / total_tests, 2) || '%' END AS description_md,
       'white' AS background_color,
        'green' as color,
    'circle-dashed-check'       as icon
FROM counts;

-- Open Defects
SELECT '## Open Defects' AS description_md,
       '# ' || COALESCE(COUNT(testcase_id), 0) AS description_md,
       'white' AS background_color,
         'orange' as color,
    'details-off'       as icon,
       'open.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_issue_detail
WHERE project_name = :project_name
AND state='open'
ORDER BY testcase_id;

-- Closed Defects
SELECT '## Closed Defects' AS description_md,
       '# ' || COALESCE(COUNT(testcase_id), 0) AS description_md,
       'white' AS background_color,
         'orange' as color,
        'details-off'       as icon,
       'closed.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_issue_detail
WHERE project_name = :project_name
AND state='closed'
ORDER BY testcase_id;


-- Test Cycle Plan for the month
SELECT '## Test Cycle Plan (Month)' AS description_md,
       '# ' || COALESCE(COUNT(*), 0) AS description_md,
       'white' AS background_color,
       'calendar-stats' AS icon,
       'orange' AS color,
       'todo-cycle-month.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_role_with_evidence re
WHERE (re.status IS NULL OR LOWER(re.status) IN ('todo', 'to-do', 'to do'))
  AND re.project_name = :project_name
  AND STRFTIME('%m-%Y', SUBSTR(re.cycledate, 7, 4) || '-' || SUBSTR(re.cycledate, 1, 2) || '-' || SUBSTR(re.cycledate, 4, 2)) = STRFTIME('%m-%Y', 'now', 'localtime')
  AND NOT EXISTS (
      SELECT 1 FROM qf_tap_results tr
      WHERE UPPER(tr.test_case_id) = UPPER(re.testcaseid)
        AND tr.tap_date = re.cycledate
  );

-- Un assigned test cases
SELECT '## Unassigned Test Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'alert-circle' AS icon,
       'orange' AS color,
       'non-assigned-test-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_status
WHERE (latest_assignee IS NULL OR TRIM(latest_assignee) = '')
  AND project_name = :project_name;

  -- Automation percentage
 SELECT
    '## Automation Test Coverage (%)' AS description_md,
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
    CASE
        WHEN COALESCE(
                (
                    SELECT test_case_percentage
                    FROM qf_case_execution_status_percentage
                    WHERE project_name = :project_name
                      AND UPPER(execution_type) = 'AUTOMATION'
                ),
                0
            ) = 0 THEN NULL
        ELSE
            'automation.sql?project_name=' ||
            REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23')
    END AS link,
    'green' AS color,
    'brand-ansible' AS icon;


 SELECT
    '## Manual Test Coverage (%)' AS description_md,
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
    CASE
        WHEN COALESCE(
                (
                    SELECT test_case_percentage
                    FROM qf_case_execution_status_percentage
                    WHERE project_name = :project_name
                      AND UPPER(execution_type) = 'MANUAL'
                ),
                0
            ) = 0 THEN NULL
        ELSE
            'manual.sql?project_name=' ||
            REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23')
    END AS link,
    'orange' AS color,
    'brand-ansible' AS icon;


--- Test suite count
SELECT '## Test Suite Count' AS description_md,
         '# ' || COALESCE(COUNT(suiteid), 0) AS description_md,
       'white' AS background_color,
          'pink' as color,
    'timeline-event'       as icon,
       'test-suite-cases-summary.sql?project_name=' ||
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
SELECT
       '## Test Cycle Execution History' AS description_md,
       'white' AS background_color,
       'alert-circle' AS icon,
       'blue' AS color,
       'test-case-history.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link;

-- Recent Commit Changes
SELECT '## Recent Commit Changes' AS description_md,
       'white' AS background_color,
       'git-commit' AS icon,
       'teal' AS color,
       'github-commit-changes.sql' AS link
WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type IN ('table','view') AND name = 'github_commits');

-- Anchor point — placed ABOVE the divider so tab clicks land at the right spot
SELECT 'html' AS component;
SELECT '<div id="chart-section" style="scroll-margin-top: 56px;"></div>
<script>
  if (window.location.hash === "#chart-section") {
    document.addEventListener("DOMContentLoaded", function () {
      var el = document.getElementById("chart-section");
      if (el) el.scrollIntoView({ block: "start", behavior: "instant" });
    });
  }
</script>' AS html;

-- Test Status Visualization
SELECT 'divider' AS component,
       'Comprehensive Test Status' AS contents,
       5 AS size,
       'blue' AS color;



-- Chart 1: Test Execution Status
SELECT 'html' AS component, '<div class="row"><div class="col-md-6">' AS html;

-- Show Chart if data exists
SELECT 'chart' AS component,
       'pie' AS type,
       6 AS width,
       'Test Case Execution Status(%)' AS title,
       TRUE AS labels,
       'green' AS color,
       'red' AS color
WHERE EXISTS (SELECT 1 FROM qf_case_status_percentage WHERE projectname = :project_name AND (passedpercentage > 0 OR failedpercentage > 0));

SELECT 'Passed' AS label, COALESCE(passedpercentage, 0) AS value
FROM qf_case_status_percentage
WHERE projectname = :project_name AND (passedpercentage > 0 OR failedpercentage > 0)
UNION ALL
SELECT 'Failed' AS label, COALESCE(failedpercentage, 0) AS value
FROM qf_case_status_percentage
WHERE projectname = :project_name AND (passedpercentage > 0 OR failedpercentage > 0);

-- Show "No Data" if no data exists
SELECT 'html' AS component,
       '<div class="card p-3 mb-3"><h3 class="card-title">Test Case Execution Status(%)</h3><div style="text-align:center; color:red; padding:40px;"><h3>No Data</h3></div></div>' as html
WHERE (:project_name IS NULL OR :project_name = '' OR NOT EXISTS (SELECT 1 FROM qf_case_status_percentage WHERE projectname = :project_name AND (passedpercentage > 0 OR failedpercentage > 0)));

SELECT 'html' AS component, '</div><div class="col-md-6">' AS html;

-- Chart 2: Test Coverage - Automation vs Manual
-- Show Chart if data exists
SELECT 'chart' AS component,
       'pie' AS type,
       6 AS width,
       'Test Coverage(%)' AS title,
       TRUE AS labels,
       'green' AS color,
       'red' AS color
WHERE EXISTS (SELECT 1 FROM qf_case_execution_status_percentage WHERE project_name = :project_name AND test_case_percentage > 0);

SELECT 'AUTOMATION' AS label, COALESCE(test_case_percentage, 0) AS value
FROM qf_case_execution_status_percentage
WHERE project_name = :project_name
  AND UPPER(execution_type) = 'AUTOMATION'
  AND test_case_percentage > 0
UNION ALL
SELECT 'MANUAL' AS label, COALESCE(test_case_percentage, 0) AS value
FROM qf_case_execution_status_percentage
WHERE project_name = :project_name
  AND UPPER(execution_type) = 'MANUAL'
  AND test_case_percentage > 0;

-- Show "No Data" if no data exists for Chart 2
SELECT 'html' AS component,
       '<div class="card p-3 mb-3"><h3 class="card-title">Test Coverage(%)</h3><div style="text-align:center; color:red; padding:40px;"><h3>No Data</h3></div></div>' as html
WHERE (:project_name IS NULL OR :project_name = '' OR NOT EXISTS (SELECT 1 FROM qf_case_execution_status_percentage WHERE project_name = :project_name AND test_case_percentage > 0));

SELECT 'html' AS component, '</div></div>' AS html;

-- Assignee Breakdown
SELECT 'divider' AS component,
       'ASSIGNEE WISE TEST CASE DETAILS' AS contents,
       5 AS size,
       'blue' AS color;

-- Assignee Filter
SELECT 'form' AS component,
       'Submit' AS validate,
       'project-dropdown' as class,
       'true' AS auto_submit
WHERE EXISTS (SELECT 1 FROM qf_case_status WHERE project_name = :project_name AND latest_assignee IS NOT NULL AND latest_assignee <> '');


SELECT 'hidden' AS type,
       'project_name' AS name,
       COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '')) AS value
WHERE EXISTS (SELECT 1 FROM qf_case_status WHERE project_name = :project_name AND latest_assignee IS NOT NULL AND latest_assignee <> '');

SELECT 'assignee' AS name,
       'Select Assignee' AS label,
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

    select tbl.latest_assignee AS label_text,
tbl.latest_assignee AS value_text,
 1 AS sort_order
  from qf_case_status tbl
where project_name=:project_name  and
 tbl.latest_assignee!='' and tbl.latest_assignee is not null
group by tbl.latest_assignee

    ORDER BY sort_order, label_text
)
WHERE EXISTS (SELECT 1 FROM qf_case_status WHERE project_name = :project_name AND latest_assignee IS NOT NULL AND latest_assignee <> '');

SELECT 'table' AS component,
       "ASSIGNEE" AS markdown,
       "TOTAL TEST CASES" AS markdown,
       "TOTAL PASSED" AS markdown,
       "TOTAL FAILED" AS markdown,
       "TOTAL CLOSED" AS markdown,
       1 AS search,
       1 AS sort
WHERE EXISTS (SELECT 1 FROM qf_case_status_tap WHERE project_name = :project_name AND latest_assignee IS NOT NULL AND TRIM(latest_assignee) <> '');

SELECT
    latest_assignee AS "ASSIGNEE",

    ${md.link("COUNT(test_case_id)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL TEST CASES",

    ${md.link("SUM(CASE WHEN LOWER(test_case_status) IN ('passed', 'ok') THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&status=passed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL PASSED",

    ${md.link("SUM(CASE WHEN LOWER(test_case_status) IN ('failed', 'not ok') THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&status=failed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL FAILED",


    ${md.link("SUM(CASE WHEN LOWER(test_case_status) = 'closed' THEN 1 ELSE 0 END)",
        ["'assigneetotaltestcase.sql?assignee='", "latest_assignee",
         "'&status=closed&project_name='", "COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> ''))"])} AS "TOTAL CLOSED"

FROM qf_case_status_tap
WHERE project_name = CASE
      WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
      THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> ''))
      ELSE :project_name
  END
  AND (
      (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
      OR (:project_name IS NOT NULL AND :project_name <> '')
  )
  AND latest_assignee IS NOT NULL
  AND TRIM(latest_assignee) <> ''
  AND (
        :assignee IS NULL
     OR :assignee = 'ALL'
     OR latest_assignee = :assignee
  )
GROUP BY latest_assignee;

-- Show "No Data" if no data exists for Assignee
SELECT 'html' AS component,
       '<div style="text-align:center; color:red; padding:20px;"><h3>No Data</h3></div>' as html
WHERE (:project_name IS NULL OR :project_name = '' OR NOT EXISTS (SELECT 1 FROM qf_case_status_tap WHERE project_name = :project_name AND latest_assignee IS NOT NULL AND TRIM(latest_assignee) <> ''));

${pagination.limit};
${pagination.navigation};

-- Test Cycle Summary
SELECT 'divider' AS component,
       'TEST CYCLE SUMMARY' AS contents,
       5 AS size,
       'blue' AS color;

SELECT 'table' AS component,
       "CYCLE" as markdown,
       "CYCLE DATE" as markdown,
       "TOTAL TEST CASES" as markdown,
       "PASSED" as markdown,
       "FAILED" as markdown,
       "TOTAL CLOSED" as markdown,
       1 AS sort,
       1 AS search
WHERE EXISTS (SELECT 1 FROM cycle_data_summary WHERE project_name = :project_name AND totalcases > 0);

SELECT
  "CYCLE",
  "CYCLE DATE",
  "TOTAL TEST CASES",
  "PASSED",
  "FAILED",
  "TOTAL CLOSED"
FROM (
  SELECT
    cycledate_sort,
    ${md.link("cycle",
          ["'cycletotaltestcase.sql?cycle='", "cycle","'&project_name='",":project_name"])} AS "CYCLE",
    cycledate as 'CYCLE DATE',
    ${md.link("totalcases",
          ["'cycletotaltestcase.sql?cycle='", "cycle","'&project_name='",":project_name"])} AS "TOTAL TEST CASES",
    ${md.link("passed_cases",
          ["'cycletotaltestcase.sql?cycle='", "cycle","'&status=passed&project_name='",":project_name"])} AS "PASSED",
    ${md.link("failed_cases",
          ["'cycletotaltestcase.sql?cycle='", "cycle","'&status=failed&project_name='",":project_name"])} AS "FAILED",
    ${md.link("closed_cases",
          ["'cycletotaltestcase.sql?cycle='", "cycle","'&status=closed&project_name='",":project_name"])} AS "TOTAL CLOSED"
  FROM cycle_data_summary
  WHERE project_name = CASE
        WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
        THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> ''))
        ELSE :project_name
    END
    AND (
        (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
        OR (:project_name IS NOT NULL AND :project_name <> '')
    )
    AND (totalcases > 0)
    AND (
        -- Show if it is not the earliest date
        cycledate_sort > (
            SELECT MIN(cycledate_sort)
            FROM cycle_data_summary c3
            WHERE c3.project_name = cycle_data_summary.project_name
        )
        OR
        -- OR show if it IS the earliest date but it is also the ONLY date
        (SELECT MIN(cycledate_sort) FROM cycle_data_summary c2 WHERE c2.project_name = cycle_data_summary.project_name) =
        (SELECT MAX(cycledate_sort) FROM cycle_data_summary c4 WHERE c4.project_name = cycle_data_summary.project_name)
    )
  GROUP BY cycle, cycledate
) t
ORDER BY cycledate_sort DESC;

-- Show "No Data" if cycle summary is empty
SELECT 'html' AS component,
       '<div style="text-align:center; color:red; padding:20px;"><h3>No Data</h3></div>' as html
WHERE (:project_name IS NULL OR :project_name = '' OR NOT EXISTS (SELECT 1 FROM cycle_data_summary WHERE project_name = :project_name AND totalcases > 0));

-- Requirement Traceability
SELECT 'divider' AS component,
       'REQUIREMENT TRACEABILITY' AS contents,
       5 AS size,
       'blue' AS color;

${paginate("qf_requirement_summary", "WHERE project_name = CASE WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') = 1 THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '')) ELSE :project_name END")}

SELECT 'table' AS component,
       "REQUIREMENT ID" AS markdown,
       "TOTAL TEST CASES" AS markdown,
       "TOTAL PASSED" AS markdown,
       "TOTAL FAILED" AS markdown,
       "TOTAL CLOSED" AS markdown,
       1 AS sort,
       1 AS search
WHERE EXISTS (SELECT 1 FROM qf_requirement_summary WHERE project_name = :project_name);

SELECT
   ${md.link("requirement_ID",
        ["'requirementdetails.sql?req='", "requirement_ID", "'&project_name='", ":project_name"])} AS "REQUIREMENT ID",
    ${md.link("total_test_cases",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&project_name='", ":project_name"])} AS "TOTAL TEST CASES",
    ${md.link("total_passed",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=passed&project_name='", ":project_name"])} AS "TOTAL PASSED",
    ${md.link("total_failed",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=failed&project_name='", ":project_name"])} AS "TOTAL FAILED",
    ${md.link("total_closed",
        ["'requirementtotaltestcase.sql?req='", "requirement_ID", "'&status=closed&project_name='", ":project_name"])} AS "TOTAL CLOSED"
FROM qf_requirement_summary
WHERE project_name = CASE
      WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') = 1
      THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> ''))
      ELSE :project_name
  END
${pagination.limit};

-- Show "No Data" if requirement traceability is empty
SELECT 'html' AS component,
       '<div style="text-align:center; color:red; padding:20px;"><h3>No Data</h3></div>' as html
WHERE (:project_name IS NULL OR :project_name = '' OR NOT EXISTS (SELECT 1 FROM qf_requirement_summary WHERE project_name = :project_name));

SELECT 'text' AS component,
       (SELECT CASE WHEN CAST($current_page AS INTEGER) > 1 THEN '[Previous](?limit=' || COALESCE($limit,50) || '&offset=' || (COALESCE($offset,0) - COALESCE($limit,50)) || ')' ELSE '' END)
       || ' '
       || '(Page ' || COALESCE($current_page,1) || ' of ' || COALESCE($total_pages,1) || ") "
       || (SELECT CASE WHEN CAST(COALESCE($current_page,1) AS INTEGER) < CAST(COALESCE($total_pages,1) AS INTEGER) THEN '[Next](?limit=' || COALESCE($limit,50) || '&offset=' || (COALESCE($offset,0) + COALESCE($limit,50)) || ')' ELSE '' END)
       AS contents_md
WHERE (SELECT COUNT(*) FROM qf_requirement_summary WHERE project_name = CASE WHEN (SELECT COUNT(DISTINCT project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '') = 1 THEN COALESCE(:project_name, (SELECT MIN(project_name) FROM qf_case_status WHERE project_name IS NOT NULL AND project_name <> '')) ELSE :project_name END) > 0;

```

---

## GitHub Commit Changes

```sql github-commit-changes.sql { route: { caption: "Commit Changes" } }
-- @route.description "Shows the file changes introduced by a specific GitHub commit, with a diff-style view of added and removed lines."

SELECT 'text' AS component, $page_description AS contents_md;

-- Page title & commit selector form
SELECT 'divider' AS component,
       'GitHub Commit Changes' AS contents,
       5 AS size,
       'teal' AS color;

-- Commit filter form
SELECT 'form' AS component,
       'Fetch Commits' AS validate,
       'blue' as button_color
WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type IN ('table','view') AND name = 'qf_github_commits');

SELECT 'commit_date' AS name,
       'Filter by Date' AS label,
       'date' AS type,
       :commit_date AS value,
       4 as width
WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type IN ('table','view') AND name = 'qf_github_commits');

SELECT 'sha' AS name,
       'Select Commit' AS label,
       'select' AS type,
       COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1)) AS value,
       8 as width,
       (SELECT json_group_array(json_object('label', SUBSTR(sha,1,7) || ' - ' || COALESCE(message, '(no message)'), 'value', sha)) 
        FROM (
            SELECT sha, message 
            FROM qf_github_commits 
            WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date)
            ORDER BY commit_date DESC LIMIT 50
        )) AS options
WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type IN ('table','view') AND name = 'qf_github_commits');

-- Commit metadata card
SELECT 'card' AS component, 1 AS columns
WHERE EXISTS (
    SELECT 1 FROM qf_github_commits
    WHERE sha = COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1))
);

SELECT
    '### ' || COALESCE(message, 'No message') AS title_md,
    '**SHA:** ' || sha || char(10)
    || '**Author:** ' || COALESCE(author_name, 'Unknown') || '  ' || char(10)
    || '**Date:** ' || COALESCE(commit_date, '')
    AS description_md,
    'white' AS background_color,
    'git-commit' AS icon,
    'teal' AS color,
    '🔗 View full commit on GitHub' AS footer,
    html_url AS link
FROM qf_github_commits
WHERE sha = COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1));

-- Diff view per changed file
SELECT 'divider' AS component,
       'File Changes' AS contents,
       5 AS size,
       'blue' AS color
WHERE EXISTS (SELECT 1 FROM qf_github_commit_files WHERE sha = COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1)));

SELECT 'html' AS component
WHERE EXISTS (SELECT 1 FROM qf_github_commit_files WHERE sha = COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1)));

SELECT
  '<style>
    .diff-container { font-family: monospace; font-size: 13px; border-radius: 8px; overflow: hidden; margin-bottom: 24px; border: 1px solid #e1e4e8; }
    .diff-file-header { background: #f1f8ff; border-bottom: 1px solid #c8e1ff; padding: 10px 16px; font-weight: 600; color: #0366d6; display: flex; align-items: center; gap: 8px; }
    .diff-file-header svg { flex-shrink: 0; }
    .diff-stats { font-size: 12px; margin-left: auto; display: flex; gap: 8px; }
    .diff-stat-add { color: #28a745; font-weight: 700; }
    .diff-stat-del { color: #d73a49; font-weight: 700; }
    .diff-hunk-header { background: #dbedff; color: #005cc5; padding: 4px 16px; font-size: 12px; border-top: 1px solid #c8e1ff; border-bottom: 1px solid #c8e1ff; }
    .diff-line { display: flex; white-space: pre; }
    .diff-line-num { color: rgba(27,31,35,.3); text-align: right; padding: 0 10px 0 10px; min-width: 50px; user-select: none; border-right: 1px solid #e1e4e8; }
    .diff-line-content { padding: 0 12px; flex: 1; overflow-x: auto; }
    .diff-added { background: #e6ffed; }
    .diff-added .diff-line-num  { background: #cdffd8; color: #28a745; }
    .diff-removed { background: #ffeef0; }
    .diff-removed .diff-line-num { background: #ffdce0; color: #d73a49; }
    .diff-context .diff-line-num { background: #fafbfc; }
    .no-data-box { text-align:center; color:#888; padding:40px; background:#fafbfc; border:1px solid #e1e4e8; border-radius:8px; margin:16px 0; }
  </style>' AS html
FROM qf_github_commits
WHERE sha = COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1))
LIMIT 1;

-- Render each file's patch as a styled diff block
SELECT 'html' AS component
WHERE EXISTS (SELECT 1 FROM qf_github_commit_files WHERE sha = COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1)));

WITH commit_data AS (
    SELECT
        json_group_array(
            json_object(
                'filename', filename,
                'status', status,
                'additions', additions,
                'deletions', deletions,
                'patch', patch
            )
        ) as files_json
    FROM qf_github_commit_files
    WHERE sha = COALESCE(:sha, (SELECT sha FROM qf_github_commits WHERE (:commit_date IS NULL OR date(commit_date) = :commit_date) ORDER BY commit_date DESC LIMIT 1))
)
SELECT
  '<div id="diff-root"></div>
  <script>
  (function() {
    var filesJson = ' || COALESCE(files_json, '[]') || ';
    var root = document.getElementById("diff-root");
    if (!root) return;
    if (!filesJson || filesJson.length === 0) {
      root.innerHTML = "<div class=\\"no-data-box\\"><h3>No file changes recorded for this commit.</h3></div>";
      return;
    }
    filesJson.forEach(function(f) {
      var patch = f.patch || "";
      var addCount = 0, delCount = 0;
      var lines = patch.split("\n");
      var diffLines = "";
      var newNum = 0, oldNum = 0;
      lines.forEach(function(line) {
        var cls = "diff-context";
        var prefix = line.charAt(0);
        var numHtml = "";
        if (line.startsWith("@@")) {
          cls = "";
          var m = line.match(/@@ -(\\d+)(?:,\\d+)? \\+(\\d+)(?:,\\d+)? @@/);
          if (m) { oldNum = parseInt(m[1]) - 1; newNum = parseInt(m[2]) - 1; }
          diffLines += "<div class=\\"diff-hunk-header\\">" + line.replace(/</g,"&lt;").replace(/>/g,"&gt;") + "</div>";
          return;
        } else if (prefix === "+") {
          cls = "diff-added"; addCount++; newNum++;
          numHtml = "<span class=\\"diff-line-num\\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + newNum + "</span>";
        } else if (prefix === "-") {
          cls = "diff-removed"; delCount++; oldNum++;
          numHtml = "<span class=\\"diff-line-num\\">" + oldNum + "</span>";
        } else {
          oldNum++; newNum++;
          numHtml = "<span class=\\"diff-line-num\\">" + oldNum + "</span>";
        }
        var content = line.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");
        diffLines += "<div class=\\"diff-line " + cls + "\\">" + numHtml + "<span class=\\"diff-line-content\\">" + content + "</span></div>";
      });
      var statusBadge = { "added": "🟢 Added", "removed": "🔴 Removed", "modified": "🟡 Modified", "renamed": "🔵 Renamed" }[f.status] || f.status || "";
      var html = "<div class=\\"diff-container\\">" +
        "<div class=\\"diff-file-header\\">" +
        "<svg width=\\"16\\" height=\\"16\\" viewBox=\\"0 0 16 16\\" fill=\\"currentColor\\"><path d=\\"M2 1.75C2 .784 2.784 0 3.75 0h6.586c.464 0 .909.184 1.237.513l2.914 2.914c.329.328.513.773.513 1.237v9.586A1.75 1.75 0 0 1 13.25 16h-9.5A1.75 1.75 0 0 1 2 14.25Zm1.75-.25a.25.25 0 0 0-.25.25v12.5c0 .138.112.25.25.25h9.5a.25.25 0 0 0 .25-.25V6h-2.75A1.75 1.75 0 0 1 9 4.25V1.5Zm6.75.062V4.25c0 .138.112.25.25.25h2.688ZM8 7.25a.75.75 0 0 1 .75.75v1.19l.47-.47a.749.749 0 1 1 1.06 1.06l-1.75 1.75a.749.749 0 0 1-1.06 0L5.72 9.78a.749.749 0 1 1 1.06-1.06l.47.47V8A.75.75 0 0 1 8 7.25Z\\"/></svg>" +
        (f.filename || "unknown file") + " <small style=\\"color:#888;font-weight:400\\">&nbsp;" + statusBadge + "</small>" +
        "<span class=\\"diff-stats\\"><span class=\\"diff-stat-add\\">+" + addCount + "</span><span class=\\"diff-stat-del\\">-" + delCount + "</span></span>" +
        "</div>" +
        (patch ? diffLines : "<div style=\\"padding:16px;color:#888;\\">Binary file or no textual diff available.</div>") +
        "</div>";
      root.innerHTML += html;
    });
  })();
  </script>'
AS html
FROM commit_data;

-- No data: github_commits table missing
SELECT 'html' AS component,
       '<div class="no-data-box" style="text-align:center;color:#888;padding:40px;background:#fafbfc;border:1px solid #e1e4e8;border-radius:8px;margin:16px 0;"><h3>⚠️ GitHub commits not yet ingested.</h3><p>Run the Singer Tap ingestion to populate GitHub commit data.</p></div>' AS html
WHERE NOT EXISTS (SELECT 1 FROM sqlite_master WHERE type IN ('table','view') AND name = 'qf_github_commits');

```

---

# Test Case List Views

## All Test Cases

 <!--  -->

```sql test-cases.sql { route: { caption: "Test Cases" } }
-- @route.description "An overview of all test cases showing the test case ID, title, current status, and the latest execution cycle, allowing quick review and tracking of test case progress."
SELECT 'text' AS component,
$page_description AS contents_md;
${paginate("qf_case_status_tap", "WHERE project_name = $project_name")}
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
FROM qf_case_status_tap
WHERE project_name = $project_name
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER)
${pagination.limit};
${pagination.navWithParams("project_name")};
```

## Passed Test Cases

<!-- Lists all test cases that have passed -->

```sql passed.sql { route: { caption: "Passed Test Cases" } }
-- @route.description "Lists all test cases with a passed status, showing their test case ID, title, and latest execution cycle for quick status review"

SELECT 'text' AS component,
$page_description AS contents_md;
${paginate("qf_case_status_tap", "WHERE project_name = $project_name AND LOWER(test_case_status) IN ('passed', 'ok')")}

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Total Passed Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT

  ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status_tap
WHERE LOWER(test_case_status) IN ('passed', 'ok')
AND project_name = $project_name
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER)
${pagination.limit};
${pagination.navWithParams("project_name")};
```

```sql failed.sql { route: { caption: "Failed Test Cases" } }
-- @route.description "Lists all test cases with a failed status, showing their test case ID, title, and latest execution cycle for quick status review"

SELECT 'text' AS component,
$page_description AS contents_md;

${paginate("qf_case_status_tap", "WHERE project_name = $project_name AND LOWER(test_case_status) IN ('failed', 'not ok')")}

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Total Failed Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT

  ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status_tap
WHERE LOWER(test_case_status) IN ('failed', 'not ok')
AND project_name = $project_name
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER)
${pagination.limit};
${pagination.navWithParams("project_name")};
```

```sql closed-test-cases.sql { route: { caption: "Closed Test Cases" } }
-- @route.description "Lists all test cases with a closed status, showing their test case ID, title, and latest execution cycle"

${paginate("qf_case_status_tap", "WHERE project_name = $project_name AND LOWER(test_case_status) = 'closed'")}

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Total Closed Test Cases' AS title,
       1 AS search,
       1 AS sort;

SELECT
  ${md.link("test_case_id",
        ["'testcasedetails.sql?testcaseid='", "test_case_id",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
       test_case_title AS "Title",
       test_case_status AS "Status",
       latest_cycle AS "Latest Cycle"
FROM qf_case_status_tap
WHERE LOWER(test_case_status) = 'closed'
AND project_name = $project_name
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER)
${pagination.limit};
${pagination.navWithParams("project_name")};
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
FROM qf_case_status_tap
WHERE LOWER(test_case_status) IN ('reopen', 'failed', 'not ok')
AND project_name = $project_name
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER);
```

## Closed Cases

```sql closed.sql { route: { caption: "Closed Test Cases" } }
-- @route.description "List of all test cases that have closed"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
         'ID' AS markdown,
       'Test Case ID' AS markdown,
        TRUE AS actions,
       1 AS search,
       1 AS sort;

SELECT
${md.link("id", ["'issuedetails.sql?testcaseid='", "TRIM(testcase_id)","'&project_name='", "$project_name","'&id='", "id"])} AS "ID",
  ${md.link("testcase_id",
        ["'testcasedetails.sql?testcaseid='", "TRIM(testcase_id)","'&project_name='", "$project_name"])} AS "Test Case ID",
       testcase_description AS "Description",
       assignee AS "ASSIGNEE",
     JSON('{"name":"EXTERNAL REFERENCE","tooltip":"VIEW EXTERNAL REFERENCE","link":"' || html_url || '","icon":"brand-github","target":"_blank"}') as _sqlpage_actions


FROM qf_issue_detail
WHERE project_name = $project_name
AND state='closed'
ORDER BY id;

```

## Open Cases

```sql open.sql { route: { caption: "Open Defects" } }
-- @route.description "Displays all open issues with their test case ID and description to help monitor issues "

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
         'ID' AS markdown,
       'Test Case ID' AS markdown,
        TRUE AS actions,
       1 AS search,
       1 AS sort;

SELECT
${md.link("id", ["'issuedetails.sql?testcaseid='", "TRIM(testcase_id)","'&project_name='", "$project_name","'&id='", "id"])} AS "ID",
  ${md.link("testcase_id",
        ["'testcasedetails.sql?testcaseid='", "TRIM(testcase_id)","'&project_name='", "$project_name"])} AS "Test Case ID",
       testcase_description AS "Description",
       assignee AS "ASSIGNEE",
     JSON('{"name":"EXTERNAL REFERENCE","tooltip":"VIEW EXTERNAL REFERENCE","link":"' || html_url || '","icon":"brand-github","target":"_blank"}') as _sqlpage_actions


FROM qf_issue_detail
WHERE project_name = $project_name
AND state='open'
ORDER BY id;
```

<!-- ## Reopened Cases

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
``` -->

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
       tbl1.status_refined AS "Status",
       tbl1.cycle AS "Latest Cycle"
FROM qf_role_with_evidence_refined tbl1
inner join qf_role_with_case tbl2
on tbl1.testcaseid=tbl2.testcaseid
and tbl1.uniform_resource_id=tbl2.uniform_resource_id
WHERE ($cycle IS NULL OR tbl1.cycle = $cycle)
  AND ($status IS NULL OR tbl1.status_refined = $status OR ($status='passed' AND tbl1.status_refined='ok') OR ($status='failed' AND tbl1.status_refined='not ok')) AND tbl1.project_name=$project_name
ORDER BY CAST(SUBSTR(tbl1.testcaseid, INSTR(tbl1.testcaseid, ' ') + 1) AS INTEGER);
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
FROM qf_case_status_tap
WHERE requirement_ID = $req
  AND ($status IS NULL OR LOWER(test_case_status) = LOWER($status) OR (LOWER($status)='passed' AND LOWER(test_case_status)='ok') OR (LOWER($status)='failed' AND LOWER(test_case_status)='not ok'))
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER);
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
FROM qf_case_status_tap
WHERE ($assignee IS NULL OR latest_assignee = $assignee)
  AND ($status IS NULL OR LOWER(test_case_status) = LOWER($status) OR (LOWER($status)='passed' AND LOWER(test_case_status)='ok') OR (LOWER($status)='failed' AND LOWER(test_case_status)='not ok'))
  AND project_name=$project_name
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER);
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
  3 as width,
  COALESCE(strftime('%Y-%m-%d', NULLIF($from_date, '')), date('now', 'localtime', 'start of month')) AS value;

-- To date (retains value after submission)
SELECT
  'to_date'    AS name,
  'To date'    AS label,
  'date'       AS type,
  3 as width,
  COALESCE(strftime('%Y-%m-%d', NULLIF($to_date, '')), date('now', 'localtime', 'start of month', '+1 month', '-1 day')) AS value;

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
  1 AS sort,
  1 AS search;


WITH tblevidence AS (
SELECT
  DISTINCT
    tbl.assignee,
    -- tbl.created_at,
    tbl.cycle,
    tbl.project_name,
  coalesce( (select  case when tap.test_case_status='not ok' then 'failed' when tap.test_case_status='ok' then 'passed' else tap.test_case_status end from qf_case_status_tap tap where tap.test_case_id= tbl.testcaseid
    and   tap.latest_cycle=tbl.cycle),tbl.status)
     as status,

    tbl.severity,
    tbl.testcaseid,

  tbl.cycledate
  FROM qf_role_with_evidence_history tbl
WHERE tbl.project_name = $project_name
)

SELECT
  tbl3.cycle,
  tbl3.cycledate,
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
  )} AS "TOTAL FAILED"



FROM (

  SELECT
    tbl2.cycle,

    tbl2.cycledate,
    tbl2.project_name,
    COUNT(*) AS total_testcases,
    0 AS passed_cases,
    0 AS failed_cases,
    0 AS reopen_cases,
    0 AS closed_cases
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
    SUM(CASE WHEN tbl2.status='closed'  THEN 1 ELSE 0 END) AS closed_cases

  FROM tblevidence tbl2
  GROUP BY tbl2.cycle, tbl2.cycledate, tbl2.project_name

) tbl3

WHERE
(
  DATE(
    SUBSTR(tbl3.cycledate,7,4)||'-'||SUBSTR(tbl3.cycledate,1,2)||'-'||SUBSTR(tbl3.cycledate,4,2)
  ) >= DATE(COALESCE(NULLIF($from_date, ''), date('now', 'localtime', 'start of month')))
)
AND
(
  DATE(
    SUBSTR(tbl3.cycledate,7,4)||'-'||SUBSTR(tbl3.cycledate,1,2)||'-'||SUBSTR(tbl3.cycledate,4,2)
  ) <= DATE(COALESCE(NULLIF($to_date, ''), date('now', 'localtime', 'start of month', '+1 month', '-1 day')))
)

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

SET tab = COALESCE($tab, 'Details');

SELECT 'tab' as component;
SELECT 'Details' as title, 'testcasedetails.sql?testcaseid=' || $testcaseid || '&project_name=' || $project_name || '&tab=Details' as link, :tab = 'Details' as active, 'file-text' as icon;
SELECT 'Versioning History' as title, 'testcasedetails.sql?testcaseid=' || $testcaseid || '&project_name=' || $project_name || '&tab=Versioning History' as link, :tab = 'Versioning History' as active, 'history' as icon;

-- Details Tab Content
SELECT 'text' AS component, $page_description AS contents_md WHERE :tab = 'Details';

SELECT 'card' AS component,
       'Test Cases Details' AS title,
       1 AS columns
WHERE :tab = 'Details';

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
WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND :tab = 'Details'
ORDER BY qcm.test_case_id;

-- Versioning History Tab Content
SELECT 'text' AS component, 'Track historical edits and iterations of the test case, revealing the evolution of test case descriptions, preconditions, steps, and expected results.' AS contents_md WHERE :tab = 'Versioning History';

SELECT 'html' AS component WHERE :tab = 'Versioning History';

SELECT
'<details class="card mb-4" style="border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); border: 1px solid #e9ecef;">' ||
  '<summary class="card-header bg-light text-dark" style="border-bottom: 2px solid #0d6efd; cursor: pointer; display: flex; align-items: center; gap: 10px;">' ||
    '<h3 class="card-title text-primary m-0" style="font-weight: 600;">Version ' || version_num || '</h3>' ||
    '<span class="ms-auto text-muted" style="font-size: 0.85em; font-style: italic;">(Click to expand details)</span>' ||
  '</summary>' ||
  '<div class="card-body p-4">' ||
    '<div class="row g-4">' ||
      '<div class="col-md-6 border-end">' ||
        '<h4 class="text-secondary mb-3"><i class="ti ti-history me-2"></i>Previous</h4>' ||
        '<div class="p-3 bg-light rounded text-secondary" style="white-space: pre-wrap; font-size: 0.95em; min-height: 250px; ' || CASE WHEN version_num = 1 THEN 'display:none;' ELSE '' END || '">' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(prev_title, '') != COALESCE(curr_title, '') THEN 'background-color: #f8d7da; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #f5c2c7;' ELSE 'margin-bottom: 8px;' END || '"><strong>Title:</strong> ' || COALESCE(prev_title, 'N/A') || '</div>' ||
          '<div style="margin-bottom: 8px;"><strong>Test Case ID:</strong> ' || test_case_id || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(prev_desc, '') != COALESCE(curr_desc, '') THEN 'background-color: #f8d7da; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #f5c2c7;' ELSE 'margin-bottom: 8px;' END || '"><strong>Description:</strong>' || char(10) || COALESCE(prev_desc, 'N/A') || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(prev_prec, '') != COALESCE(curr_prec, '') THEN 'background-color: #f8d7da; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #f5c2c7;' ELSE 'margin-bottom: 8px;' END || '"><strong>Preconditions:</strong>' || char(10) || COALESCE(prev_prec, 'N/A') || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(prev_steps, '') != COALESCE(curr_steps, '') THEN 'background-color: #f8d7da; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #f5c2c7;' ELSE 'margin-bottom: 8px;' END || '"><strong>Steps:</strong>' || char(10) || COALESCE(prev_steps, 'N/A') || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(prev_exp, '') != COALESCE(curr_exp, '') THEN 'background-color: #f8d7da; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #f5c2c7;' ELSE 'margin-bottom: 8px;' END || '"><strong>Expected Results:</strong>' || char(10) || COALESCE(prev_exp, 'N/A') || '</div>' ||
        '</div>' ||
        CASE WHEN version_num = 1 THEN '<div class="p-4 bg-light rounded text-muted d-flex align-items-center justify-content-center" style="min-height: 250px; font-style: italic;">Initial Version - No Previous History</div>' ELSE '' END ||
      '</div>' ||
      '<div class="col-md-6">' ||
        '<h4 class="text-success mb-3"><i class="ti ti-check me-2"></i>Current</h4>' ||
        '<div class="p-3 bg-white border rounded text-dark" style="white-space: pre-wrap; font-size: 0.95em; min-height: 250px; border-left: 4px solid #198754 !important;">' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(curr_title, '') != COALESCE(prev_title, '') THEN 'background-color: #d1e7dd; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #badbcc;' ELSE 'margin-bottom: 8px;' END || '"><strong>Title:</strong> ' || COALESCE(curr_title, 'N/A') || '</div>' ||
          '<div style="margin-bottom: 8px;"><strong>Test Case ID:</strong> ' || test_case_id || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(curr_desc, '') != COALESCE(prev_desc, '') THEN 'background-color: #d1e7dd; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #badbcc;' ELSE 'margin-bottom: 8px;' END || '"><strong>Description:</strong>' || char(10) || COALESCE(curr_desc, 'N/A') || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(curr_prec, '') != COALESCE(prev_prec, '') THEN 'background-color: #d1e7dd; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #badbcc;' ELSE 'margin-bottom: 8px;' END || '"><strong>Preconditions:</strong>' || char(10) || COALESCE(curr_prec, 'N/A') || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(curr_steps, '') != COALESCE(prev_steps, '') THEN 'background-color: #d1e7dd; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #badbcc;' ELSE 'margin-bottom: 8px;' END || '"><strong>Steps:</strong>' || char(10) || COALESCE(curr_steps, 'N/A') || '</div>' ||
          '<div style="' || CASE WHEN version_num > 1 AND COALESCE(curr_exp, '') != COALESCE(prev_exp, '') THEN 'background-color: #d1e7dd; padding: 8px; border-radius: 4px; margin-bottom: 8px; border: 1px solid #badbcc;' ELSE 'margin-bottom: 8px;' END || '"><strong>Expected Results:</strong>' || char(10) || COALESCE(curr_exp, 'N/A') || '</div>' ||
        '</div>' ||
      '</div>' ||
    '</div>' ||
  '</div>' ||
'</details>' AS html
FROM (
    WITH extracted AS (
        SELECT
          extracted_id AS test_case_id,
          title AS test_case_title,
          json_extract(body_json_string, '$[3].paragraph') AS description,
          (SELECT group_concat((CAST(j.key AS INTEGER) + 1) || '. ' || json_extract(j.value, '$.item[0].paragraph'), char(10))
           FROM json_each(json_extract(body_json_string, '$[5].list')) AS j) AS preconditions,
          (SELECT group_concat((CAST(j.key AS INTEGER) + 1) || '. ' || json_extract(j.value, '$.item[0].paragraph'), char(10))
           FROM json_each(json_extract(body_json_string, '$[7].list')) AS j) AS steps,
          (SELECT group_concat((CAST(j.key AS INTEGER) + 1) || '. ' || json_extract(j.value, '$.item[0].paragraph'), char(10))
           FROM json_each(json_extract(body_json_string, '$[9].list')) AS j) AS expected_results,
          created_at
        FROM qf_role_history
        WHERE role_name = 'case' AND extracted_id = $testcaseid
    ),
    grouped_versions AS (
        SELECT
          test_case_id,
          test_case_title,
          description,
          preconditions,
          steps,
          expected_results,
          MIN(created_at) AS first_seen
        FROM extracted
        GROUP BY test_case_id, test_case_title, description, preconditions, steps, expected_results
    )
    SELECT
      test_case_id,
      test_case_title AS curr_title,
      description AS curr_desc,
      preconditions AS curr_prec,
      steps AS curr_steps,
      expected_results AS curr_exp,
      ROW_NUMBER() OVER (ORDER BY first_seen ASC) as version_num,
      LAG(test_case_title) OVER (ORDER BY first_seen ASC) as prev_title,
      LAG(description) OVER (ORDER BY first_seen ASC) as prev_desc,
      LAG(preconditions) OVER (ORDER BY first_seen ASC) as prev_prec,
      LAG(steps) OVER (ORDER BY first_seen ASC) as prev_steps,
      LAG(expected_results) OVER (ORDER BY first_seen ASC) as prev_exp
    FROM grouped_versions
)
WHERE :tab = 'Versioning History'
ORDER BY version_num DESC;
```

---

# Visualizations

## Pass/Fail Pie Chart

```sql chart/pie-chart-left.sql { route: { caption: "" } }
SELECT 'chart' AS component,
       'pie' AS type,
       'Test Case Execution Status(%)' AS title,
       TRUE AS labels,
       'green' AS color,
       'orange' AS color,
       'red' AS color,
       'chart-left' AS class;

SELECT
  'Passed' AS label,
  COALESCE(passedpercentage, 0) AS value
FROM qf_case_status_percentage
WHERE projectname = $project_name

UNION ALL

SELECT
  'Failed' AS label,
  COALESCE(failedpercentage, 0) AS value
FROM qf_case_status_percentage
WHERE projectname = $project_name;
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

## Unassigned Test Cases

```sql non-assigned-test-cases.sql { route: { caption: "Unassigned Test Cases" } }
-- @route.description "Provides the List of Unassigned Test Cases"

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       1 AS search,
       1 AS sort;

SELECT
    ${md.link("testcaseid",
        ["'testcasedetails.sql?testcaseid='", "testcaseid",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
    cycle AS "Cycle",
    cycledate AS "Cycle Date",
    status AS "Status"
FROM qf_role_with_evidence
WHERE (assignee IS NULL OR TRIM(assignee) = '')
  AND project_name = $project_name
ORDER BY SUBSTR(cycledate, 7, 4) DESC, SUBSTR(cycledate, 1, 2) DESC, SUBSTR(cycledate, 4, 2) DESC;

```

```sql todo-cycle-month.sql { route: { caption: "Test Cycle Plan (Month)" } }
-- @route.description "Provides the List of Test Cycle Plans for the current month with 'todo' status"

${paginate("qf_role_with_evidence")}

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'Test Case ID' AS markdown,
       'Test Cases' AS title,
       1 AS search,
       1 AS sort;
SELECT
  ${md.link("re.testcaseid",
        ["'testcasedetails.sql?testcaseid='", "re.testcaseid",
         "'&project_name='", "$project_name"])} AS "Test Case ID",
    re.cycle AS "Cycle",
    re.cycledate AS "Cycle Date",
    re.status AS "Status",
    re.assignee AS "Assignee"
FROM qf_role_with_evidence re
WHERE re.project_name = $project_name
  AND (re.status IS NULL OR LOWER(re.status) IN ('todo', 'to-do', 'to do'))
  AND (
    (re.cycledate IS NULL OR re.cycledate = '') OR
    (STRFTIME('%m-%Y', SUBSTR(re.cycledate, 7, 4) || '-' || SUBSTR(re.cycledate, 1, 2) || '-' || SUBSTR(re.cycledate, 4, 2)) = STRFTIME('%m-%Y', 'now', 'localtime'))
  )
  AND NOT EXISTS (
      SELECT 1 FROM qf_tap_results tr
      WHERE UPPER(tr.test_case_id) = UPPER(re.testcaseid)
        AND tr.tap_date = re.cycledate
  )
ORDER BY SUBSTR(re.cycledate, 7, 4) DESC, SUBSTR(re.cycledate, 1, 2) DESC, SUBSTR(re.cycledate, 4, 2) DESC;

```

```sql test-suite-cases.sql { route: { caption: "Test suite" } }
-- @route.description "Test suite is a collection of test cases designed to verify the functionality, performance, and security of a software application. It ensures that the application meets the specified requirements by executing predefined tests across various scenarios, identifying defects, and validating that the system works as intended.."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'SUITE NAME' AS markdown,
       'Title' AS title,
        'TEST CASES' AS markdown,
       1 AS search,
       1 AS sort;

with tbldata as (
SELECT
  prj1.title AS "Title" ,
  (select count(prj2.project_id) from qf_role_with_case prj2 where
  prj2.project_name=prj1.project_name
  and prj2.uniform_resource_id=prj1.uniform_resource_id
   ) as "TotalTestCases",
   prj1.suite_name,
   prj1.suite_date,
   prj1.created_by,
   prj1.suiteid,
   prj1.project_name,
   prj1.uniform_resource_id,
   prj1.rownum
FROM qf_role_with_suite prj1
WHERE prj1.project_name = $project_name  and prj1.uniform_resource_id=$uniform_resource_id )
select
    ${md.link(
      "suiteid",
      [
        "'suitecasedetailsreport.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "SUITE NAME" ,
   Title AS "TITLE",
${md.link(
      "TotalTestCases",
      [
        "'suitecasedetails.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "TEST CASES",
   suite_date as "CREATED DATE",
   created_by  as "CREATED BY"
  from tbldata
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
WHERE LOWER(execution_type) = 'failed'
AND project_name = $project_name
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER);
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
INNER JOIN qf_case_status_tap as qcs ON qrc.testcaseid=qcs.test_case_id
AND qcs.project_name=qrc.project_name
WHERE qrc.project_name = $project_name AND UPPER(execution_type)='AUTOMATION'
ORDER BY CAST(SUBSTR(testcaseid, INSTR(testcaseid, ' ') + 1) AS INTEGER);
```

```sql automationtestcasedetails.sql { route: { caption: "Automation Test Case Details" } }
-- @route.description "Displays detailed information for a selected test case, including its description, preconditions, execution steps, and expected results"

SELECT 'text' AS component,
$page_description AS contents_md;
${paginate("qf_role_with_case", "WHERE project_name = $project_name AND UPPER(execution_type)='AUTOMATION'")}
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
ORDER BY CAST(SUBSTR(test_case_id, INSTR(test_case_id, ' ') + 1) AS INTEGER)
${pagination.limit};
${pagination.navWithParams("project_name")};
```

```sql manual.sql { route: { caption: "Manual Test Cases" } }
-- @route.description "An overview of all test cases under type manual execution showing the test case ID, title, current status, and the latest execution cycle, allowing quick review and tracking of test case progress."
SELECT 'text' AS component,
$page_description AS contents_md;
${paginate("qf_role_with_case", "WHERE project_name = $project_name AND UPPER(execution_type)='MANUAL'")}
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
INNER JOIN qf_case_status_tap as qcs ON qrc.testcaseid=qcs.test_case_id
AND qcs.project_name=qrc.project_name
WHERE qrc.project_name = $project_name AND UPPER(execution_type)='MANUAL'
ORDER BY CAST(SUBSTR(testcaseid, INSTR(testcaseid, ' ') + 1) AS INTEGER)
${pagination.limit};
${pagination.navWithParams("project_name")};
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
       'SUITE' AS markdown,
       1 AS search,
       1 AS sort;
/*
with tblplansummary as (SELECT
    tbl.project_name,
    tbl.uniform_resource_id,
    tbl.rownum,
    tbl.planid,
    plan_date,
    created_by,
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
end AS "PLAN NAME",
plan_date AS "CREATED DATE",
created_by AS "CREATED BY"
from tblplansummary
where project_name=$project_name; */

with tblplansummary as (SELECT
    tbl.project_name,
    tbl.uniform_resource_id,
    tbl.rownum,
    tbl.planid,
    plan_date,
    created_by,
    (select count(*) from qf_role_with_suite where project_name = tbl.project_name  and uniform_resource_id=tbl.uniform_resource_id)
    AS "suite_count"
FROM qf_role_with_plan tbl)
select
   ${md.link(
      "planid",
      [
        "'plancasedetailsreport.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "PLAN NAME",
  ${md.link(
      "suite_count",
       [
        "'test-suite-cases.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "SUITE",
plan_date AS "CREATED DATE",
created_by AS "CREATED BY"
from tblplansummary
where project_name=$project_name
ORDER BY planid;

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

```sql chart/pie-chart-autostatus.sql { route: { caption: "" } }
SELECT 'chart' AS component,
       'pie' AS type,
       'Test Coverage(%)' AS title,
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

```sql issuedetails.sql { route: { caption: "Issue Details" } }
-- @route.description "Displays detailed information for a selected issue, including its description"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'list' AS component,
      'Issue Details' AS title;

SELECT
   'Description' AS title,
   testcase_description AS description,
   NULL AS link,
   NULL AS icon,
   NULL AS link_text,
   NULL AS target
FROM qf_issue_detail
WHERE project_name=$project_name AND testcase_id=$testcaseid AND id=$id

UNION ALL

SELECT
   'Assignee' AS title,
   assignee AS description,
   NULL AS link,
   NULL AS icon,
   NULL AS link_text,
   NULL AS target
FROM qf_issue_detail
WHERE project_name=$project_name AND testcase_id=$testcaseid AND id=$id

UNION ALL

SELECT
   'State' AS title,
   state AS description,
   NULL AS link,
   NULL AS icon,
   NULL AS link_text,
   NULL AS target
FROM qf_issue_detail
WHERE project_name=$project_name AND testcase_id=$testcaseid AND id=$id

UNION ALL

SELECT
   'Created at' AS title,
   strftime('%m-%d-%Y', DATE(created_at)) AS description,
   NULL AS link,
   NULL AS icon,
   NULL AS link_text,
   NULL AS target
FROM qf_issue_detail
WHERE project_name=$project_name AND testcase_id=$testcaseid AND id=$id

UNION ALL

SELECT
   'Author Association' AS title,
   author_association AS description,
   NULL AS link,
   NULL AS icon,
   NULL AS link_text,
   NULL AS target
FROM qf_issue_detail
WHERE project_name=$project_name AND testcase_id=$testcaseid AND id=$id

UNION ALL


SELECT
   'OWNER' AS title,
   owner AS description,
   NULL AS link,
   NULL AS icon,
   NULL AS link_text,
   NULL AS target
FROM qf_issue_detail
WHERE project_name=$project_name AND testcase_id=$testcaseid AND id=$id


UNION ALL

SELECT
   'Attachment' AS title,
   NULL AS description,
   attachment_url AS link,
   'paperclip' AS icon,
   'View Attachment' AS link_text,
   '_blank' AS target
FROM qf_issue_detail
WHERE project_name=$project_name AND testcase_id=$testcaseid
   AND attachment_url IS NOT NULL AND attachment_url != '' AND id=$id;
```

```sql requirementdetails.sql { route: { caption: "Requirement Details" } }

SELECT 'hero' AS component,
    'Requirement Detail' as title,
    $req as description,
    'blue' as color,
    'checklist' as icon;

SELECT 'card' AS component, 1 AS columns;
SELECT
    'Detailed Specification' as title,
    'Description and functional specification for ' || $req as description;

SELECT 'text' AS component,
       rd.description AS contents_md
FROM qf_plan_requirement_summary rs
INNER JOIN qf_plan_requirement_details rd
    ON rs.rownum = rd.rownum
WHERE rs.requirement_id LIKE '%' || $req || '%'
  AND (rs.project_name = $project_name OR rs.project_name = 'Unknown')
ORDER BY rd.rownumdetail;
```

```sql productivity.sql { route: { caption: "Productivity" } }

SELECT 'chart' AS component,
      'bar' AS type,
      'Assignee wise Productivity' AS title,
      TRUE AS labels,
      'green' AS color,
      TRUE AS stacked,
       TRUE AS toolbar,
        650                   as height,
       20 AS ystep;

SELECT
   latest_assignee AS label,
   COUNT(*) AS value
FROM
   qf_case_status
WHERE
   project_name = $project_name
GROUP BY
   latest_assignee
ORDER BY
   value DESC;
```

```sql suitecasedetailsreport.sql { route: { caption: "Suite Details" } }

SELECT 'hero' AS component,
    'Test Suite Specification' as title,
    COALESCE(
        (SELECT suite_name FROM qf_role_with_suite WHERE trim(rownum) = trim($id) LIMIT 1),
        'Suite: ' || $id
    ) as description,
    'purple' as color,
    'package' as icon;

SELECT 'card' AS component, 1 AS columns;
SELECT
    'Suite Content' as title,
    'Detailed scope and test case mapping' as description,
    'purple' as color,
    'list-check' as icon;

SELECT 'text' AS component,
       rd.description AS contents_md
FROM qf_suite_description_summary rs
INNER JOIN qf_suite_description_details rd
    ON rs.rownum = rd.rownum
WHERE trim(rs.rownum) = trim($id)
ORDER BY rd.rownumdetail;
```

```sql plancasedetailsreport.sql { route: { caption: "Plan Details" } }

SELECT 'hero' AS component,
    'Test Plan Specification' as title,
    COALESCE(
        (SELECT plan_name FROM qf_role_with_plan WHERE trim(rownum) = trim($id) LIMIT 1),
        'Plan: ' || $id
    ) as description,
    'green' as color,
    'file-text' as icon;

SELECT 'card' AS component, 1 AS columns;
SELECT
    'Plan Content' as title,
    'Complete test strategies and criteria' as description,
    'green' as color,
    'clipboard-list' as icon;

SELECT 'text' AS component,
       rd.description AS contents_md
FROM qf_plan_summary rs
INNER JOIN qf_plan_detail rd
    ON rs.rownum = rd.rownum
WHERE trim(rs.rownum) = trim($id)
ORDER BY rd.rownumdetail;
```

```sql test-suite-cases-summary.sql { route: { caption: "Test suite" } }
-- @route.description "Test suite is a collection of test cases designed to verify the functionality, performance, and security of a software application. It ensures that the application meets the specified requirements by executing predefined tests across various scenarios, identifying defects, and validating that the system works as intended.."
SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'table' AS component,
       'SUITE NAME' AS markdown,
       'Title' AS title,
        'TEST CASES' AS markdown,
       1 AS search,
       1 AS sort;

with tbldata as (
SELECT
  prj1.title AS "Title" ,
  (select count(prj2.project_id) from qf_role_with_case prj2 where
  prj2.project_name=prj1.project_name
  and prj2.uniform_resource_id=prj1.uniform_resource_id
   ) as "TotalTestCases",
   prj1.suite_name,
   prj1.suite_date,
   prj1.created_by,
   prj1.suiteid,
   prj1.project_name,
   prj1.uniform_resource_id,
   prj1.rownum
FROM qf_role_with_suite prj1
WHERE prj1.project_name = $project_name    )
select
    ${md.link(
      "suiteid",
      [
        "'suitecasedetailsreport.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "SUITE NAME" ,
   Title AS "TITLE",
${md.link(
      "TotalTestCases",
      [
        "'suitecasedetails.sql?project_name='",
        "project_name",
        "'&id='",
        "rownum","'&uniform_resource_id='","uniform_resource_id"
      ]
  )} AS "TEST CASES",
   suite_date as "CREATED DATE",
   created_by  as "CREATED BY"
  from tbldata
  ORDER BY suiteid
;
```

```sql trends.sql { route: { caption: "Test Case Trends Over Time" } }
-- @route.description "Display metrics such as test case count, passed, failed"

SELECT
    'chart' AS component,
    'ATest Case Trends Over Time (Total Count vs Passed vs Failed)' AS title,
    'scatter' AS type,
    'Passed Test Cases' AS xtitle,
    'Failed Test Cases' AS ytitle,
    500 AS height,
    8 AS marker,
    0 AS xmin,
    50 AS xmax,
    0 AS ymin,
    50 AS ymax,
    5 AS yticks;

-- Data for each assignee
SELECT
    latest_assignee AS series,
    COUNT(CASE WHEN LOWER(test_case_status) IN ('passed', 'ok') THEN 1 END) AS x,  -- Passed test cases on the x-axis
    COUNT(CASE WHEN LOWER(test_case_status) IN ('failed', 'not ok') THEN 1 END) AS y   -- Failed test cases on the y-axis
FROM
    qf_case_status_tap
WHERE
    project_name = $project_name
```
