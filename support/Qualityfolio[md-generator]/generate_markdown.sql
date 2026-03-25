-- ============================================================
-- generate_markdown.sql  (v2 — fixed, stateless, DB-free)
-- ============================================================

-- Guard: redirect back if required fields are empty
SELECT 'redirect' AS component, 'entries.sql' AS link
WHERE NULLIF($project_name, '') IS NULL OR NULLIF($requirement_text, '') IS NULL;

-- Shell
SELECT 'shell' AS component,
       'Qualityfolio AI' AS title,
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
           '/js/layout.js?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
           '/js/chat.js?v='   || CAST(STRFTIME('%s', 'now') AS TEXT)
       ) AS javascript,
       json_array(
           '/css/theme.css?v=' || CAST(STRFTIME('%s', 'now') AS TEXT),
           '/css/chat.css?v='  || CAST(STRFTIME('%s', 'now') AS TEXT)
       ) AS css;

-- ── Capture params ────────────────────────────────────────────
SET _schema     = COALESCE(NULLIF($schema_level,''),   '3_level');
SET _name       = $project_name;
SET _req_id     = COALESCE(NULLIF($requirement_id,''), 'REQ-001');
SET _req_text   = $requirement_text;
SET _count      = CAST(COALESCE(NULLIF($test_cases_count,''), '5') AS INTEGER);
SET _creator    = COALESCE(NULLIF($default_creator,''), 'QA Engineer');
SET _test_type  = COALESCE(NULLIF($test_type,''),       'Functional');
SET _cycle      = COALESCE(NULLIF($cycle,''),            '1.0');
SET _cycle_date = COALESCE(NULLIF($cycle_date,''),       CURRENT_DATE);

-- ── Build AI prompt ───────────────────────────────────────────
SET prompt =
    'You are a senior QA engineer. Generate exactly ' || $_count || ' comprehensive, professional test cases.' || CHAR(10) ||
    'Project: ' || $_name || CHAR(10) ||
    'Test Type: ' || $_test_type || CHAR(10) ||
    'Requirement ID: ' || $_req_id || CHAR(10) ||
    'Requirement: ' || $_req_text || CHAR(10) || CHAR(10) ||
    'Return ONLY a raw JSON array (no markdown fences, no text before/after). Each element must have these exact keys:' || CHAR(10) ||
    '  title, priority (High|Medium|Low), scenario_type (Happy Path|Negative|Edge Case|Boundary),' || CHAR(10) ||
    '  execution_type (Manual|Automated), description, pre_conditions, steps, expected_result' || CHAR(10) ||
    'Example: [{"title":"Verify login with valid credentials","priority":"High","scenario_type":"Happy Path","execution_type":"Manual","description":"Tests that a user can log in successfully.","pre_conditions":"User is registered.","steps":"1. Open login page\\n2. Enter credentials\\n3. Click Login","expected_result":"User is redirected to dashboard."}]';

-- ── Call Groq API ─────────────────────────────────────────────
SET api_key = COALESCE(
    sqlpage.environment_variable('GROQ_API_KEY'),
    sqlpage.environment_variable('API_KEY')
);

SET api_response = sqlpage.fetch(json_object(
    'url',    'https://api.groq.com/openai/v1/chat/completions',
    'method', 'POST',
    'headers', json_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || $api_key
    ),
    'body', json_object(
        'model',       COALESCE(sqlpage.environment_variable('GROQ_MODEL'), 'llama-3.3-70b-versatile'),
        'temperature', 0.4,
        'messages',    json_array(
            json_object('role', 'system', 'content',
                'You are a QA expert. Return ONLY a valid JSON array. No markdown, no code fences, no explanation. Start with [ and end with ].'),
            json_object('role', 'user', 'content', $prompt)
        )
    )
));

-- ── Parse + clean response ────────────────────────────────────
SET raw_json = json_extract($api_response, '$.choices[0].message.content');
SET clean_json = TRIM(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        COALESCE($raw_json, '[]'),
    '```json', ''), '```', ''), CHAR(13), ''), CHAR(9), ''),
    CHAR(10)||CHAR(10), CHAR(10)), '  ', ' ')
);
-- If response starts before '[', trim to first '['
SET clean_json = CASE
    WHEN INSTR($clean_json, '[') > 1
    THEN SUBSTR($clean_json, INSTR($clean_json, '['))
    ELSE $clean_json
END;

-- ── Page header ───────────────────────────────────────────────
SELECT 'html' AS component, '
<style>
.qfr-header { background: linear-gradient(135deg,#1e40af,#0ea5e9); color:#fff; padding:24px 28px; border-radius:12px; margin-bottom:20px; }
.qfr-header h1 { margin:0 0 4px; font-size:1.4rem; font-weight:800; }
.qfr-header p  { margin:0; opacity:.85; font-size:.88rem; }
.qfr-meta { display:flex; flex-wrap:wrap; gap:10px; margin-top:14px; }
.qfr-meta span { background:rgba(255,255,255,.18); border-radius:6px; padding:4px 12px; font-size:.78rem; font-weight:600; }
.qfr-actions { display:flex; gap:10px; margin-bottom:20px; flex-wrap:wrap; }
.qfr-btn-back { background:#f1f5f9; color:#334155; border:1px solid #e2e8f0; border-radius:8px; padding:8px 18px; font-size:.83rem; font-weight:600; cursor:pointer; text-decoration:none; display:inline-flex; align-items:center; gap:6px; }
.qfr-btn-back:hover { background:#e2e8f0; }
.qfr-stat { background:#fff; border:1px solid #e2e8f0; border-radius:10px; padding:8px 18px; font-size:.82rem; color:#64748b; font-weight:500; }
</style>
<div class="qfr-header">
  <h1>&#127775; Generated Test Cases</h1>
  <p>AI-generated from your requirements. Review below, then download as Markdown.</p>
  <div class="qfr-meta">
    <span>&#128193; ' || $_name || '</span>
    <span>&#128204; ' || REPLACE($_schema,'_','-') || '</span>
    <span>&#128196; ' || $_req_id || '</span>
    <span>&#128100; ' || $_creator || '</span>
    <span>&#128197; ' || $_cycle || ' &bull; ' || $_cycle_date || '</span>
    <span>&#9881; ' || $_test_type || '</span>
  </div>
</div>
' AS html;

-- Back button
SELECT 'button' AS component, 'sm' AS size;
SELECT '← Back to Generator' AS title, 'entries.sql' AS link,
       'arrow-left' AS icon, 'outline-secondary' AS color;

-- ── Error state ───────────────────────────────────────────────
SELECT 'alert' AS component,
       'danger' AS color,
       '⚠️ AI Generation Failed' AS title,
       'The AI did not return valid JSON. Check that your GROQ_API_KEY is set in .env and try again. Raw response: ' || COALESCE($raw_json, 'NULL') AS description
WHERE NOT json_valid($clean_json) OR $clean_json IS NULL OR $clean_json = '' OR $clean_json = '[]';

-- ── Case count badge ──────────────────────────────────────────
SELECT 'html' AS component,
    '<div style="margin:16px 0;display:flex;align-items:center;gap:12px;">' ||
    '<span style="background:#eff6ff;color:#1d4ed8;border-radius:999px;padding:5px 16px;font-weight:700;font-size:.88rem;">' ||
    COALESCE((SELECT COUNT(*) FROM json_each($clean_json) WHERE json_valid($clean_json)), 0) ||
    ' Test Cases Generated</span>' ||
    '</div>' AS html
WHERE json_valid($clean_json) AND $clean_json != '[]';

-- ── Astro Results UI Replikation ────────────────────────────
SELECT 'html' AS component,
    '<style>
        :root { --border-color: #e2e8f0; --primary-color: #0ea5e9; --text-primary: #0f172a; --text-secondary: #334155; --text-muted: #64748b; --bg-primary: #ffffff; --border-radius: 12px; }
        .card { background: var(--bg-primary); border-radius: 16px; border: 1px solid var(--border-color); margin-bottom: 2rem; overflow: hidden; }
        .card-header { padding: 1.5rem; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; }
        .form-input { border: 1.5px solid #e2e8f0; border-radius: 10px; padding: 0.75rem 1rem; transition: border-color 0.2s; font-family: inherit; }
        .form-input:focus { outline: none; border-color: var(--primary-color); }
        .btn { display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.75rem 1.5rem; border-radius: 10px; font-weight: 600; cursor: pointer; border: none; font-family: inherit; transition: all 0.2s; }
        .btn-primary { background: #e8f0f5; color: #1e293b; }
        .btn-primary:hover { background: #d1e3ed; transform: translateY(-2px); }
        .btn-secondary { background: #e8f0f5; color: #1e293b; }
        .btn-outline { background: #e8f0f5; border: 1px solid #d1e3ed; color: #1e293b; }
        .btn-outline-danger { background: transparent; border: 1px solid #ef4444; color: #ef4444; }
        .tab-btn { padding: 0.5rem 1rem; background: transparent; border: none; color: var(--text-muted); font-weight: 600; cursor: pointer; border-bottom: 2px solid transparent; transition: all 0.2s; }
        .tab-btn:hover { color: #0f172a; }
        .tab-btn.active { color: var(--primary-color); border-bottom-color: var(--primary-color); }
        .tab-content { display: none; padding: 1.5rem; }
        .tab-content.active { display: block; }
        .results-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; padding: 1.5rem; background: #f8fafc; border-bottom: 1px solid var(--border-color); }
        .stat-card { background: #ffffff; border-radius: 16px; padding: 1.5rem; border: 1px solid var(--border-color); display: flex; align-items: center; gap: 1.25rem; }
        .markdown-editor-area { width: 100%; min-height: 600px; background: #ffffff; border: 1.5px solid var(--border-color); border-radius: 12px; padding: 1.5rem; color: #0f172a; font-family: monospace; }
        
        .tc-card { transition: border-color 0.2s; }
        .tc-card:hover { border-color: var(--primary-color); transform: scale(1.01); box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        .modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.7); display: none; align-items: center; justify-content: center; z-index: 2000; }
        .modal { background: #fff; border-radius: 20px; width: 90%; max-width: 600px; max-height: 90vh; overflow-y: auto; }
        
        /* Tree explorer overrides */
        .tree-explorer { padding: 1rem; color: var(--text-primary); }
        .tree-node { padding: 0.5rem 0; cursor: pointer; }
        .tree-header { display: flex; justify-content: space-between; }
        .tree-children { border-left: 1px solid var(--border-color); padding-left: 1rem; margin-top: 0.25rem; display: none; }
        .tree-node.open > .tree-children { display: block; }
    </style>' ||
    '<div class="card" style="background:#ffffff;border-radius:16px;border:1px solid #e2e8f0;margin-bottom:2rem;overflow:hidden;">' ||
        '<div class="card-header" style="padding:1.5rem;border-bottom:1px solid #f1f5f9;display:flex;justify-content:space-between;align-items:center;">' ||
            '<h3 style="font-size:1.25rem;font-weight:600;color:#0f172a;margin:0;">Generated Suites</h3>' ||
            '<div class="header-actions" style="display:flex;gap:0.5rem;align-items:center;">' ||
                '<input type="text" id="downloadFileName" class="form-input" placeholder="File Name (e.g. TestCases)" value="' || REPLACE($_name, '''', '') || '_' || $_req_id || '" style="padding:0.5rem;font-size:0.9rem;border:1px solid #cbd5e1;border-radius:8px;width:220px;" maxlength="40" />' ||
                '<button class="btn btn-primary" id="downloadBtn" style="background:#0ea5e9;color:#fff;border:none;padding:0.5rem 1rem;border-radius:8px;cursor:pointer;"><i class="fas fa-download"></i> Download</button>' ||
            '</div>' ||
        '</div>' ||
        '<div class="results-stats" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:1rem;padding:1.5rem;background:#f8fafc;border-bottom:1px solid #f1f5f9;">' ||
            '<div class="stat-card" style="background:#ffffff;border-radius:16px;padding:1.5rem;border:1px solid #e2e8f0;display:flex;align-items:center;gap:1.25rem;"><span class="stat-label" style="display:block;font-size:0.875rem;color:#64748b;margin-bottom:0.25rem;">Total Test Cases</span><span class="stat-value" id="totalTestCases" style="font-size:1.75rem;font-weight:700;color:#0f172a;">0</span></div>' ||
            '<div class="stat-card" style="background:#ffffff;border-radius:16px;padding:1.5rem;border:1px solid #e2e8f0;display:flex;align-items:center;gap:1.25rem;"><span class="stat-label" style="display:block;font-size:0.875rem;color:#64748b;margin-bottom:0.25rem;">Time Taken</span><span class="stat-value" id="generationTime" style="font-size:1.75rem;font-weight:700;color:#0f172a;">...</span></div>' ||
        '</div>' ||
        '<div class="results-content" style="width:100%">' ||
            '<div class="tabs" style="display:flex;gap:1rem;padding:1rem 1.5rem;border-bottom:1px solid #f1f5f9;">' ||
                '<button class="tab-btn active" data-tab="preview" style="padding:0.5rem 1rem;background:transparent;border:none;color:#0ea5e9;font-weight:600;cursor:pointer;border-bottom:2px solid #0ea5e9;">Preview</button>' ||
                '<button class="tab-btn" data-tab="treeView" style="padding:0.5rem 1rem;background:transparent;border:none;color:#64748b;font-weight:600;cursor:pointer;border-bottom:2px solid transparent;">Hierarchy</button>' ||
                '<button class="tab-btn" data-tab="markdown" style="padding:0.5rem 1rem;background:transparent;border:none;color:#64748b;font-weight:600;cursor:pointer;border-bottom:2px solid transparent;">Markdown</button>' ||
                '<button class="tab-btn" data-tab="json" style="display:none;">JSON</button>' ||
            '</div>' ||
            '<div class="tab-content active" id="preview" style="padding:1.5rem;display:block;">' ||

                '<div id="testCasesPreview" style="margin-top:1rem;"></div>' ||
            '</div>' ||
            '<div class="tab-content" id="treeView" style="padding:1.5rem;display:none;">' ||
                '<div id="treeViewContent" class="tree-explorer"></div>' ||
            '</div>' ||
            '<div class="tab-content" id="markdown" style="padding:1.5rem;display:none;">' ||
                '<textarea id="markdownContent" class="markdown-editor-area" style="width:100%;min-height:600px;background:#ffffff;border:1.5px solid #e2e8f0;border-radius:12px;padding:1.5rem;color:#0f172a;font-family:monospace;font-size:0.9rem;line-height:1.7;resize:vertical;"></textarea>' ||
            '</div>' ||
            '<div class="tab-content" id="json" style="display:none;"><pre><code id="jsonContent" class="json-content"></code></pre></div>' ||
        '</div>' ||
    '</div>' ||
    '<script>' ||
    'try {' ||
    '  var cleanData = ' || $clean_json || ';' ||
    '  var payload = { projectName: "' || REPLACE($_name, '"', '\"') || '", schemaLevel: "' || REPLACE(COALESCE($_schema, '3_level'), '_level', '') || '", testCases: cleanData };' ||
    '  localStorage.setItem("qf_generated_test_cases", JSON.stringify(payload));' ||
    '} catch(e) { console.error("Error setting test cases data", e); }' ||
    '</script>' ||
    '<script src="/js/results.js"></script>'
    AS html
WHERE json_valid($clean_json) AND $clean_json != '[]';
