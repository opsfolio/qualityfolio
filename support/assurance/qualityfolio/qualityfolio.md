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

```bash gitcommits -C --descr "Python script which is retriving git commits and pushing them to SQLite"
#!/usr/bin/env -S bash
set -euo pipefail

# Load .env if present
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
  exit 0
fi

python github_commit.py
```

```contribute sqlpage_files --base .
./index.bbd2bbc9.js .
./custom_diff.css .
./custom_diff.js .
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
       '© 2026 Qualityfolio. Test assurance as living Markdown.' AS footer ,
        '/custom_diff.css' AS css,
       '/custom_diff.js' AS javascript
       ;

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
        'list-check'       as icon,
       'test-cases.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_title, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_case_count
WHERE
  project_title = :project_name;

-- Passed Cases
SELECT '## Total Passed Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'shield-check' AS icon,
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
       'shield-x' AS icon,
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
    'trending-up'       as icon
FROM counts;

-- Open Defects
SELECT '## Open Defects' AS description_md,
       '# ' || COALESCE(COUNT(testcase_id), 0) AS description_md,
       'white' AS background_color,
         'orange' as color,
    'bug'       as icon,
       CASE WHEN COUNT(testcase_id) = 0 THEN NULL
       ELSE 'open.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23')
       END AS link
FROM qf_issue_detail
WHERE project_name = :project_name
AND state='open'
AND repo_name = COALESCE(sqlpage.environment_variable('GITHUB_REPOSITORY'), repo_name)
ORDER BY testcase_id;

-- Closed Defects
SELECT '## Closed Defects' AS description_md,
       '# ' || COALESCE(COUNT(testcase_id), 0) AS description_md,
       'white' AS background_color,
         'orange' as color,
        'bug-off'       as icon,
       CASE WHEN COUNT(testcase_id) = 0 THEN NULL
       ELSE 'closed.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23')
       END AS link
FROM qf_issue_detail
WHERE project_name = :project_name
AND state='closed'
AND repo_name = COALESCE(sqlpage.environment_variable('GITHUB_REPOSITORY'), repo_name)
ORDER BY testcase_id;


-- Test Cycle Plan for the month
SELECT '## Test Cycle Plan (Month)' AS description_md,
       '# ' || COALESCE(COUNT(*), 0) AS description_md,
       'white' AS background_color,
       'calendar-stats' AS icon,
       'orange' AS color,
       CASE WHEN COUNT(*) = 0 THEN NULL
       ELSE 'todo-cycle-month.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23')
       END AS link
FROM qf_role_with_evidence re
WHERE (re.status IS NULL OR LOWER(re.status) IN ('todo', 'to-do', 'to do'))
  AND re.project_name = :project_name
  AND STRFTIME('%m-%Y', COALESCE(DATE(re.cycledate), DATE(SUBSTR(re.cycledate,7,4)||'-'||SUBSTR(re.cycledate,1,2)||'-'||SUBSTR(re.cycledate,4,2)))) = STRFTIME('%m-%Y', 'now', 'localtime')
  AND NOT EXISTS (
      SELECT 1 FROM qf_tap_results tr
      WHERE UPPER(tr.test_case_id) = UPPER(re.testcaseid)
        AND tr.tap_date = re.cycledate
  );

-- Un assigned test cases
SELECT '## Unassigned Test Cases' AS description_md,
       '# ' || COALESCE(COUNT(test_case_id), 0) AS description_md,
       'white' AS background_color,
       'user-off' AS icon,
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
    'robot' AS icon;


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
    'user' AS icon;


--- Test suite count
SELECT '## Test Suite Count' AS description_md,
         '# ' || COALESCE(COUNT(suiteid), 0) AS description_md,
       'white' AS background_color,
          'pink' as color,
    'folders'       as icon,
       'test-suite-cases-summary.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link
FROM qf_role_with_suite
WHERE
  project_name = :project_name HAVING COUNT(suiteid) > 0;


-- Test plan count
SELECT '## Test Plan Count' AS description_md,
         '# ' || COALESCE(COUNT(planid), 0) AS description_md,
       'white' AS background_color,
       'clipboard-list'       as icon,
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
       'history' AS icon,
       'blue' AS color,
       'test-case-history.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link;

-- Analytics Tile
SELECT '## Analytics' AS description_md,
       'View Strategic Insights' AS description_md,
       'white' AS background_color,
       'chart-bar' AS icon,
       'blue' AS color,
       'analytics.sql?project_name=' ||
           REPLACE(REPLACE(REPLACE(:project_name, ' ', '%20'), '&', '%26'), '#', '%23') AS link;


-- -- Recent Commit Changes
-- SELECT '## Recent Commit Changes' AS description_md,
--        'white' AS background_color,
--        'git-commit' AS icon,
--        'teal' AS color,
--        'github-commit-changes.sql' AS link
-- WHERE EXISTS (SELECT 1 FROM sqlite_master WHERE type IN ('table','view') AND name = 'github_commits');

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

``````sql github-commit-changes.sql { route: { caption: "Commit Changes" } }
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



SELECT 'title' AS component,
       'Commit Details: ' || coalesce($sha, :sha) AS title;

SELECT 'text' AS component;

SELECT
    '### 📄 ' || filename || char(10) || char(10) ||
    '**Additions:** `+' || additions || '` | **Deletions:** `-' || deletions || '`' || char(10) || char(10) ||
    '`````diff' || char(10) || coalesce(patch, 'No patch details available') || char(10) || '`````' || char(10) || '---' AS contents_md
FROM commit_files
WHERE commit_sha = coalesce($sha, :sha);




``````

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
    latest_cycle AS "Latest Cycle",
    priority AS "Priority",
    tags AS "Tags",
    scenario_type AS "Scenario Type",
    execution_type AS "Execution Type",
    test_type AS "Test Type"
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
       latest_cycle AS "Latest Cycle",
       priority AS "Priority",
       tags AS "Tags",
       scenario_type AS "Scenario Type",
       execution_type AS "Execution Type",
       test_type AS "Test Type"
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
       latest_cycle AS "Latest Cycle",
       priority AS "Priority",
       tags AS "Tags",
       scenario_type AS "Scenario Type",
       execution_type AS "Execution Type",
       test_type AS "Test Type"
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
       latest_cycle AS "Latest Cycle",
       priority AS "Priority",
       tags AS "Tags",
       scenario_type AS "Scenario Type",
       execution_type AS "Execution Type",
       test_type AS "Test Type"
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
       latest_cycle AS "Latest Cycle",
       priority AS "Priority",
       tags AS "Tags",
       scenario_type AS "Scenario Type",
       execution_type AS "Execution Type",
       test_type AS "Test Type"
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
       repo_name AS "Repository",
     JSON('{"name":"EXTERNAL REFERENCE","tooltip":"VIEW EXTERNAL REFERENCE","link":"' || html_url || '","icon":"brand-github","target":"_blank"}') as _sqlpage_actions


FROM qf_issue_detail
WHERE project_name = $project_name
AND state='closed'
AND repo_name = COALESCE(sqlpage.environment_variable('GITHUB_REPOSITORY'), repo_name)
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
       repo_name AS "Repository",
     JSON('{"name":"EXTERNAL REFERENCE","tooltip":"VIEW EXTERNAL REFERENCE","link":"' || html_url || '","icon":"brand-github","target":"_blank"}') as _sqlpage_actions


FROM qf_issue_detail
WHERE project_name = $project_name
AND state='open'
AND repo_name = COALESCE(sqlpage.environment_variable('GITHUB_REPOSITORY'), repo_name)
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
       'Run Details' AS markdown,
       'Test Cases' AS title,
       1 AS search,
       1 AS sort;

-- De-duplicate per testcaseid within the requested cycle (pick latest rn),
-- then resolve the status the same way the history-summary page does.
-- Additional dedup on the join to qf_role_with_case_history ensures no duplicates.
WITH ranked_history AS (
  SELECT
    tbl.testcaseid,
    tbl.uniform_resource_id,
    tbl.cycle,
    tbl.project_name,
    COALESCE(
      (
        SELECT tr.status
        FROM qf_tap_results tr
        WHERE UPPER(tr.test_case_id) = UPPER(tbl.testcaseid)
          AND COALESCE(DATE(tr.tap_date), DATE(SUBSTR(tr.tap_date,7,4)||'-'||SUBSTR(tr.tap_date,1,2)||'-'||SUBSTR(tr.tap_date,4,2))) = 
              COALESCE(DATE(tbl.cycledate), DATE(SUBSTR(tbl.cycledate,7,4)||'-'||SUBSTR(tbl.cycledate,1,2)||'-'||SUBSTR(tbl.cycledate,4,2)))
        ORDER BY tr.ingest_session_id DESC
        LIMIT 1
      ),
      tbl.status
    ) AS status_refined,
    ROW_NUMBER() OVER (
      PARTITION BY tbl.testcaseid, tbl.cycle, tbl.project_name
      ORDER BY tbl.rn DESC
    ) AS row_num
  FROM qf_role_with_evidence_history tbl
  WHERE tbl.project_name = $project_name
    AND ($cycle IS NULL OR tbl.cycle = $cycle)
),
deduped AS (
  SELECT
    rh.testcaseid,
    rh.uniform_resource_id,
    rh.cycle,
    rh.project_name,
    rh.status_refined,
    tbl2.title,
    ROW_NUMBER() OVER (
      PARTITION BY rh.testcaseid
      ORDER BY rh.row_num
    ) AS final_rn
  FROM ranked_history rh
  INNER JOIN qf_role_with_case_history tbl2
    ON rh.testcaseid = tbl2.testcaseid
   AND rh.uniform_resource_id = tbl2.uniform_resource_id
  WHERE rh.row_num = 1
    AND (
      $status IS NULL
      OR LOWER(rh.status_refined) = LOWER($status)
      OR (LOWER($status) = 'passed' AND LOWER(rh.status_refined) = 'ok')
      OR (LOWER($status) = 'failed' AND LOWER(rh.status_refined) = 'not ok')
    )
)
SELECT
  ${md.link("d.testcaseid",
      ["'testcasedetails.sql?testcaseid='", "d.testcaseid",
       "'&project_name='", "$project_name"])} AS "Test Case ID",
  d.title AS "Title",
  d.status_refined AS "Status",
  d.cycle AS "Latest Cycle",
  CASE
    WHEN EXISTS (
        SELECT 1 FROM qf_run_details rd 
        WHERE UPPER(rd.test_case_id) = UPPER(d.testcaseid)
          AND rd.run_cycle = d.cycle
    )
    THEN '[▶ View Details](rundetails.sql?testcaseid=' || d.testcaseid || '&project_name=' || d.project_name || '&cycle=' || d.cycle || ')'
    ELSE ''
  END AS "Run Details"
FROM deduped d
WHERE d.final_rn = 1
ORDER BY CAST(SUBSTR(d.testcaseid, INSTR(d.testcaseid, '-') + 1) AS INTEGER);
```

## Run Details

```sql rundetails.sql { route: { caption: "Run Details" } }
-- @route.description "Displays detailed run execution information for a selected test case, including actual results, run summary, and step-wise execution status"

SELECT 'text' AS component,
$page_description AS contents_md;

-- Run Details Summary Card
SELECT 'card' AS component,
       'Run Execution Summary' AS title,
       1 AS columns;

SELECT
  'Test Case: ' || test_case_id AS title,
  '**Status:** ' || COALESCE(UPPER(overall_status), 'N/A') || '

' ||
  '**Description:** ' || COALESCE(test_description, 'N/A') || '

' ||
  '**Duration:** ' || COALESCE(total_duration, 'N/A') || '

' ||
  '**Start Time:** ' || COALESCE(start_time, 'N/A') || '

' ||
  '**End Time:** ' || COALESCE(end_time, 'N/A')
  AS description_md,
  CASE WHEN overall_status = 'passed' THEN 'green'
       WHEN overall_status = 'failed' THEN 'red'
       ELSE 'azure' END AS color
FROM qf_run_details
WHERE UPPER(test_case_id) = UPPER($testcaseid)
  AND run_cycle = $cycle
LIMIT 1;

-- Actual Result
SELECT 'card' AS component,
       'Actual Result' AS title,
     1 AS columns
WHERE EXISTS (SELECT 1 FROM qf_run_details WHERE UPPER(test_case_id) = UPPER($testcaseid) AND run_cycle = $cycle AND actual_result IS NOT NULL);

SELECT
  actual_result AS description_md
FROM qf_run_details
WHERE UPPER(test_case_id) = UPPER($testcaseid)
  AND run_cycle = $cycle
  AND actual_result IS NOT NULL
LIMIT 1;

-- Run Summary
SELECT 'card' AS component,
       'Run Summary' AS title,
       1 AS columns
WHERE EXISTS (SELECT 1 FROM qf_run_details WHERE UPPER(test_case_id) = UPPER($testcaseid) AND run_cycle = $cycle AND run_summary IS NOT NULL);

SELECT
  run_summary AS description_md
FROM qf_run_details
WHERE UPPER(test_case_id) = UPPER($testcaseid)
  AND run_cycle = $cycle
  AND run_summary IS NOT NULL
LIMIT 1;

-- Steps Table
SELECT 'table' AS component,
       'Execution Steps' AS title,
       'No steps found.' AS empty_title,
       1 AS sort;

SELECT
  json_extract(step.value, '$.step') AS "Step #",
  json_extract(step.value, '$.stepname') AS "Step Name",
  UPPER(json_extract(step.value, '$.status')) AS "Status",
  json_extract(step.value, '$.start_time') AS "Start Time",
  json_extract(step.value, '$.end_time') AS "End Time",
  CASE
    WHEN json_extract(step.value, '$.error_message') IS NOT NULL
      AND json_extract(step.value, '$.error_message') <> ''
    THEN json_extract(step.value, '$.error_message')
    ELSE '-'
  END AS "Error"
FROM qf_run_details rd,
     json_each(rd.steps) AS step
WHERE UPPER(rd.test_case_id) = UPPER($testcaseid)
  AND rd.run_cycle = $cycle
  AND rd.steps IS NOT NULL
ORDER BY CAST(json_extract(step.value, '$.step') AS INTEGER);
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
       latest_cycle AS "Latest Cycle",
       priority AS "Priority",
       tags AS "Tags",
       scenario_type AS "Scenario Type",
       execution_type AS "Execution Type",
       test_type AS "Test Type"
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
-- @route.description "Provides a cycle-wise summary of test execution, showing total test cases and status-wise counts (passed, failed), with optional date-range filtering to analyze results by cycle creation and ingestion time."

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
  COALESCE(
    (
      SELECT tr.status
      FROM qf_tap_results tr
      WHERE UPPER(tr.test_case_id) = UPPER(tbl.testcaseid)
        AND COALESCE(DATE(tr.tap_date), DATE(SUBSTR(tr.tap_date,7,4)||'-'||SUBSTR(tr.tap_date,1,2)||'-'||SUBSTR(tr.tap_date,4,2))) = 
            COALESCE(DATE(tbl.cycledate), DATE(SUBSTR(tbl.cycledate,7,4)||'-'||SUBSTR(tbl.cycledate,1,2)||'-'||SUBSTR(tbl.cycledate,4,2)))
      ORDER BY tr.ingest_session_id DESC
      LIMIT 1
    ),
    tbl.status
  ) AS status,

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
    SUM(CASE WHEN LOWER(tbl2.status) IN ('passed', 'ok')  THEN 1 ELSE 0 END) AS passed_cases,
    SUM(CASE WHEN LOWER(tbl2.status) IN ('failed', 'not ok')  THEN 1 ELSE 0 END) AS failed_cases,
    SUM(CASE WHEN tbl2.status='reopen'  THEN 1 ELSE 0 END) AS reopen_cases,
    SUM(CASE WHEN tbl2.status='closed'  THEN 1 ELSE 0 END) AS closed_cases

  FROM tblevidence tbl2
  GROUP BY tbl2.cycle, tbl2.cycledate, tbl2.project_name

) tbl3

WHERE
(
  COALESCE(DATE(tbl3.cycledate), DATE(SUBSTR(tbl3.cycledate,7,4)||'-'||SUBSTR(tbl3.cycledate,1,2)||'-'||SUBSTR(tbl3.cycledate,4,2))) >= DATE(COALESCE(NULLIF($from_date, ''), date('now', 'localtime', 'start of month')))
)
AND
(
  COALESCE(DATE(tbl3.cycledate), DATE(SUBSTR(tbl3.cycledate,7,4)||'-'||SUBSTR(tbl3.cycledate,1,2)||'-'||SUBSTR(tbl3.cycledate,4,2))) <= DATE(COALESCE(NULLIF($to_date, ''), date('now', 'localtime', 'start of month', '+1 month', '-1 day')))
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

INSERT INTO qf_testcase_comments (testcase_id, comment_text, created_by)
SELECT $testcaseid, :new_comment, COALESCE(sqlpage.user_info('name'), sqlpage.user_info('email'), 'Anonymous User')
WHERE :new_comment IS NOT NULL AND TRIM(:new_comment) <> '';

SELECT 'tab' as component;
SELECT 'Details' as title, 'testcasedetails.sql?testcaseid=' || $testcaseid || '&project_name=' || $project_name || '&tab=Details' as link, :tab = 'Details' as active, 'file-text' as icon;
SELECT 'Revision History' as title, 'testcasedetails.sql?testcaseid=' || $testcaseid || '&project_name=' || $project_name || '&tab=Revision History' as link, :tab = 'Revision History' as active, 'history' as icon
WHERE EXISTS (SELECT 1 FROM qf_github_commits LIMIT 1);

-- Details Tab Content
SELECT 'text' AS component, $page_description AS contents_md WHERE :tab = 'Details';

SELECT 'card' AS component,
       'Test Cases Metadata' AS title,
       5 AS columns
WHERE :tab = 'Details';

SELECT 'Priority' AS title, priority AS description, 'flag' AS icon FROM qf_role_with_case WHERE testcaseid = $testcaseid AND project_name = $project_name AND :tab = 'Details';
SELECT 'Test Type' AS title, test_type AS description, 'category' AS icon FROM qf_role_with_case WHERE testcaseid = $testcaseid AND project_name = $project_name AND :tab = 'Details';
SELECT 'Scenario Type' AS title, scenario_type AS description, 'hierarchy' AS icon FROM qf_role_with_case WHERE testcaseid = $testcaseid AND project_name = $project_name AND :tab = 'Details';
SELECT 'Execution Type' AS title, execution_type AS description, 'settings' AS icon FROM qf_role_with_case WHERE testcaseid = $testcaseid AND project_name = $project_name AND :tab = 'Details';
SELECT 'Tags' AS title, tags AS description, 'tags' AS icon FROM qf_role_with_case WHERE testcaseid = $testcaseid AND project_name = $project_name AND :tab = 'Details';

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

-- Comments Section (under Details)
SELECT 'form' AS component, 'Add Comment' AS validate, 'testcasedetails.sql?testcaseid=' || $testcaseid || '&project_name=' || $project_name || '&tab=Details' AS action, 'comment-form' AS id WHERE :tab = 'Details';
SELECT 'new_comment' AS name, 'Write your comment here...' AS placeholder, 'textarea' AS type, '' AS label, 12 AS width WHERE :tab = 'Details';

SELECT 'html' AS component;
SELECT '
<style>
#comment-form button[type=submit] { opacity: 0.5; cursor: not-allowed; }
.comments-table td:first-child { word-break: break-word; white-space: normal; max-width: 500px; }
</style>
<script>
(function() {
  var poll = setInterval(function() {
    var form = document.getElementById("comment-form");
    if (!form) return;
    var textarea = form.querySelector("textarea[name=new_comment]");
    var btn = form.querySelector("button[type=submit]");
    if (!textarea || !btn) return;
    clearInterval(poll);
    btn.disabled = true;
    btn.style.opacity = "0.5";
    btn.style.cursor = "not-allowed";
    textarea.addEventListener("focus", function() {
      btn.disabled = false;
      btn.style.opacity = "1";
      btn.style.cursor = "pointer";
    });
    textarea.addEventListener("blur", function() {
      if (textarea.value.trim().length === 0) {
        btn.disabled = true;
        btn.style.opacity = "0.5";
        btn.style.cursor = "not-allowed";
      }
    });
  }, 100);
})();
</script>
' AS html WHERE :tab = 'Details';

SELECT 'table' AS component, 'Comments' AS title, 'No comments yet.' AS empty_title, 'comments-table' AS class WHERE :tab = 'Details';
SELECT comment_text AS "Comment", created_by AS "User", strftime('%m-%d-%Y', created_at) AS "Date",
  CASE
    WHEN CAST(strftime('%H', created_at) AS INTEGER) = 0 THEN '12:' || strftime('%M:%S', created_at) || ' AM'
    WHEN CAST(strftime('%H', created_at) AS INTEGER) < 12 THEN CAST(strftime('%H', created_at) AS INTEGER) || ':' || strftime('%M:%S', created_at) || ' AM'
    WHEN CAST(strftime('%H', created_at) AS INTEGER) = 12 THEN '12:' || strftime('%M:%S', created_at) || ' PM'
    ELSE CAST(CAST(strftime('%H', created_at) AS INTEGER) - 12 AS TEXT) || ':' || strftime('%M:%S', created_at) || ' PM'
  END AS "Time"
FROM qf_testcase_comments 
WHERE testcase_id = $testcaseid
  AND :tab = 'Details' 
ORDER BY created_at DESC;


SELECT 'table' AS component, 'Test Cases' AS title
WHERE :tab = 'Revision History'
  AND EXISTS (SELECT 1 FROM qf_github_commits LIMIT 1);


select
/*${md.link("commit_sha", ["'testcaserevisiondetails.sql?commit_sha='", "cf.commit_sha", "'&project_name='", "$project_name"])} AS "Revisions" */
hc.message as "Commit Message",
hc.author_name as "Author",
 strftime('%d-%m-%Y %H:%M', hc.commit_date) as "Commit Date",
JSON('{"name":"Commit URL", "tooltip":"View Commit in GitHub", "link":"' || hc.html_url || '", "icon":"brand-github", "target":"_blank"}') as "_sqlpage_actions"
from qf_github_commits hc
inner join commit_files cf on cf.commit_sha=hc.sha
where cf.filename=(select cm.file_basename from qf_case_master cm
 where cm.test_case_id=$testcaseid
  limit 1
 )
 and  :tab = 'Revision History'
 AND EXISTS (SELECT 1 FROM qf_github_commits LIMIT 1);

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
    qcs.latest_cycle AS "Latest Cycle",
    qcs.priority AS "Priority",
    qcs.tags AS "Tags",
    qcs.scenario_type AS "Scenario Type",
    qcs.test_type AS "Test Type"
FROM qf_role_with_case as qrc
INNER JOIN qf_case_status_tap as qcs ON qrc.testcaseid=qcs.test_case_id
AND qcs.project_name=qrc.project_name
WHERE qrc.project_name = $project_name AND UPPER(qrc.execution_type)='AUTOMATION'
ORDER BY CAST(SUBSTR(testcaseid, INSTR(testcaseid, ' ') + 1) AS INTEGER);
```

```sql automationtestcasedetails.sql { route: { caption: "Automation Test Case Details" } }
-- @route.description "Displays detailed information for a selected test case, including its description, preconditions, execution steps, and expected results"

SELECT 'text' AS component,
$page_description AS contents_md;
${paginate("qf_role_with_case", "WHERE project_name = $project_name AND UPPER(execution_type)='AUTOMATION'")}
SELECT 'card' AS component,
       'Test Cases Metadata' AS title,
       5 AS columns;

SELECT 'Priority' AS title, qwc.priority AS description, 'flag' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='AUTOMATION';
SELECT 'Test Type' AS title, qwc.test_type AS description, 'category' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='AUTOMATION';
SELECT 'Scenario Type' AS title, qwc.scenario_type AS description, 'hierarchy' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='AUTOMATION';
SELECT 'Execution Type' AS title, qwc.execution_type AS description, 'settings' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='AUTOMATION';
SELECT 'Tags' AS title, qwc.tags AS description, 'tags' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='AUTOMATION';

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
    qcs.latest_cycle AS "Latest Cycle",
    qcs.priority AS "Priority",
    qcs.tags AS "Tags",
    qcs.scenario_type AS "Scenario Type",
    qcs.test_type AS "Test Type"
FROM qf_role_with_case as qrc
INNER JOIN qf_case_status_tap as qcs ON qrc.testcaseid=qcs.test_case_id
AND qcs.project_name=qrc.project_name
WHERE qrc.project_name = $project_name AND UPPER(qrc.execution_type)='MANUAL'
ORDER BY CAST(SUBSTR(testcaseid, INSTR(testcaseid, ' ') + 1) AS INTEGER)
${pagination.limit};
${pagination.navWithParams("project_name")};
```

```sql manaultestcasedetails.sql { route: { caption: "Manual Test Case Details" } }
-- @route.description "Displays detailed information for a selected test case, including its description, preconditions, execution steps, and expected results"

SELECT 'text' AS component,
$page_description AS contents_md;

SELECT 'card' AS component,
       'Test Cases Metadata' AS title,
       5 AS columns;

SELECT 'Priority' AS title, qwc.priority AS description, 'flag' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='MANUAL';
SELECT 'Test Type' AS title, qwc.test_type AS description, 'category' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='MANUAL';
SELECT 'Scenario Type' AS title, qwc.scenario_type AS description, 'hierarchy' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='MANUAL';
SELECT 'Execution Type' AS title, qwc.execution_type AS description, 'settings' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='MANUAL';
SELECT 'Tags' AS title, qwc.tags AS description, 'tags' AS icon FROM qf_case_master as qcm INNER JOIN qf_role_with_case as qwc ON qcm.test_case_id=qwc.testcaseid WHERE qcm.test_case_id = $testcaseid AND qwc.project_name=$project_name AND UPPER(qwc.execution_type)='MANUAL';

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

```sql analytics.sql { route: { caption: "Analytics" } }
-- @route.description "Strategic insights and test metrics visualizations"

-- Side-by-Side Horizontal Layout: Pyramid (Left) | Execution (Right)
SELECT 'title' AS component, 'Strategic Analytics' AS contents;

SELECT 'html' AS component, '<div class="row" style="align-items:stretch;">' AS html;

--- LEFT COLUMN: Testing Pyramid (%) ---
WITH dynamic_data AS (
    SELECT test_type AS label, COUNT(*) AS val
    FROM qf_role_with_case 
    WHERE project_name = $project_name AND test_type IS NOT NULL AND test_type <> ''
    GROUP BY test_type
),
totals AS (
    SELECT SUM(val) as grand_total FROM dynamic_data
),
ranked_data AS (
    SELECT 
        label, val, (val * 100.0 / (SELECT grand_total FROM totals)) as pct,
        ROW_NUMBER() OVER (ORDER BY val ASC) as rank
    FROM dynamic_data
),
cumulative_data AS (
    SELECT 
        label, pct, rank,
        COALESCE(SUM(pct) OVER (ORDER BY rank ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) / 100.0 AS y_top,
        SUM(pct) OVER (ORDER BY rank) / 100.0 AS y_bottom,
        CASE (rank % 5)
            WHEN 1 THEN '#28a745' WHEN 2 THEN '#ffc107' WHEN 3 THEN '#fd7e14' WHEN 4 THEN '#17a2b8' ELSE '#6f42c1'
        END AS layer_color
    FROM ranked_data
)
SELECT 
    'html' AS component,
    COALESCE(
        (SELECT '
        <style>
            .analytics-card-left {
                padding: 30px;
                background: #ffffff;
                border: 1px solid #e3e6f0;
                border-radius: 12px;
                flex: 1;
                display: flex;
                flex-direction: column;
                align-items: center;
            }
            .pyramid-wrapper-v3 {
                display: flex;
                width: 100%;
                max-width: 780px;
                height: 380px;
                margin-top: 10px;
                position: relative;
            }
            .pyramid-vis-center {
                width: 280px;
                display: flex;
                flex-direction: column;
                align-items: center;
                position: relative;
                height: 360px;
            }
            .pyramid-labels-right {
                flex: 1;
                position: relative;
                height: 360px;
            }
            .pyramid-layer-v3 {
                width: 100%;
                display: flex;
                justify-content: center;
                align-items: center;
                position: relative;
            }
            .callout-box-abs {
                position: absolute;
                display: flex;
                align-items: center;
                transform: translateY(-50%);
                color: #2c3e50;
                font-weight: 700;
                font-size: 0.85rem;
                white-space: nowrap;
            }
            .callout-connector {
                height: 2px;
                margin-right: 10px;
                border-radius: 1px;
            }
        </style>
        <div class="col-md-6" style="display:flex; flex-direction:column;">
        <div class="analytics-card-left">
            <h3 style="color:#4e73df; font-weight:800; margin-bottom:10px;">Testing Pyramid (%)</h3>
            <div class="pyramid-wrapper-v3">
                <div class="pyramid-vis-center">' ||
            (SELECT group_concat(layer_html, '') FROM (
                SELECT 
                    '<div class="pyramid-layer-v3" style="' ||
                    'height:' || pct || '%;' ||
                    'background:' || layer_color || ';' ||
                    'clip-path: polygon(' || (50 - (y_top * 50)) || '% 0%, ' || (50 + (y_top * 50)) || '% 0%, ' || (50 + (y_bottom * 50)) || '% 100%, ' || (50 - (y_bottom * 50)) || '% 100%);' ||
                    '"></div>' AS layer_html
                FROM cumulative_data
                ORDER BY rank ASC
            )) ||
            '</div>
                <div class="pyramid-labels-right">' ||
            (SELECT group_concat(label_html, '') FROM (
                SELECT 
                    '<div class="callout-box-abs" style="top:' || (y_top + pct/2) || '%; ' || 
                    (CASE (100 - rank) % 3 
                        WHEN 0 THEN 'padding-left: 220px;' 
                        WHEN 1 THEN 'padding-left: 110px;' 
                        ELSE '' 
                    END) || '">' ||
                    '<div class="callout-connector" style="background:' || layer_color || '; width: ' || 
                    (CASE (100 - rank) % 3 
                        WHEN 0 THEN 255 
                        WHEN 1 THEN 145 
                        ELSE 35 
                    END) || 'px;"></div>' ||
                    '<span>' || label || ' (' || PRINTF("%.1f", pct) || '%)</span>' ||
                    '</div>' AS label_html
                FROM (SELECT *, (SELECT COUNT(*) FROM cumulative_data) as total FROM cumulative_data)
                ORDER BY rank ASC
            )) ||
            '</div>
            </div>
        </div></div>' FROM cumulative_data LIMIT 1),
        '<div class="col-md-6"><div class="card p-3" style="height:520px;display:flex;align-items:center;justify-content:center;"><h4 style="color:#999;">No Data</h4></div></div>'
    ) AS html;

SELECT 'html' AS component, '<style>.analytics-chart-col { display:flex; flex-direction:column; } .analytics-chart-col .card { flex:1; height:100% !important; }</style><div class="col-md-6 analytics-chart-col">' AS html;

--- RIGHT COLUMN: Execution Bar Chart ---
SELECT 'chart' AS component, 'bar' AS type, 'Execution Volume by Cycle' AS title, 480 AS height;
WITH cycle_stats AS (
    SELECT 
        cycle,
        STRFTIME('%Y-%m', COALESCE(DATE(cycledate), DATE(SUBSTR(cycledate,7,4)||'-'||SUBSTR(cycledate,1,2)||'-'||SUBSTR(cycledate,4,2)))) AS month_key,
        CASE STRFTIME('%m', COALESCE(DATE(cycledate), DATE(SUBSTR(cycledate,7,4)||'-'||SUBSTR(cycledate,1,2)||'-'||SUBSTR(cycledate,4,2))))
            WHEN '01' THEN 'January' WHEN '02' THEN 'February' WHEN '03' THEN 'March'
            WHEN '04' THEN 'April' WHEN '05' THEN 'May' WHEN '06' THEN 'June'
            WHEN '07' THEN 'July' WHEN '08' THEN 'August' WHEN '09' THEN 'September'
            WHEN '10' THEN 'October' WHEN '11' THEN 'November' WHEN '12' THEN 'December'
        END || ' ' || STRFTIME('%Y', COALESCE(DATE(cycledate), DATE(SUBSTR(cycledate,7,4)||'-'||SUBSTR(cycledate,1,2)||'-'||SUBSTR(cycledate,4,2)))) AS month_name,
        COALESCE(DATE(cycledate), DATE(SUBSTR(cycledate,7,4)||'-'||SUBSTR(cycledate,1,2)||'-'||SUBSTR(cycledate,4,2))) as date_val,
        COUNT(DISTINCT testcaseid) AS test_count
    FROM qf_role_with_evidence_history h
    INNER JOIN qf_markdown_master m ON h.file_basename = m.file_basename
    WHERE h.project_name = $project_name AND h.cycle IS NOT NULL
      AND STRFTIME('%Y', COALESCE(DATE(h.cycledate), DATE(SUBSTR(h.cycledate,7,4)||'-'||SUBSTR(h.cycledate,1,2)||'-'||SUBSTR(h.cycledate,4,2)))) = STRFTIME('%Y', 'now', 'localtime')
    GROUP BY h.cycle, month_key, month_name, date_val
),
ranked_cycles AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY month_key ORDER BY date_val ASC, cycle ASC) as cycle_num
    FROM cycle_stats
)
SELECT 
    month_name AS x,
    cycle AS series,
    test_count AS value,
    CASE cycle_num
        WHEN 1 THEN 'blue'
        ELSE 'yellow'
    END AS color
FROM ranked_cycles
ORDER BY date_val ASC, cycle ASC;

SELECT 'html' AS component, '</div></div>' AS html;
```
