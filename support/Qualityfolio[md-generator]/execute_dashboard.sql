-- execute_dashboard.sql
-- This file is called ONLY when the user clicks the button
-- It handles all command execution and output display
-- This page NEVER loads automatically

-- Shell component for page structure
SELECT 'shell' AS component,
       'Qualityfolio AI' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
       json_array(
           json_object('title', 'Generator', 'link', 'entries.sql',   'icon', 'pencil'),
           json_object('title', 'Markdown Editor', 'link', 'md_editor.sql', 'icon', 'file-text'),
           json_object('title', 'Settings',  'link', 'settings.sql',  'icon', 'settings'),
           json_object('title', 'Dashboard', 'link', 'dashboard.sql', 'icon', 'chart-line')
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

-- Display execution interface and run commands
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
      .execution-output { background: #1f2937; color: #10b981; padding: 20px; border-radius: 8px; font-family: monospace; font-size: 13px; line-height: 1.8; max-height: 600px; overflow-y: auto; margin: 20px 0; border: 1px solid #374151; }
      .execution-output .step { color: #60a5fa; font-weight: 600; margin-top: 15px; padding: 8px 0; border-left: 3px solid #60a5fa; padding-left: 10px; }
      .execution-output .success { color: #34d399; font-weight: 500; }
      .execution-output .error { color: #ef4444; font-weight: 500; }
      .back-button { display: inline-block; margin-top: 20px; padding: 10px 20px; background: #2563eb; color: white; text-decoration: none; border-radius: 6px; }
      .back-button:hover { background: #1d4ed8; }
    </style>
    <div class="qfg-wrap">
      <h2 style="margin-bottom: 24px; color: #0f172a;">Initializing Dashboard...</h2>
      <div class="execution-output">
        <div class="step">▸ Processing Test Definitions (spry rb run qualityfolio.md)</div>'
    || COALESCE(sqlpage.exec('bash', '-c', 'cd qualityfolio && spry rb run qualityfolio.md 2>&1'), 'Command execution started')
    || '<div class="step">▸ Generating Static Assets (spry sp spc)</div>'
    || COALESCE(sqlpage.exec('bash', '-c', 'cd qualityfolio && spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md 2>&1'), 'Command execution started')
    || '<div class="step">▸ Starting Dashboard Service (surveilr web-ui)</div>'
    || COALESCE(sqlpage.exec('bash', '-c', 'cd qualityfolio && EOH_INSTANCE=1 PORT=9227 surveilr web-ui -d ./resource-surveillance.sqlite.db > /dev/null 2>&1 & sleep 2 && echo "✓ Service started on port 9227"'), 'Starting in background')
    || '<div class="success">✓ All systems initialized successfully! Redirecting to dashboard...</div>'
    || '      </div>
      <p style="color: #64748b; margin-top: 20px;">
        <a href="dashboard.sql" class="back-button">← Back to Dashboard</a>
      </p>
      <meta http-equiv="refresh" content="3;url=http://localhost:9227/">'
    || '    </div>'
AS html;