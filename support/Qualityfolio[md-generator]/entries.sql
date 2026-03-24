-- AI Generator Page (client-side, no page navigation, CSP-safe)
-- All JS in /js/generator.js — no inline event handlers used here.

SET _api_key   = COALESCE(sqlpage.environment_variable('GROQ_API_KEY'), sqlpage.environment_variable('API_KEY'));
SET _api_model = COALESCE(sqlpage.environment_variable('GROQ_MODEL'), 'llama-3.3-70b-versatile');
SET _members   = (SELECT json_group_array(full_name) FROM team_members);
SET _testtypes = (SELECT json_group_array(name) FROM test_types);
SET _statuses  = (SELECT json_group_array(name) FROM test_case_statuses);

-- Ensure app_settings table exists before reading from it
SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/033_create_app_settings.sql') AS properties;

SET _tc_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'tc_id_format'), 'TC-{NUM}');
SET _plan_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'plan_id_format'), 'PL-{NUM}');
SET _suite_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'suite_id_format'), 'ST-{NUM}');
SET _req_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'req_id_format'), 'RQ-{NUM}');

SELECT 'shell' AS component,
       '' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
       json_array(
           json_object('title', 'Generator', 'link', 'entries.sql',   'icon', 'pencil'),
           json_object('title', 'Markdown Editor', 'link', 'md_editor.sql', 'icon', 'file-text'),
           json_object('title', 'Settings',  'link', 'settings.sql',  'icon', 'settings')
       ) AS menu_item,
       json_array(
           '/js/layout.js?v='         || CAST(STRFTIME('%s','now') AS TEXT),
           '/js/chat.js?v='           || CAST(STRFTIME('%s','now') AS TEXT),
            '/js/pikaday.js',
           '/js/md-date-picker.js?v=' || CAST(STRFTIME('%s','now') AS TEXT),
           '/js/generator.js?v='      || CAST(STRFTIME('%s','now') AS TEXT)
       ) AS javascript,
       json_array(
           '/css/theme.css?v=' || CAST(STRFTIME('%s','now') AS TEXT),
           '/css/chat.css?v='  || CAST(STRFTIME('%s','now') AS TEXT),
            '/css/pikaday.css'
       ) AS css;

-- Inject server-side data via data-* attributes on a hidden element (CSP-safe, no inline script)
SELECT 'html' AS component,
    '<div id="qfg-config" hidden'
    || ' data-key="'   || COALESCE($_api_key,'')   || '"'
    || ' data-model="' || $_api_model              || '"'
    || ' data-members=''' || REPLACE(COALESCE($_members,'[]'), '''','&apos;') || ''''
    || ' data-testtypes=''' || REPLACE(COALESCE($_testtypes,'[]'), '''','&apos;') || ''''
    || ' data-statuses=''' || REPLACE(COALESCE($_statuses,'[]'), '''','&apos;') || ''''
    || ' data-tcidformat="' || REPLACE(COALESCE($_tc_id_format,'TC-{NUM}'), '"', '&quot;') || '"'
    || ' data-planidformat="' || REPLACE(COALESCE($_plan_id_format,'PL-{NUM}'), '"', '&quot;') || '"'
    || ' data-suiteidformat="' || REPLACE(COALESCE($_suite_id_format,'ST-{NUM}'), '"', '&quot;') || '"'
    || ' data-reqidformat="' || REPLACE(COALESCE($_req_id_format,'RQ-{NUM}'), '"', '&quot;') || '"'
    || '></div>' AS html;

SELECT 'html' AS component, '
<style>
  /* ============================================
     VARIABLES & FOUNDATIONS
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
  .qfg-wrap { width: 100%; margin: 0 auto; padding: 32px 24px; }
  .qfg-title-block { text-align: center; animation: slideDown 0.6s ease-out; }
  .qfg-title-block h1 { font-weight: 400; color: var(--text-primary); }
  .qfg-title-block p { color: var(--text-secondary); font-size: 0.8rem; font-weight: 400; }
  @keyframes slideDown { from { opacity: 0; transform: translateY(-20px); } to { opacity: 1; transform: translateY(0); } }

  /* ============================================
     CARD STRUCTURE
     ============================================ */
  .qfg-card { background: #ffffff; padding: 20px; display: flex; flex-direction: column; overflow: hidden; animation: fadeIn 0.5s ease-out 0.1s both; }
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  .qfg-card-title { font-size: 0.875rem; font-weight: 700; color: var(--slate-500); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 24px; flex-shrink: 0; }
  .qfg-scroll-inner { flex: 1; overflow-y: auto; overflow-x: hidden; padding-right: 8px; }
  .qfg-scroll-inner::-webkit-scrollbar { width: 6px; }
  .qfg-scroll-inner::-webkit-scrollbar-track { background: transparent; }
  .qfg-scroll-inner::-webkit-scrollbar-thumb { background: var(--slate-300); border-radius: 3px; }
  .qfg-scroll-inner::-webkit-scrollbar-thumb:hover { background: var(--slate-400); }

  /* ============================================
     FORM FIELDS
     ============================================ */
  .qfg-field { margin-bottom: 18px; }
  .qfg-field label { display: block; font-size: 0.875rem; font-weight: 600; color: var(--text-primary); margin-bottom: 8px; }
  .qfg-field .req { color: var(--danger); font-weight: 700; margin-left: 3px; }
  .qfg-field input, .qfg-field select, .qfg-field textarea { width: 100%; border: 1.5px solid var(--border); border-radius: 10px; padding: 10px 14px; font-size: 0.9375rem; color: var(--text-primary); background: var(--slate-50); font-family: inherit; transition: all 0.2s ease; }
  .qfg-field input:hover, .qfg-field select:hover, .qfg-field textarea:hover { border-color: var(--slate-300); background: #ffffff; }
  .qfg-field input:focus, .qfg-field select:focus, .qfg-field textarea:focus { outline: none; border-color: var(--primary); background: #ffffff; box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1); }
  .qfg-field textarea { resize: vertical; min-height: 80px; }
  .qfg-field .hint { font-size: 0.8125rem; color: var(--slate-500); margin-top: 6px; display: block; }

  /* ============================================
     GRID LAYOUTS
     ============================================ */
  .qfg-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .qfg-row3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 16px; }
  @media (max-width: 768px) { .qfg-row, .qfg-row3 { grid-template-columns: 1fr; } }

  /* ============================================
     REVEAL & COLLAPSE
     ============================================ */
  #qfg-reveal { overflow: hidden; max-height: 0; opacity: 0; transition: max-height 0.5s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.4s ease; pointer-events: none; }
  #qfg-reveal.open { max-height: 5000px; opacity: 1; pointer-events: auto; }

  /* ============================================
     SCHEMA BANNER
     ============================================ */
  #qfg-schema-banner { display: none; background: linear-gradient(135deg, #d3f7f9 0%, #e0f2fe 100%); border: 1.5px solid #93c5fd; border-radius: 10px; padding: 12px 16px; margin-bottom: 18px; font-size: 0.875rem; font-weight: 600; color: #169fb9; align-items: center; gap: 10px; flex-wrap: wrap; }
  #qfg-schema-banner.show { display: flex; }

  /* ============================================
     BADGES & PILLS
     ============================================ */
  .qfg-badge { background: #169fb9; color: #ffffff; border-radius: 9999px; padding: 4px 12px; font-size: 0.75rem; font-weight: 700; }
  .qfg-sep { color: #1d8397; }

  /* ============================================
     SUITE BLOCKS & GROUPS
     ============================================ */
  .qfg-suite-block { border: 1.5px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 14px; position: relative; background: linear-gradient(135deg, #ffffff 0%, var(--slate-50) 100%); transition: all 0.2s ease; }
  .qfg-suite-block:hover { border-color: var(--primary); box-shadow: var(--shadow-sm); }
  .qfg-remove-suite { position: absolute; top: 12px; right: 14px; background: none; border: none; cursor: pointer; color: var(--danger); font-size: 1.25rem; padding: 4px; transition: transform 0.2s ease; }
  .qfg-remove-suite:hover { transform: scale(1.1); }
  .qfg-add-suite { border: 2px dashed var(--slate-300); border-radius: 10px; padding: 12px; text-align: center; cursor: pointer; color: var(--slate-500); font-size: 0.85rem; font-weight: 600; background: none; width: 100%; margin-top: 8px; transition: all 0.2s ease; }
  .qfg-add-suite:hover { border-color: var(--primary); color: var(--primary); background: var(--primary-light); }

  /* ============================================
     BUTTONS
     ============================================ */
  .qfg-refine-btn { float: right; background: linear-gradient(135deg, #11a6aa, #043044); color: #ffffff; border: none; border-radius: 8px; padding: 6px 14px; font-size: 0.8125rem; font-weight: 700; cursor: pointer; transition: all 0.2s ease; margin-bottom:10px}
  .qfg-refine-btn:hover { transform: translateY(-2px); box-shadow: var(--shadow-md); }
  .qfg-footer-btns { display: flex; justify-content: flex-end; gap: 12px; align-items: center; padding-top: 20px; flex-shrink: 0; border-top: 1px solid var(--border); margin-top: 24px; }
  .qfg-btn-reset { background: var(--slate-100); color: var(--text-secondary); border: 1px solid var(--border); border-radius: 10px; padding: 7px 15px; font-size: 0.85rem; font-weight: 600; cursor: pointer; transition: all 0.2s ease; }
  .qfg-btn-reset:hover { background: var(--border); transform: translateY(-2px); }
  .qfg-btn-generate { background: linear-gradient(135deg, #11a6aa, #043044); color: #ffffff; border: none; border-radius: 10px; padding: 7px 15px; font-size: 0.85rem; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 8px; box-shadow: var(--shadow-md); transition: all 0.2s ease; }
  .qfg-btn-generate:hover:not(:disabled) { transform: translateY(-2px); box-shadow: var(--shadow-lg); }
  .qfg-btn-generate:disabled { opacity: 0.6; cursor: not-allowed; }

  /* ============================================
     SPINNER
     ============================================ */
  .qfg-spinner { width: 16px; height: 16px; border: 2px solid rgba(255, 255, 255, 0.3); border-top-color: #ffffff; border-radius: 50%; animation: spin 0.7s linear infinite; }
  @keyframes spin { to { transform: rotate(360deg); } }

  /* ============================================
     RESULTS SECTION
     ============================================ */
  .qfg-results-header { background: linear-gradient(135deg, #d3f7f9 0%, #e0f2fe 100%); color: #1d8397; padding: 24px; border-radius: 14px; margin-bottom: 24px; }
  .qfg-results-header h2 { margin: 0 0 6px; font-size: 1rem; font-weight:500; }
  .qfg-results-header p { margin: 0; opacity: 0.9; font-size: 0.85rem; }
  .qfg-results-meta { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 8px; }
  .qfg-results-meta span { background: rgb(9 124 113 / 20%); border-radius: 20px;; padding: 4px 12px; font-size: 0.8125rem; font-weight: 600; }

  /* ============================================
     CASE CARDS
     ============================================ */
  .qfg-case-card { border: 1px solid var(--border); border-radius: 12px; margin-bottom: 16px; overflow: hidden; background: #ffffff; box-shadow: var(--shadow-sm); transition: all 0.2s ease; }
  .qfg-case-card:hover { box-shadow: var(--shadow-md); transform: translateY(-2px); }
  .qfg-case-head { display: flex; align-items: center; gap: 12px; padding: 16px; border-bottom: 1px solid var(--border); flex-wrap: wrap; background: var(--slate-50); }
  .qfg-case-id { font-size: 0.75rem; font-weight: 800; background: #8fdee1; color: #0e9289; border-radius: 6px; padding: 4px 10px; }
  .qfg-case-title { flex: 1; font-weight: 700; font-size: 0.8rem; color: #666; min-width: 200px; }
  .pri-high { background: #fee2e2; color: #991b1b; }
  .pri-medium { background: #fef3c7; color: #92400e; }
  .pri-low { background: #dcfce7; color: #166534; }
  .qfg-case-pill { font-size: 0.75rem; font-weight: 700; border-radius: 9999px; padding: 4px 10px; }
  .qfg-case-body { padding: 18px; display: grid; gap: 14px; }

  /* ============================================
     SECTIONS
     ============================================ */
  .qfg-section-label { font-size: 0.75rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.08em; color: var(--slate-500); margin-bottom: 6px; }
  .qfg-section-value { font-size: 0.9375rem; color: var(--text-secondary); background: var(--slate-50); border-radius: 8px; padding: 12px; white-space: pre-wrap; border: 1px solid var(--border); }
  .qfg-section-value.steps { background: #f0f9ff; border-color: #bfdbfe; }
  .qfg-section-value.result { background: #dcfce7; border-color: #a7f3d0; }

  /* ============================================
     DOWNLOAD BAR
     ============================================ */
  .qfg-dl-bar { background: linear-gradient(135deg, var(--primary-light), #e0f2fe); border: 1.5px solid #93c5fd; border-radius: 12px; padding: 18px; display: flex; align-items: center; gap: 16px; margin-bottom: 24px; flex-wrap: wrap; }
  .qfg-dl-bar a { background: var(--primary); color: #ffffff; text-decoration: none; padding: 10px 20px; border-radius: 8px; font-size: 0.9375rem; font-weight: 700; transition: all 0.2s ease; }
  .qfg-dl-bar a:hover { background: var(--primary-dark); transform: translateY(-2px); box-shadow: var(--shadow-md); }

  /* ============================================
     ERROR & INFO
     ============================================ */
  .qfg-error { background: #fee2e2; border: 1.5px solid #fca5a5; border-radius: 10px; padding: 16px; color: #991b1b; font-size: 0.9375rem; }
  .qfg-section-lbl { margin-bottom: 12px; font-size: 0.875rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; margin-top: 8px; color: #35a0d0; }
  .qfg-check-item { padding: 6px 0; font-size: 0.9375rem; color: var(--text-secondary); line-height: 1.6; }

  /* ============================================
     BULK OPERATIONS
     ============================================ */
  .qfg-bulk-toolbar { background: #ffffff; border: 1px solid var(--border); border-radius: 12px; padding: 18px; margin: 18px 0; display: flex; flex-direction: column; gap: 12px; box-shadow: var(--shadow-sm); }
  .qfg-bulk-section { display: flex; flex-direction: column; gap: 8px; }
  .qfg-bulk-section-label { font-size: 0.75rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; color: var(--slate-500); }
  .qfg-bulk-row { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; }
  .qfg-bulk-select { padding: 5px 9px; border: 1px solid var(--border); border-radius: 7px; font-size: 0.8rem; color: var(--text-secondary); background: var(--slate-50); }
  .qfg-bulk-input { padding: 5px 9px; border: 1px solid var(--border); border-radius: 7px; font-size: 0.8rem; color: var(--text-secondary); background: var(--slate-50); }
  .qfg-bulk-edit-btn { padding: 5px 13px; background: var(--slate-100); border: 1px solid var(--border); border-radius: 7px; font-size: 0.8rem; font-weight: 600; color: var(--slate-700); cursor: pointer; transition: all 0.2s ease; }
  .qfg-bulk-edit-btn:hover { background: var(--slate-200); }
  .qfg-bulk-apply-btn { padding: 5px 14px; background: var(--primary); color: #fff; border: none; border-radius: 7px; font-size: 0.8rem; font-weight: 700; cursor: pointer; transition: all 0.2s ease; }
  .qfg-bulk-apply-btn:hover { background: var(--primary-dark); }
  .qfg-bulk-run-btn { background: var(--accent); }
  .qfg-bulk-run-btn:hover { background: #0284c7; }
  .qfg-bulk-reset-btn { padding: 5px 13px; background: var(--slate-50); border: 1px solid var(--border); border-radius: 7px; font-size: 0.79rem; color: var(--slate-500); cursor: pointer; transition: all 0.2s ease; }
  .qfg-bulk-reset-btn:hover { background: var(--slate-200); }
  .qfg-bulk-footer { display: flex; align-items: center; gap: 10px; border-top: 1px solid var(--border); padding-top: 10px; margin-top: 2px; }

  /* ============================================
     GROUP HEADERS
     ============================================ */
  .qfg-group-header { display: flex; align-items: center; gap: 10px; padding: 12px 16px; border-radius: 10px; margin: 12px 0 8px; flex-wrap: wrap; background: var(--slate-50); border: 1px solid var(--border); transition: all 0.2s ease; }
  .qfg-group-header.plan-header { background: linear-gradient(90deg, var(--primary-light), #f0f9ff); border: 1.5px solid #93c5fd; }
  .qfg-group-header.suite-header {background: #b5cee7;    border: 1px solid var(--border);}
  .qfg-group-icon { font-size: 1rem; }
  .qfg-group-label { font-size: 0.9375rem; font-weight: 700; color: var(--text-primary); flex: 1; }
  .qfg-group-actions { display: flex; gap: 8px; flex-wrap: wrap; }

  /* ============================================
     ACTION BUTTONS
     ============================================ */
  .qfg-action-btn { padding: 6px 12px; border-radius: 6px; font-size: 0.75rem; font-weight: 600; border: 1px solid var(--border); background: #ffffff; color: var(--text-secondary); cursor: pointer; transition: all 0.2s ease; }
  .qfg-action-btn:hover { background: var(--slate-100); }
  .qfg-action-btn.del { background: #fff0f0; border-color: #fca5a5; color: #b91c1c; }
  .qfg-action-btn.del:hover { background: #fee2e2; }
  .qfg-action-sm { padding: 6px 12px; border-radius: 6px; font-size: 0.77rem; font-weight: 600; border: 1px solid var(--border); background: var(--slate-100); color: var(--text-secondary); cursor: pointer; transition: all 0.2s ease; }
  .qfg-action-sm:hover { background: var(--slate-200); }

  /* ============================================
     TEST CASE INLINE
     ============================================ */
  .tc-inline-fields { display: flex; flex-direction: column; gap: 2px; }
  .tc-inline-fields label { font-size: 0.625rem; font-weight: 700; letter-spacing: 0.04em; }
  .tc-actions { display: flex; gap: 6px; margin-left: auto; }
  .qfg-tc-edit-btn { padding: 4px 10px; border-radius: 5px; border: 1px solid #c7d2fe; background: var(--primary-light); color: var(--primary-dark); font-size: 0.75rem; font-weight: 600; cursor: pointer; transition: all 0.2s ease; }
  .qfg-tc-edit-btn:hover { background: #e0e7ff; }
  .qfg-tc-del-btn { padding: 4px 10px; border-radius: 5px; border: 1px solid #fca5a5; background: #fff0f0; color: #b91c1c; font-size: 0.75rem; font-weight: 600; cursor: pointer; transition: all 0.2s ease; }
  .qfg-tc-del-btn:hover { background: #fee2e2; }

  /* ============================================
     SELECTION CONTROLS
     ============================================ */
  .hint { font-size: 0.75rem; color: var(--slate-500); }
  .qfg-bulk-tip { font-size: 0.75rem; cursor: default; }
  .qfg-select-bar { display: flex; align-items: center; gap: 10px; padding: 10px 14px; background: var(--slate-50); border: 1px solid var(--border); border-radius: 8px; margin-bottom: 8px; }
  .qfg-select-all-label { display: flex; align-items: center; gap: 6px; font-size: 0.875rem; font-weight: 600; color: var(--text-secondary); cursor: pointer; user-select: none; }
  .qfg-select-all-label input[type=checkbox] { width: 16px; height: 16px; cursor: pointer; accent-color: var(--primary); }
  .qfg-sel-count { font-size: 0.8rem; font-weight: 700; color: var(--primary); background: var(--primary-light); padding: 3px 10px; border-radius: 12px; }
  .tc-checkbox { width: 16px; height: 16px; cursor: pointer; accent-color: var(--primary); flex-shrink: 0; }

  /* ============================================
     MODALS
     ============================================ */
  .qfg-modal-overlay {position: fixed;inset: 0;background: rgba(0, 0, 0, 0.45);z-index: 9999;display: flex;align-items: flex-start;justify-content: center;overflow-y: auto;padding: 40px 20px;}
  .qfg-modal {background: #ffffff;border-radius: 14px;padding: 24px 28px;width: min(580px, 95vw);max-height: 90vh;overflow-y: auto;box-shadow: 0 20px 50px rgba(0, 0, 0, 0.2);}
  .qfg-modal-header { display: flex; justify-content: space-between; align-items: center; font-weight: 800; font-size: 1.05rem; color: var(--text-primary); margin-bottom: 16px; }
  .qfg-modal-close { background: none; border: none; font-size: 1.2rem; cursor: pointer; color: var(--slate-500); transition: all 0.2s ease; }
  .qfg-modal-close:hover { color: var(--danger); }
  .qfg-modal-hint {font-size: 0.8rem;color: #1d8397;margin-bottom: 16px;background: linear-gradient(135deg, #d3f7f9 0%, #e0f2fe 100%);padding: 10px 12px;border-radius: 7px;border-left: 3px solid #1ebbba; }
  .qfg-modal-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
  .qfg-modal-footer { display: flex; justify-content: flex-end; gap: 12px; margin-top: 24px; padding-top: 16px; border-top: 1px solid var(--border); }

  /* ============================================
     COLLAPSIBLE SECTIONS
     ============================================ */
  .qfg-toggle-header { display: flex; align-items: center; cursor: pointer; margin: 14px 0 8px; padding: 12px 16px; background: var(--slate-50); border: 1px solid var(--border); border-radius: 10px; user-select: none; transition: all 0.2s ease; gap: 12px; }
  .qfg-toggle-header:hover { background: var(--slate-100); border-color: var(--slate-300); transform: translateY(-1px); box-shadow: var(--shadow-sm); }
  .qfg-toggle-icon { font-size: 1rem; color: var(--slate-500); font-weight: 900; transition: transform 0.2s; display: inline-flex; align-items: center; justify-content: center; width: 20px; height: 20px; }
  .qfg-toggle-header.open .qfg-toggle-icon { transform: rotate(90deg); }
  .qfg-toggle-header:not(.open) .qfg-toggle-icon { transform: rotate(0deg); }
  .qfg-toggle-header.open { background: #ffffff; border-color: var(--slate-300); }
  .qfg-collapse-content { max-height: 0; opacity: 0; overflow: hidden; transition: max-height 0.4s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.3s ease, margin 0.3s ease; pointer-events: none; padding: 0; }
  .qfg-collapse-content.open { max-height: 500px; opacity: 1; margin-bottom: 12px; pointer-events: auto; padding-top: 12px; }

  .qfg-plan-block {
  border:1px solid #f0f0f0;border-radius:12px;padding:16px;margin-bottom:14px;position:relative;
  }
@media (max-width: 480px) {
  .qfg-modal {
    width: 100vw;
    height: 100vh;
    border-radius: 0;
    max-height: 100vh;
  }
}
</style>

<div class="qfg-wrap">
  <div class="qfg-title-block ">
    <h1>Project Configuration</h1>
    <p>Select a schema level, describe your requirements, and generate test cases with AI.</p>
  </div>

  <div class="qfg-card">
    <!--<div class="qfg-card-title">Project Configuration</div>-->

    <!-- Project Name (always visible, must be filled first) -->
    <div class="qfg-field">
      <label>Project Name<span class="req">*</span></label>
      <input type="text" id="qfg-project" placeholder="Enter Project Name" />
    </div>

    <!-- Schema Level -->
    <div class="qfg-field">
      <label>Schema Level<span class="req">*</span></label>
      <select id="qfg-schema">
        <option value="">-- Select Schema Level --</option>
        <option value="3_level">3-Level: Project &#8594; Test Cases &#8594; Evidence</option>
        <option value="4_level">4-Level: Project &#8594; Suite &#8594; Test Cases &#8594; Evidence</option>
        <option value="5_level">5-Level: Project &#8594; Plan &#8594; Suite &#8594; Test Cases &#8594; Evidence</option>
      </select>
    </div>

    <!-- Schema banner -->
    <div id="qfg-schema-banner"></div>

    <!-- Reveal on schema select -->
    <div id="qfg-reveal">


      <!-- Plan section (5-level only) — multiple plans -->
      <div id="qfg-plan-section" style="display:none">
        <div class="qfg-section-lbl" >&#128204; Plan Details</div>
        <div id="qfg-plan-list"></div>
        <button class="qfg-add-suite" id="qfg-add-plan-btn" >&#43; Add Another Plan</button>
        <div style="height:18px"></div>
      </div>

      <!-- Suite section (4-level only — standalone) -->
      <div id="qfg-suites-section" style="display:none">
        <div class="qfg-section-lbl" >&#9776; Suite Details</div>
        <div id="qfg-suite-list"></div>
        <button class="qfg-add-suite" id="qfg-add-suite-btn">&#43; Add Another Suite</button>
        <div style="height:18px"></div>
      </div>

      <!-- Requirements (only shown for 3-level; 4/5-level have per-suite req) -->
      <div id="qfg-req-section">
        <div class="qfg-section-lbl" style="color:#334155"> Requirements</div>
        <div class="qfg-row" style="margin-bottom:14px">
          <div class="qfg-field"><label>Requirement ID<span class="req">*</span></label><input type="text" id="qfg-req-id" placeholder="REQ-001" value="REQ-001" /></div>
          <div class="qfg-field"><label>Requirement Title</label><input type="text" id="qfg-req-title" placeholder="e.g. User Login Flow" /></div>
        </div>
        <div class="qfg-field">
          <label>Requirement Description</label>
          <textarea id="qfg-req-desc" rows="2" placeholder="Brief description of the requirement scope..."></textarea>
        </div>
        <div class="qfg-field">
          <label>Requirement Details<span class="req">*</span>
            <button class="qfg-refine-btn " id="qfg-refine-btn">&#10024; AI Refine</button>
          </label>
          <textarea id="qfg-req-text" name="requirement_text" rows="5" placeholder="Enter your requirements here (one per line or separated by bullets)..."></textarea>
          <div class="hint">&#128161; Requirement Details will be used to generate test cases.</div>
        </div>
        <div class="qfg-field" style="margin-bottom:4px">
          <label>Test Cases Count</label>
          <input type="number" id="qfg-count" value="5" min="1" max="50" style="width:80px"/>
          <span class="hint" style="margin-left:8px">Total test cases to generate</span>
        </div>
      </div><!-- /qfg-req-section (3-level only) -->

      <!-- Test Cycle Details — shared across all schema levels -->
      <div class="qfg-toggle-header" id="qfg-params-toggle">
        <span class="qfg-toggle-icon">&#10095;</span>
        <div class="qfg-section-lbl" style="color:#334155;margin:0">Test Cycle Details</div>
      </div>
      
      <div id="qfg-params-collapse" class="qfg-collapse-content">
        <div style="margin-bottom:0">
          <div class="qfg-field"><label>Default Assignee</label><select id="qfg-creator"></select></div>
        </div>
        <div class="qfg-row3" style="margin-bottom:8px">
          <div class="qfg-field"><label>Test Type</label><select id="qfg-testtype"></select></div>
          <div class="qfg-field"><label>Cycle</label><input type="text" id="qfg-cycle" value="1.0" placeholder="Ver 1.0" /></div>
          <div class="qfg-field"><label>Cycle Date</label>
            <div style="position:relative;display:flex;align-items:center;">
              <input type="text" id="qfg-cycle-date-display" placeholder="MM-DD-YYYY"
                style="width:100%;cursor:pointer;padding-right:28px;" />
              <input type="hidden" id="qfg-cycle-date"  placeholder="MM-DD-YYYY"/>
              <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
            </div>
          </div>
        </div>
      </div>

    </div><!-- /reveal -->
    <!-- Buttons -->
      <div class="qfg-footer-btns">
        <button class="qfg-btn-reset" id="qfg-reset-btn">Reset</button>
        <button class="qfg-btn-generate" id="qfg-gen-btn">
          <span id="qfg-btn-icon">&#10024;</span>
          <span id="qfg-btn-text">Create Test Cases</span>
        </button>
      </div>

      <!-- Footer Buttons moved outside scroll but inside card -->
  </div><!-- /card -->

  <!-- Results -->
  <div id="qfg-results" class="qfg-card" style="display:none"></div>
  <!-- Modal structure -->
<div id="bulkModal" class="modal">
  <div class="modal-content">
    <span id="bulkModalClose" class="close">&times;</span>
    <div class="modal-header">
      <h2 id="bulkModalTitle"></h2>
    </div>
    <div class="modal-body">
      <p id="bulkModalMessage"></p>
    </div>
    <div class="modal-footer">
      <button id="bulkModalOk">OK</button>
    </div>
  </div>
</div>

<style>
/* Overlay */
.modal {
  display: none;
  position: fixed;
  z-index: 9999;
  left: 0; top: 0;
  width: 100%; height: 100%;
  background: rgba(0,0,0,0.5);
  animation: fadeIn 0.3s ease;
}

/* Modal box */
.modal-content {
  background: #fff;
  margin: 10% auto;
  padding: 0;
  border-radius: 12px;
  width: 600px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.25);
  overflow: hidden;
  animation: slideUp 0.4s ease;
  position: relative;
}

/* Header */
.modal-header {
  background: #0ea5e9;
  color: #fff;
  padding: 10px 16px;
  text-align: center;
}
.modal-header h2 {
  margin: 0;
  font-size: 1rem;
}

/* Body */
.modal-body {
  padding: 20px;
  color: #1e293b;
  font-size: 0.95rem;
}

/* Footer */
.modal-footer {
  padding: 10px;
  text-align: center;
  background: #f8fafc;
}
#bulkModalOk {
  padding: 10px 20px;
  background: #0ea5e9;
  color: #fff;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  transition: background 0.2s ease;
}
#bulkModalOk:hover {
  background: #0284c7;
}

/* Close button */
.close {
  position: absolute;
  right: 14px; top: 10px;
  font-size: 22px;
  cursor: pointer;
  color: #fff;
}

/* Animations */
@keyframes fadeIn { from {opacity:0;} to {opacity:1;} }
@keyframes slideUp { from {transform:translateY(40px);} to {transform:translateY(0);} }
</style>

</div>
' AS html;
