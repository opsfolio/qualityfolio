-- Settings page for managing master data - UI matching entries.sql design system
SELECT 'shell' AS component,
       'Qualityfolio AI' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
       json_array(
           json_object('title', 'Generator', 'link', 'entries.sql',   'icon', 'pencil'),
           json_object('title', 'Markdown Editor', 'link', 'md_editor.sql', 'icon', 'file-text'),
           json_object('title', 'View Dashboard',  'link', 'dashboard.sql',  'icon', 'chart-line'),
          json_object('title', 'Settings',  'link', 'settings.sql',  'icon', 'settings')
       ) AS menu_item,
        json_array(
             '/js/layout.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/js/chat.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/js/settings.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS javascript,
        json_array(
             '/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
             '/css/chat.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT)
        ) AS css,
        '/images/favicon.ico' AS favicon,
        '© 2026 Qualityfolio. Test assurance as living Markdown.' AS footer;

-- ============================================
-- DESIGN SYSTEM (matching entries.sql exactly)
-- ============================================
SELECT 'html' AS component, '
<style>
  /* ============================================
     VARIABLES & FOUNDATIONS (mirrored from entries.sql)
     ============================================ */
  :root {
    --primary: #2563eb;
    --primary-dark: #1d4ed8;
    --primary-light: #dbeafe;
    --accent: #0ea5e9;
    --success: #10b981;
    --warning: #f59e0b;
    --danger: #ef4444;
    --slate-50: #f8fafc;
    --slate-100: #f1f5f9;
    --slate-200: #e2e8f0;
    --slate-300: #cbd5e1;
    --slate-500: #64748b;
    --slate-700: #334155;
    --slate-900: #0f172a;
    --text-primary: #0f172a;
    --text-secondary: #475569;
    --border: #e2e8f0;
    --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
    --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
    --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
  }

  /* ============================================
     GLOBAL STYLES
     ============================================ */
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", "Helvetica Neue", sans-serif; color: var(--text-primary); background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%); line-height: 1.6; }

  /* ============================================
     LAYOUT & CONTAINERS
     ============================================ */
  .cfg-wrap { width: 100%; margin: 0 auto; padding: 32px 24px; }
  .cfg-title-block { text-align: center; animation: slideDown 0.6s ease-out; margin-bottom: 28px; }
  .cfg-title-block h1 { font-weight: 400; color: var(--text-primary); }
  .cfg-title-block p { color: var(--text-secondary); font-size: 0.8rem; font-weight: 400; }
  @keyframes slideDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

  /* ============================================
     CARD STRUCTURE (identical to entries.sql)
     ============================================ */
  .cfg-card {background: #ffffff;padding: 20px;display: flex;flex-direction: column;overflow: hidden;animation: fadeIn 0.5s ease-out 0.1s both;border-radius: 0 0 12px 12px;border: 1.5px solid var(--border);box-shadow: var(--shadow-sm);margin-bottom: 20px; }
  .cfg-card-title { font-size: 0.875rem; font-weight: 700; color: var(--slate-500); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 4px; }
  .cfg-card-desc { font-size: 0.8rem; color: var(--text-secondary); margin-bottom: 20px; }

  /* ============================================
     TABS
     ============================================ */
  .cfg-tab-bar {display: flex;background: #ffffff;box-shadow: var(--shadow-sm);flex-wrap: wrap;animation: fadeIn 0.5s ease-out 0.05s both; }
  .cfg-tab-btn { padding: 9px 16px; border: none; background: transparent; color: var(--text-secondary); font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: all 0.2s ease; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; white-space: nowrap; }
  .cfg-tab-btn:hover { background: var(--slate-100); color: var(--text-primary); border-radius: 10px 10px 0 0;}
  .cfg-tab-btn.active {box-shadow: var(--shadow-sm);background: oklch(67.66% .1481 238.14) !important;border-radius: 10px 10px 0 0;color: #FFF !important;}
  .cfg-tab-btn .cfg-tab-icon { font-size: 0.9rem; }

  /* ============================================
     BACK BUTTON
     ============================================ */
  .cfg-back-btn { display: inline-flex; align-items: center; gap: 6px; padding: 7px 14px; background: var(--slate-100); color: var(--text-secondary); border: 1px solid var(--border); border-radius: 8px; font-size: 0.82rem; font-weight: 600; text-decoration: none; transition: all 0.2s ease; margin-bottom: 20px; }
  .cfg-back-btn:hover { background: var(--slate-200); transform: translateY(-1px); text-decoration: none; color: var(--text-primary); }

  /* ============================================
     SUCCESS ALERT
     ============================================ */
  .cfg-alert { display: flex; align-items: center; gap: 12px; background: linear-gradient(135deg, #ecfdf5 0%, #e0f9f7 100%); border: 1.5px solid #6ee7b7; border-radius: 10px; padding: 14px 18px; margin-bottom: 20px; color: #065f46; font-size: 0.875rem; font-weight: 600; animation: slideDown 0.4s ease-out; }
  .cfg-alert-icon { font-size: 1.1rem; }

  /* ============================================
     TABLE STRUCTURE
     ============================================ */
  .cfg-table-wrap { display: block; width: 100%; overflow-x: auto; margin-bottom: 0; }
  .cfg-table { width: 100%; border-collapse: collapse; }
  .cfg-table thead { background: var(--slate-100); }
  .cfg-table th { padding: 12px 16px; font-weight: 600; text-align: left; font-size: 0.8rem; color: var(--text-secondary); border-bottom: 1.5px solid var(--border); }
  .cfg-table td { padding: 14px 16px; border-bottom: 1px solid var(--border); font-size: 0.875rem; color: var(--text-primary); }
  .cfg-table tbody tr:hover { background: #fafbfc; }
  .cfg-table-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
  .cfg-table-header-title { font-weight: 600; color: var(--text-primary); font-size: 0.875rem; }
  .cfg-table-search { padding: 7px 12px; border: 1.5px solid var(--border); border-radius: 8px; font-size: 0.85rem; width: 200px; transition: all 0.2s; }
  .cfg-table-search:focus { outline: none; border-color: var(--primary); background: #fff; box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1); }
  .cfg-name-cell { font-weight: 600; color: var(--text-primary); }
  .cfg-date-cell { color: var(--slate-500); font-size: 0.85rem; }
  .cfg-actions-cell { display: flex; gap: 8px; }

  /* ============================================
     BUTTONS
     ============================================ */
  .btn { display: inline-block; padding: 8px 14px; border-radius: 8px; font-weight: 600; font-size: 0.875rem; cursor: pointer; text-decoration: none; transition: all 0.2s ease; border: none; }
  .btn-primary { background: var(--primary); color: white; display: inline-flex; align-items: center; gap: 6px; }
  .btn-primary:hover { background: var(--primary-dark); transform: translateY(-2px); box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25); }
  .btn-sm { padding: 6px 12px; font-size: 0.8rem; }
  .btn-edit-action { border-radius: 6px; }
  .btn-edit-action:hover { background: #bfdbfe; }
  .btn-delete-action { border-radius: 6px; }
  .btn-delete-action:hover { background: #fecaca; }
  .qfg-tc-btn { padding: 9px 16px; font-size: 0.85rem; }

  /* ============================================
     ADD HEADER SECTION
     ============================================ */
  .cfg-add-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
  .cfg-add-header > div { flex: 1; }
  .cfg-add-header button { margin-left: 16px; }

  /* ============================================
     FOOTER BUTTONS
     ============================================ */
  .cfg-footer-btns { display: flex; justify-content: flex-end; gap: 12px; margin-top: 20px; }
  .cfg-footer-btns button { display: inline-flex; align-items: center; gap: 6px; }

  /* ============================================
     ID FORMATS FORM
     ============================================ */
  .cfg-format-form { display: flex; flex-direction: column; gap: 20px; }
  .cfg-format-group { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .cfg-format-field { display: flex; flex-direction: column; gap: 6px; }
  .cfg-format-field label { font-weight: 600; color: var(--text-primary); font-size: 0.875rem; }
  .cfg-format-field input { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: 8px; font-size: 0.875rem; transition: all 0.2s; }
  .cfg-format-field input:focus { outline: none; border-color: var(--primary); background: #fff; box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1); }
  .cfg-format-field .hint { font-size: 0.75rem; color: var(--slate-500); margin-top: 4px; }

  /* ============================================
     TOKEN TABLE & PILLS
     ============================================ */
  .cfg-token-table { width: 100%; border-collapse: collapse; }
  .cfg-token-table thead { background: var(--slate-100); }
  .cfg-token-table th { padding: 10px 14px; text-align: left; font-weight: 600; font-size: 0.8rem; color: var(--text-secondary); border-bottom: 1.5px solid var(--border); }
  .cfg-token-table td { padding: 12px 14px; border-bottom: 1px solid var(--border); font-size: 0.875rem; }
  .cfg-token-table tbody tr:hover { background: #fafbfc; }
  .cfg-token-pill { background: var(--primary-light); color: var(--primary); padding: 2px 8px; border-radius: 4px; font-family: "Monaco", "Courier New", monospace; font-size: 0.8rem; font-weight: 600; }
  .cfg-token-example { background: var(--slate-100); color: var(--text-secondary); padding: 2px 6px; border-radius: 3px; font-family: "Monaco", "Courier New", monospace; font-size: 0.8rem; }

  /* ============================================
     RESPONSIVE
     ============================================ */
  @media (max-width: 768px) {
    .cfg-wrap { padding: 20px 16px; }
    .cfg-add-header { flex-direction: column; align-items: flex-start; }
    .cfg-add-header button { margin-left: 0; margin-top: 12px; }
    .cfg-table-search { width: 100%; }
    .cfg-format-group { grid-template-columns: 1fr; }
  }
</style>
' AS html;

-- ============================================
-- PAGE HEADER + BACK BUTTON + TABS
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-bottom: 0;">
  <div class="cfg-title-block">
    <h1>Settings</h1>
    <p>Manage master data and configuration for your application.</p>
  </div>

  <a href="entries.sql" class="cfg-back-btn">&#8592; Back to Generator</a>

  <div class="cfg-tab-bar">
    <a href="settings.sql?tab=team_members"   class="cfg-tab-btn ' || CASE WHEN $tab = 'team_members'      OR $tab IS NULL THEN 'active' ELSE '' END || '">
    Team Members
    </a>
    <a href="settings.sql?tab=test_types"     class="cfg-tab-btn ' || CASE WHEN $tab = 'test_types'         THEN 'active' ELSE '' END || '">
    Test Types
    </a>
    <a href="settings.sql?tab=scenario_types" class="cfg-tab-btn ' || CASE WHEN $tab = 'scenario_types'     THEN 'active' ELSE '' END || '">
    Scenario Types
    </a>
    <a href="settings.sql?tab=execution_types" class="cfg-tab-btn ' || CASE WHEN $tab = 'execution_types'   THEN 'active' ELSE '' END || '">
    Execution Types
    </a>
    <a href="settings.sql?tab=tags"           class="cfg-tab-btn ' || CASE WHEN $tab = 'tags'               THEN 'active' ELSE '' END || '">
    Tags
    </a>
    <a href="settings.sql?tab=test_case_statuses" class="cfg-tab-btn ' || CASE WHEN $tab = 'test_case_statuses' THEN 'active' ELSE '' END || '">
    TC Status
    </a>
    <a href="settings.sql?tab=id_formats"    class="cfg-tab-btn ' || CASE WHEN $tab = 'id_formats'          THEN 'active' ELSE '' END || '">
    ID Formats
    </a>
    <a href="settings.sql?tab=markdown_paths" class="cfg-tab-btn ' || CASE WHEN $tab = 'markdown_paths' THEN 'active' ELSE '' END || '">
    Markdown Folder
    </a>
  </div>
</div>
' AS html;

-- ============================================
-- TEAM MEMBERS TAB
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-add-header">
      <div>
        <div class="cfg-card-title">Team Members</div>
        <div class="cfg-card-desc" style="margin-bottom:0;">Configure the team members available for test case assignment.</div>
      </div>
      <button class="btn btn-primary qfg-tc-btn" data-action="addMember" data-entity="team_members">
        ＋ Add Member
      </button>
    </div>

    <div class="cfg-table-wrap">
      <div class="cfg-table-header">
        <span class="cfg-table-header-title">All Members</span>
        <input class="cfg-table-search" type="text" placeholder="Search…" />
      </div>
      <table class="cfg-table" id="tm-table">
        <thead>
          <tr>
            <th>Full Name</th>
            <th>Designation</th>
            <th>Created</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
' AS html
WHERE $tab = 'team_members' OR $tab IS NULL;

SELECT 'html' AS component,
  '<tr>
    <td class="cfg-name-cell" data-field="full_name" data-value="' || REPLACE(full_name, '"', '&quot;') || '">' || full_name || '</td>
    <td data-field="designation" data-value="' || COALESCE(REPLACE(designation, '"', '&quot;'), '') || '">' || COALESCE(designation, '<span style="color:var(--slate-300)">—</span>') || '</td>
    <td class="cfg-date-cell">' || datetime(created_at, 'localtime') || '</td>
    <td>
      <div class="cfg-actions-cell">
        <button class="btn btn-sm btn-edit-action" style="padding: 0.5rem !important;"
                data-action="editMember"
                data-entity="team_members"
                data-id="' || id || '"
                data-full_name="' || REPLACE(full_name, '"', '&quot;') || '"
                data-designation="' || COALESCE(REPLACE(designation, '"', '&quot;'), '') || '"
                title="Edit ' || REPLACE(full_name, '"', '&quot;') || '">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
        </button>
        <a class="btn btn-sm btn-delete-action" style="padding: 0.5rem !important; display:inline-flex; align-items:center;"
           href="/pages/settings/delete_team_member.sql?id=' || id || '"
           title="Delete ' || REPLACE(full_name, '"', '&quot;') || '">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
        </a>
      </div>
    </td>
  </tr>'
AS html
FROM team_members
WHERE $tab = 'team_members' OR $tab IS NULL
ORDER BY full_name;

SELECT 'html' AS component, '
        </tbody>
      </table>
    </div>
  </div>
</div>
' AS html
WHERE $tab = 'team_members' OR $tab IS NULL;

-- ============================================
-- TEST TYPES TAB
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-add-header">
      <div>
        <div class="cfg-card-title">Test Types</div>
        <div class="cfg-card-desc" style="margin-bottom:0;">Configure the types of tests available in the system.</div>
      </div>
      <button class="btn btn-primary qfg-tc-btn" data-action="addMember" data-entity="test_types">
        ＋ Add Test Type
      </button>
    </div>

    <div class="cfg-table-wrap">
      <div class="cfg-table-header">
        <span class="cfg-table-header-title">All Test Types</span>
        <input class="cfg-table-search" type="text" placeholder="Search…" />
      </div>
      <table class="cfg-table" id="tt-table">
        <thead><tr><th>Name</th><th>Created</th><th>Actions</th></tr></thead>
        <tbody>
' AS html
WHERE $tab = 'test_types';

SELECT 'html' AS component,
  '<tr>
    <td class="cfg-name-cell">' || name || '</td>
    <td class="cfg-date-cell">' || datetime(created_at, 'localtime') || '</td>
    <td><div class="cfg-actions-cell">
      <button class="btn btn-sm btn-edit-action"
              data-action="editMember"
              data-entity="test_types"
              data-id="' || id || '"
              data-name="' || REPLACE(name, '"', '&quot;') || '"
              title="Edit ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
      </button>
      <a class="btn btn-sm btn-delete-action" style="padding: 0.5rem !important; display:inline-flex; align-items:center;"
         href="/pages/settings/delete_test_type.sql?id=' || id || '"
         title="Delete ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
      </a>
    </div></td>
  </tr>'
AS html
FROM test_types
WHERE $tab = 'test_types'
ORDER BY name;

SELECT 'html' AS component, '
        </tbody>
      </table>
    </div>
  </div>
</div>
' AS html
WHERE $tab = 'test_types';

-- ============================================
-- SCENARIO TYPES TAB
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-add-header">
      <div>
        <div class="cfg-card-title">Scenario Types</div>
        <div class="cfg-card-desc" style="margin-bottom:0;">Define scenario types for organizing test cases.</div>
      </div>
      <button class="btn btn-primary qfg-tc-btn" data-action="addMember" data-entity="scenario_types">
        ＋ Add Scenario Type
      </button>
    </div>

    <div class="cfg-table-wrap">
      <div class="cfg-table-header">
        <span class="cfg-table-header-title">All Scenario Types</span>
        <input class="cfg-table-search" type="text" placeholder="Search…" />
      </div>
      <table class="cfg-table" id="st-table">
        <thead><tr><th>Name</th><th>Created</th><th>Actions</th></tr></thead>
        <tbody>
' AS html
WHERE $tab = 'scenario_types';

SELECT 'html' AS component,
  '<tr>
    <td class="cfg-name-cell">' || name || '</td>
    <td class="cfg-date-cell">' || datetime(created_at, 'localtime') || '</td>
    <td><div class="cfg-actions-cell">
      <button class="btn btn-sm btn-edit-action"
              data-action="editMember"
              data-entity="scenario_types"
              data-id="' || id || '"
              data-name="' || REPLACE(name, '"', '&quot;') || '"
              title="Edit ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
      </button>
      <a class="btn btn-sm btn-delete-action" style="padding: 0.5rem !important; display:inline-flex; align-items:center;"
         href="/pages/settings/delete_scenario_type.sql?id=' || id || '"
         title="Delete ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
      </a>
    </div></td>
  </tr>'
AS html
FROM scenario_types
WHERE $tab = 'scenario_types'
ORDER BY name;

SELECT 'html' AS component, '
        </tbody>
      </table>
    </div>
  </div>
</div>
' AS html
WHERE $tab = 'scenario_types';

-- ============================================
-- EXECUTION TYPES TAB
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-add-header">
      <div>
        <div class="cfg-card-title">Execution Types</div>
        <div class="cfg-card-desc" style="margin-bottom:0;">Configure execution types (e.g. Automated, Manual).</div>
      </div>
      <button class="btn btn-primary qfg-tc-btn" data-action="addMember" data-entity="execution_types">
        ＋ Add Execution Type
      </button>
    </div>

    <div class="cfg-table-wrap">
      <div class="cfg-table-header">
        <span class="cfg-table-header-title">All Execution Types</span>
        <input class="cfg-table-search" type="text" placeholder="Search…" />
      </div>
      <table class="cfg-table" id="et-table">
        <thead><tr><th>Name</th><th>Created</th><th>Actions</th></tr></thead>
        <tbody>
' AS html
WHERE $tab = 'execution_types';

SELECT 'html' AS component,
  '<tr>
    <td class="cfg-name-cell">' || name || '</td>
    <td class="cfg-date-cell">' || datetime(created_at, 'localtime') || '</td>
    <td><div class="cfg-actions-cell">
      <button class="btn btn-sm btn-edit-action"
              data-action="editMember"
              data-entity="execution_types"
              data-id="' || id || '"
              data-name="' || REPLACE(name, '"', '&quot;') || '"
              title="Edit ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
      </button>
      <a class="btn btn-sm btn-delete-action" style="padding: 0.5rem !important; display:inline-flex; align-items:center;"
         href="/pages/settings/delete_execution_type.sql?id=' || id || '"
         title="Delete ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
      </a>
    </div></td>
  </tr>'
AS html
FROM execution_types
WHERE $tab = 'execution_types'
ORDER BY name;

SELECT 'html' AS component, '
        </tbody>
      </table>
    </div>
  </div>
</div>
' AS html
WHERE $tab = 'execution_types';

-- ============================================
-- TAGS TAB
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-add-header">
      <div>
        <div class="cfg-card-title">Tags</div>
        <div class="cfg-card-desc" style="margin-bottom:0;">Create tags to categorize and filter test cases.</div>
      </div>
      <button class="btn btn-primary qfg-tc-btn" data-action="addMember" data-entity="tags">
        ＋ Add Tag
      </button>
    </div>

    <div class="cfg-table-wrap">
      <div class="cfg-table-header">
        <span class="cfg-table-header-title">All Tags</span>
        <input class="cfg-table-search" type="text" placeholder="Search…" />
      </div>
      <table class="cfg-table" id="tag-table">
        <thead><tr><th>Name</th><th>Created</th><th>Actions</th></tr></thead>
        <tbody>
' AS html
WHERE $tab = 'tags';

SELECT 'html' AS component,
  '<tr>
    <td class="cfg-name-cell">' || name || '</td>
    <td class="cfg-date-cell">' || datetime(created_at, 'localtime') || '</td>
    <td><div class="cfg-actions-cell">
      <button class="btn btn-sm btn-edit-action"
              data-action="editMember"
              data-entity="tags"
              data-id="' || id || '"
              data-name="' || REPLACE(name, '"', '&quot;') || '"
              title="Edit ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
      </button>
      <a class="btn btn-sm btn-delete-action" style="padding: 0.5rem !important; display:inline-flex; align-items:center;"
         href="/pages/settings/delete_tag.sql?id=' || id || '"
         title="Delete ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
      </a>
    </div></td>
  </tr>'
AS html
FROM tags
WHERE $tab = 'tags'
ORDER BY name;

SELECT 'html' AS component, '
        </tbody>
      </table>
    </div>
  </div>
</div>
' AS html
WHERE $tab = 'tags';

-- ============================================
-- TEST CASE STATUSES TAB
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-add-header">
      <div>
        <div class="cfg-card-title">Test Case Statuses</div>
        <div class="cfg-card-desc" style="margin-bottom:0;">Configure status options for test case execution results.</div>
      </div>
      <button class="btn btn-primary qfg-tc-btn" data-action="addMember" data-entity="test_case_statuses">
        ＋ Add Status
      </button>
    </div>

    <div class="cfg-table-wrap">
      <div class="cfg-table-header">
        <span class="cfg-table-header-title">All Statuses</span>
        <input class="cfg-table-search" type="text" placeholder="Search…" />
      </div>
      <table class="cfg-table" id="tcs-table">
        <thead><tr><th>Status Name</th><th>Created</th><th>Actions</th></tr></thead>
        <tbody>
' AS html
WHERE $tab = 'test_case_statuses';

SELECT 'html' AS component,
  '<tr>
    <td class="cfg-name-cell">' || name || '</td>
    <td class="cfg-date-cell">' || datetime(created_at, 'localtime') || '</td>
    <td><div class="cfg-actions-cell">
      <button class="btn btn-sm btn-edit-action"
              data-action="editMember"
              data-entity="test_case_statuses"
              data-id="' || id || '"
              data-name="' || REPLACE(name, '"', '&quot;') || '"
              title="Edit ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
      </button>
      <a class="btn btn-sm btn-delete-action" style="padding: 0.5rem !important; display:inline-flex; align-items:center;"
         href="/pages/test_cases/delete_status.sql?id=' || id || '"
         title="Delete ' || REPLACE(name, '"', '&quot;') || '">
        <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
      </a>
    </div></td>
  </tr>'
AS html
FROM test_case_statuses
WHERE $tab = 'test_case_statuses'
ORDER BY name;

SELECT 'html' AS component, '
        </tbody>
      </table>
    </div>
  </div>
</div>
' AS html
WHERE $tab = 'test_case_statuses';


-- ============================================
-- ID FORMATS TAB
-- ============================================
SELECT 'html' AS component, '
<div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-card-title">ID Format Configuration</div>
    <div class="cfg-card-desc">Define the naming patterns for auto-generated IDs. Use tokens like {NUM}, {PRJ}, {SUITE}, and {REQ} in your patterns.</div>

    <form method="POST" action="/pages/settings/save_id_formats.sql" class="cfg-format-form">
      <div class="cfg-format-group">
        <div class="cfg-format-field">
          <label>Test Case ID Format</label>
          <input type="text" name="tc_id_format" placeholder="TC-{PRJ}-{NUM}"
                 value="' || COALESCE($_tc_id_format, 'TC-{PRJ}-{NUM}') || '" />
          <span class="hint">Tokens: {NUM}, {PRJ}, {SUITE}</span>
        </div>
        <div class="cfg-format-field">
          <label>Scenario ID Format</label>
          <input type="text" name="scn_id_format" placeholder="SCN-{NUM}"
                 value="' || COALESCE($_scn_id_format, 'SCN-{NUM}') || '" />
          <span class="hint">Tokens: {NUM}, {PRJ}, {SUITE}</span>
        </div>
      </div>
      <div class="cfg-format-group">
        <div class="cfg-format-field">
          <label>Requirement ID Format</label>
          <input type="text" name="req_id_format" placeholder="RQ-{NUM}"
                 value="' || COALESCE($_req_id_format, 'RQ-{NUM}') || '" />
          <span class="hint">Tokens: {NUM}, {PRJ}, {SUITE}</span>
        </div>
      </div>
      <div class="cfg-footer-btns">
        <button type="submit" class="btn btn-primary qfg-tc-btn">💾 Save Formats</button>
      </div>
    </form>
  </div>

  <!-- Token Reference -->
  <div class="cfg-card">
    <div class="cfg-card-title">📖 Available Tokens — Reference Guide</div>
    <div class="cfg-card-desc">Use these tokens inside your format patterns. They will be substituted at generation time.</div>
    <div class="cfg-table-wrap">
      <table class="cfg-token-table">
        <thead>
          <tr>
            <th>Token</th>
            <th>Description</th>
            <th>Example Value</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><span class="cfg-token-pill">{NUM}</span></td>
            <td>Auto-incremented sequence number (zero-padded to 3 or 4 digits)</td>
            <td><span class="cfg-token-example">001 or 0001</span></td>
          </tr>
          <tr>
            <td><span class="cfg-token-pill">{REQ}</span></td>
            <td>Requirement ID (if applicable)</td>
            <td><span class="cfg-token-example">RQ-001</span></td>
          </tr>
          <tr>
            <td><span class="cfg-token-pill">{PRJ}</span></td>
            <td>Project name (slug, lowercase, hyphenated)</td>
            <td><span class="cfg-token-example">login-page</span></td>
          </tr>
          <tr>
            <td><span class="cfg-token-pill">{SUITE}</span></td>
            <td>Suite name (first 3 letters, uppercase)</td>
            <td><span class="cfg-token-example">REG</span></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</div>
' AS html
WHERE $tab = 'id_formats';

SELECT 'html' AS component,'
  <div class="cfg-wrap" style="padding-top:0">
  <div class="cfg-card">
    <div class="cfg-card-title"> Markdown Destination Folder</div>
    <div class="cfg-card-desc">Set the folder where generated markdown files will be saved.</div>
    <form method="POST" action="/pages/settings/save_path_settings.sql" class="cfg-format-form">
      <div class="cfg-format-field">
        <label>Destination Path</label>
        <input type="text"
               name="artifact_destination"
               placeholder="e.g. /home/user/markdown  or  ./docs/output"
               value="' || COALESCE(destination_path, '') || '"
               autocomplete="off" />
        <span class="hint">Enter the foldername (e.g. outputs)</span>
      </div>
      <div class="cfg-footer-btns">
        <button type="submit" class="btn btn-primary qfg-tc-btn">💾 Save Folder Name</button>
      </div>
    </form>
  </div>
</div>
'
AS html
FROM path_settings
WHERE setting_key = 'markdown_destination'
  AND $tab = 'markdown_paths';