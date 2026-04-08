-- QualityFolio Dashboard Page
-- Modified for actual command integration:
-- • spry rb run qualityfolio.md
-- • spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md
-- • EOH_INSTANCE=1 PORT=9227 surveilr web-ui -d ./resource-surveillance.sqlite.db

SET _api_key   = COALESCE(sqlpage.environment_variable('GROQ_API_KEY'), sqlpage.environment_variable('API_KEY'));
SET _api_model = COALESCE(sqlpage.environment_variable('GROQ_MODEL'), 'llama-3.3-70b-versatile');
SET _members   = (SELECT json_group_array(full_name) FROM team_members);
SET _testtypes = (SELECT json_group_array(name) FROM test_types);
SET _statuses  = (SELECT json_group_array(name) FROM test_case_statuses);

-- Optional: Load app settings if needed for other purposes
-- SET _tc_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'tc_id_format'), 'TC-{NUM}');
-- SET _plan_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'plan_id_format'), 'PL-{NUM}');
-- SET _suite_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'suite_id_format'), 'ST-{NUM}');
-- SET _req_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'req_id_format'), 'RQ-{NUM}');

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
           '/js/layout.js?v='         || CAST(STRFTIME('%s','now') AS TEXT),
           '/js/chat.js?v='           || CAST(STRFTIME('%s','now') AS TEXT),
            '/js/pikaday.js',
           '/js/md-date-picker.js?v=' || CAST(STRFTIME('%s','now') AS TEXT),
           '/js/generator.js?v='      || CAST(STRFTIME('%s','now') AS TEXT),
           '/js/dashboard-launcher-commands.js?v=' || CAST(STRFTIME('%s','now') AS TEXT)
       ) AS javascript,
       json_array(
           '/css/theme.css?v=' || CAST(STRFTIME('%s','now') AS TEXT),
           '/css/chat.css?v='  || CAST(STRFTIME('%s','now') AS TEXT),
            '/css/pikaday.css',
           '/css/dashboard-loader.css?v=' || CAST(STRFTIME('%s','now') AS TEXT)
       ) AS css,
       '/images/favicon.ico' AS favicon,
        '© 2026 Qualityfolio. Test assurance as living Markdown.' AS footer;



-- CRITICAL FIX: Only show button on initial load (no execute parameter)
-- When button is clicked, user is redirected to execute_dashboard.sql page which handles command execution
SELECT 'html' AS component,
    '<style>
      :root {
        --primary: #2563eb;
        --primary-dark: #1d4ed8;
        --primary-light: #dbeafe;
        --accent: #0ea5e9;
        --success: #10b981;
        --slate-50: #f8fafc;
        --slate-500: #64748b;
        --text-primary: #0f172a;
        --text-secondary: #475569;
        --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
      }

      .qfg-wrap { padding: 32px 24px; }
      
      .view_dash_btn {
        background: linear-gradient(135deg, var(--primary) 0%, var(--accent) 100%);
        color: #ffffff;
        padding: 12px 28px;
        border-radius: 8px;
        font-weight: 600;
        border: none;
        cursor: pointer;
        transition: all 0.2s ease;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        font-size: 1rem;
      }
      
      .view_dash_btn:hover {
        background: linear-gradient(135deg, var(--primary-dark) 0%, #0284c7 100%);
        transform: translateY(-2px);
        box-shadow: 0 10px 15px rgba(37, 99, 235, 0.3);
      }

      .dashboard-info-box {
        background: #f0f9ff;
        border-left: 4px solid var(--primary);
        padding: 12px;
        border-radius: 4px;
        margin-top: 12px;
        font-size: 0.85rem;
        color: #334155;
        font-family: monospace;
      }

      .dashboard-command {
        display: block;
        margin: 4px 0;
        word-break: break-all;
      }
    </style>

    <div class="qfg-wrap">
      <h2 style="margin-bottom: 24px; color: #0f172a;">Qualityfolio Dashboard</h2>
      
      
      <a href="execute_dashboard.sql"><button class="view_dash_btn" id="sqlpageDashboardBtn">
        <i class="fas fa-chart-line"></i>
        View Qualityfolio Dashboard
      </button></a>

      <p style="margin-top: 16px; color: #475569;">
        Click to launch the Qualityfolio dashboard
      </p>

   
    </div>'
AS html;