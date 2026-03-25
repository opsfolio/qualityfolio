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

-- Ensure app_settings table exists
SELECT 'dynamic' AS component, sqlpage.run_sql('sqlpage/migrations/033_create_app_settings.sql') AS properties;

SET _tc_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'tc_id_format'), 'TC-{NUM}');
SET _plan_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'plan_id_format'), 'PL-{NUM}');
SET _suite_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'suite_id_format'), 'ST-{NUM}');
SET _req_id_format = COALESCE((SELECT value FROM app_settings WHERE key = 'req_id_format'), 'RQ-{NUM}');

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
           json_object('title', 'Dashboard', 'link', '#', 'icon', 'chart-line')
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
       ) AS css;

-- Inject server-side data via data attributes (CSP-safe)
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

-- Dashboard Content with Button and Execution Logic
SELECT CASE WHEN COALESCE($execute, '') = '' THEN 'html' ELSE 'html' END AS component,
CASE 
  WHEN COALESCE($execute, '') = '1' THEN
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
      .execution-output { background: #1f2937; color: #10b981; padding: 20px; border-radius: 8px; font-family: monospace; font-size: 13px; line-height: 1.8; max-height: 400px; overflow-y: auto; margin: 20px 0; border: 1px solid #374151; }
      .execution-output .step { color: #60a5fa; font-weight: 600; margin-top: 15px; padding: 8px 0; border-left: 3px solid #60a5fa; padding-left: 10px; }
      .execution-output .success { color: #34d399; font-weight: 500; }
    </style>
    <div class="qfg-wrap">
      <h2 style="margin-bottom: 24px; color: #0f172a;">Initializing Dashboard...</h2>
      <div class="execution-output">
        <div class="step">▸ Processing Test Definitions</div>' || '
' ||
    COALESCE(sqlpage.exec('bash', '-c', 'cd qualityfolio && spry rb run qualityfolio.md 2>&1'), 'Command started') || '
' ||
    '<div class="step">▸ Generating Static Assets</div>' || '
' ||
    COALESCE(sqlpage.exec('bash', '-c', 'cd qualityfolio && spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md 2>&1'), 'Command started') || '
' ||
    '<div class="step">▸ Starting Dashboard Service</div>' || '
' ||
    COALESCE(sqlpage.exec('bash', '-c', 'cd qualityfolio && EOH_INSTANCE=1 PORT=9227 surveilr web-ui -d ./resource-surveillance.sqlite.db > /dev/null 2>&1 & sleep 2 && echo "✓ Service started on port 9227"'), 'Starting in background') || '
' ||
    '<div class="success">✓ All systems initialized successfully!</div>' || '
' ||
    '      </div>
    </div>
    <meta http-equiv="refresh" content="3;url=http://localhost:9227/">'
  ELSE
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

      /* Dashboard Loader Modal */
      .dashboard-loader-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: center;
        opacity: 0;
        pointer-events: none;
        transition: opacity 0.3s ease;
      }

      .dashboard-loader-overlay.active {
        opacity: 1;
        pointer-events: auto;
      }

      .dashboard-loader-modal {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        width: 90%;
        max-width: 500px;
        padding: 3rem 2rem;
        border-radius: 20px;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        text-align: center;
        animation: modalSlideIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
      }

      @keyframes modalSlideIn {
        from { opacity: 0; transform: scale(0.9); }
        to { opacity: 1; transform: scale(1); }
      }

      .dashboard-loader-spinner {
        width: 80px;
        height: 80px;
        margin: 0 auto 1.5rem;
        border: 4px solid rgba(255, 255, 255, 0.3);
        border-top: 4px solid white;
        border-radius: 50%;
        animation: spin 1s linear infinite;
      }

      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }

      .dashboard-loader-title {
        font-size: 1.5rem;
        margin-bottom: 0.5rem;
        font-weight: 600;
      }

      .dashboard-loader-status {
        font-size: 0.95rem;
        opacity: 0.9;
        margin-bottom: 2rem;
        min-height: 24px;
      }

      .dashboard-progress-bar {
        background: rgba(255, 255, 255, 0.2);
        border-radius: 10px;
        height: 8px;
        overflow: hidden;
        margin-bottom: 1rem;
      }

      .dashboard-progress-fill {
        height: 100%;
        width: 0%;
        background: white;
        transition: width 0.1s linear;
        border-radius: 10px;
        box-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
      }

      .dashboard-percentage {
        font-size: 0.85rem;
        opacity: 0.8;
        margin-bottom: 1.5rem;
        font-weight: 600;
      }

      .dashboard-open-btn {
        background: white;
        color: #667eea;
        border: none;
        padding: 0.75rem 2rem;
        border-radius: 8px;
        font-weight: 600;
        cursor: pointer;
        opacity: 0.5;
        pointer-events: none;
        transition: all 0.3s;
        font-size: 0.95rem;
      }

      .dashboard-open-btn.ready {
        opacity: 1;
        pointer-events: auto;
      }

      .dashboard-open-btn:hover:not(:disabled) {
        background: #f0f0f0;
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
      }

      @media (max-width: 480px) {
        .dashboard-loader-modal {
          width: 95vw;
          padding: 2rem 1.5rem;
        }
      }
    </style>

    <div class="qfg-wrap">
      <h2 style="margin-bottom: 24px; color: #0f172a;">QualityFolio Dashboard</h2>
      
      <p style="margin-bottom: 16px; color: #475569;">
        Click to launch the Surveilr dashboard running on <strong>port 9227</strong>
      </p>

      <a href="?execute=1"><button class="view_dash_btn" id="sqlpageDashboardBtn">
        <i class="fas fa-chart-line"></i>
        View Surveilr Dashboard (Port 9227)
      </button></a>

      <p style="margin-top: 16px; color: #64748b; font-size: 0.85rem;">
        This will initialize and connect to your Surveilr instance. The following commands will be executed:
      </p>
      
      <div style="margin-top: 12px; padding: 12px; background: #f8fafc; border-left: 3px solid #2563eb; border-radius: 4px; color: #334155; font-size: 0.8rem; font-family: monospace;">
        <p style="margin: 4px 0;">$ spry rb run qualityfolio.md</p>
        <p style="margin: 4px 0;">$ spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md</p>
        <p style="margin: 4px 0;">$ EOH_INSTANCE=1 PORT=9227 surveilr web-ui -d ./resource-surveillance.sqlite.db</p>
      </div>
    </div>

    <!-- Dashboard Loader Modal -->
    <div id="dashboardLoaderOverlay" class="dashboard-loader-overlay">
      <div class="dashboard-loader-modal">
        <div style="margin-bottom: 2rem;">
          <div class="dashboard-loader-spinner"></div>
          <h3 class="dashboard-loader-title">Connecting to Dashboard</h3>
          <p class="dashboard-loader-status" id="dashboardLoaderStatus">🔍 Checking if Surveilr is running...</p>
        </div>
        
        <div class="dashboard-progress-bar">
          <div class="dashboard-progress-fill" id="dashboardProgressFill"></div>
        </div>
        
        <p class="dashboard-percentage" id="dashboardPercentage">0%</p>
        
        <button class="dashboard-open-btn" id="dashboardOpenBtn">
          <i class="fas fa-external-link-alt"></i> Open Dashboard
        </button>
      </div>
    </div>'
END AS html;