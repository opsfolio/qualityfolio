-- test_case_detail.sql
-- SQLPage Test Case Detail Page
-- Shows comprehensive test case information with tabs, actions, and navigation
-- Usage: test_case_detail.sql?id=TC-001

-- Get test case ID from URL parameter
SET _tc_id = COALESCE(sqlpage.url_param('id'), 'TC-001');

-- Render the shell/layout
SELECT 'shell' AS component,
       'Qualityfolio AI' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
       json_array(
           json_object('title', 'Back to Suites', 'link', 'index.sql', 'icon', 'arrow-left'),
           json_object('title', 'Generator', 'link', 'entries.sql', 'icon', 'pencil'),
           json_object('title', 'Settings', 'link', 'settings.sql', 'icon', 'settings')
       ) AS menu_item,
       json_array(
           '/js/pikaday.js',
           '/js/testcasedetail.js?v=' || CAST(STRFTIME('%s','now') AS TEXT)
       ) AS javascript,
       json_array(
           '/css/theme.css?v=' || CAST(STRFTIME('%s','now') AS TEXT),
           '/css/pikaday.css',
           '/css/testcasedetail.css?v=' || CAST(STRFTIME('%s','now') AS TEXT)
       ) AS css;

-- ════════════════════════════════════════════════════════════════
-- PAGE HEADER WITH TEST CASE ID, TITLE, AND ACTIONS
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
    '<div class="qfg-tc-header">'
    || '  <div class="qfg-tc-header-top">'
    || '    <button class="qfg-btn-back" onclick="goBackToSuites()" title="Back to test suites">← Back</button>'
    || '    <div class="qfg-tc-actions">'
    || '      <button class="qfg-action-btn" onclick="copyTestCase(''' || _tc_id || ''', document.querySelector(''.qfg-tc-title'').textContent)" title="Copy ID and title">📋 Copy</button>'
    || '      <button class="qfg-action-btn" onclick="shareTestCase(''' || _tc_id || ''')" title="Share test case">🔗 Share</button>'
    || '      <button class="qfg-action-btn qfg-btn-edit" onclick="editTestCase(''' || _tc_id || ''')" title="Edit test case">✎ Edit</button>'
    || '      <button class="qfg-action-btn qfg-btn-delete" onclick="deleteTestCase(''' || _tc_id || ''')" title="Delete test case">🗑 Delete</button>'
    || '    </div>'
    || '  </div>'
    || '</div>' AS html;

-- ════════════════════════════════════════════════════════════════
-- FETCH AND DISPLAY TEST CASE OVERVIEW
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
    '<div class="qfg-tc-container">'
    || '  <div class="qfg-tc-title-section">'
    || '    <span class="qfg-tc-id-badge">' || _tc_id || '</span>'
    || '    <h1 class="qfg-tc-title">' || COALESCE(tc.title, 'Test case not found') || '</h1>'
    || '  </div>'
    || '  <div class="qfg-tc-badges">'
    || (
        SELECT GROUP_CONCAT(
            CASE 
                WHEN tcs.name = 'Passed' THEN '<span class="qfg-badge qfg-badge-passed">✓ Passed</span>'
                WHEN tcs.name = 'Failed' THEN '<span class="qfg-badge qfg-badge-failed">✕ Failed</span>'
                WHEN tcs.name = 'Blocked' THEN '<span class="qfg-badge qfg-badge-blocked">⊘ Blocked</span>'
                ELSE '<span class="qfg-badge qfg-badge-todo">○ ' || tcs.name || '</span>'
            END
        )
        FROM test_cases tc2
        LEFT JOIN test_case_statuses tcs ON tc2.status_id = tcs.id
        WHERE tc2.id = _tc_id
    )
    || (
        SELECT GROUP_CONCAT(
            CASE 
                WHEN p.name = 'Critical' THEN '<span class="qfg-badge qfg-badge-critical">Critical</span>'
                WHEN p.name = 'High' THEN '<span class="qfg-badge qfg-badge-high">High</span>'
                WHEN p.name = 'Medium' THEN '<span class="qfg-badge qfg-badge-medium">Medium</span>'
                ELSE '<span class="qfg-badge qfg-badge-low">Low</span>'
            END
        )
        FROM test_cases tc2
        LEFT JOIN test_case_priorities p ON tc2.priority_id = p.id
        WHERE tc2.id = _tc_id
    )
    || '  </div>'
    || '</div>'
FROM test_cases tc
WHERE tc.id = _tc_id;

-- ════════════════════════════════════════════════════════════════
-- TAB NAVIGATION
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
    '<div class="qfg-tc-tabs">'
    || '  <button class="qfg-tab-btn qfg-tab-active" data-tab="overview" onclick="switchTab(event, ''overview'')">📋 Overview</button>'
    || '  <button class="qfg-tab-btn" data-tab="steps" onclick="switchTab(event, ''steps'')">👣 Steps</button>'
    || '  <button class="qfg-tab-btn" data-tab="attachments" onclick="switchTab(event, ''attachments'')">📎 Attachments</button>'
    || '  <button class="qfg-tab-btn" data-tab="history" onclick="switchTab(event, ''history'')">📜 History</button>'
    || '</div>' AS html;

-- ════════════════════════════════════════════════════════════════
-- TAB CONTENT: OVERVIEW
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
    '<div id="overview" class="qfg-tab-content qfg-tab-active">'
    || '  <div class="qfg-tc-grid">'
    || '    <div class="qfg-tc-column-left">'
    || '      <div class="qfg-tc-section">'
    || '        <h3 class="qfg-section-title">Description</h3>'
    || '        <p class="qfg-section-content">' || COALESCE(tc.description, 'No description provided') || '</p>'
    || '      </div>'
    || '      <div class="qfg-tc-section">'
    || '        <h3 class="qfg-section-title">Metadata</h3>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Suite:</span> <span class="qfg-value">' || COALESCE(ts.name, 'N/A') || '</span></div>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Assignee:</span> <span class="qfg-value">' || COALESCE(tm.full_name, 'Unassigned') || '</span></div>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Created By:</span> <span class="qfg-value">' || COALESCE(tc.created_by, 'System') || '</span></div>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Created:</span> <span class="qfg-value">' || DATE(tc.created_date) || '</span></div>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Modified:</span> <span class="qfg-value">' || DATE(tc.modified_date) || '</span></div>'
    || '      </div>'
    || '      <div class="qfg-tc-section">'
    || '        <h3 class="qfg-section-title">Pre-conditions</h3>'
    || COALESCE(
        (SELECT GROUP_CONCAT('<li>' || condition_text || '</li>', '')
         FROM test_preconditions
         WHERE test_case_id = _tc_id),
        '<li>No preconditions defined</li>'
    )
    || '      </div>'
    || '    </div>'
    || '    <div class="qfg-tc-column-right">'
    || '      <div class="qfg-tc-section">'
    || '        <h3 class="qfg-section-title">Test Information</h3>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Related Requirement:</span> <span class="qfg-value">' || COALESCE(req.id, 'N/A') || '</span></div>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Estimated Time:</span> <span class="qfg-value">' || COALESCE(tc.estimated_time, 'N/A') || '</span></div>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Actual Time:</span> <span class="qfg-value">' || COALESCE(tc.actual_time, 'N/A') || '</span></div>'
    || '        <div class="qfg-detail-row"><span class="qfg-label">Environments:</span> <span class="qfg-value">Staging, Production</span></div>'
    || '      </div>'
    || '      <div class="qfg-tc-section">'
    || '        <h3 class="qfg-section-title">Tags</h3>'
    || '        <div class="qfg-tags">'
    || COALESCE(
        (SELECT GROUP_CONCAT('<span class="qfg-tag">' || name || '</span>', '')
         FROM test_case_tags
         WHERE test_case_id = _tc_id),
        '<span style="color: #999;">No tags</span>'
    )
    || '        </div>'
    || '      </div>'
    || '      <div class="qfg-tc-section">'
    || '        <h3 class="qfg-section-title">Post-conditions</h3>'
    || COALESCE(
        (SELECT GROUP_CONCAT('<li>' || condition_text || '</li>', '')
         FROM test_postconditions
         WHERE test_case_id = _tc_id),
        '<li>No postconditions defined</li>'
    )
    || '      </div>'
    || '    </div>'
    || '  </div>'
    || '</div>'
FROM test_cases tc
LEFT JOIN test_suites ts ON tc.suite_id = ts.id
LEFT JOIN team_members tm ON tc.assigned_to = tm.id
LEFT JOIN requirements req ON tc.requirement_id = req.id
WHERE tc.id = _tc_id;

-- ════════════════════════════════════════════════════════════════
-- TAB CONTENT: TEST STEPS
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
    '<div id="steps" class="qfg-tab-content" style="display: none;">'
    || '  <div class="qfg-steps-container">'
    || COALESCE(
        (SELECT GROUP_CONCAT(
            '<div class="qfg-step-card">'
            || '  <div class="qfg-step-number">Step ' || step_number || '</div>'
            || '  <div class="qfg-step-content">'
            || '    <div class="qfg-step-section">'
            || '      <label class="qfg-step-label">Action:</label>'
            || '      <p>' || description || '</p>'
            || '    </div>'
            || '    <div class="qfg-step-section">'
            || '      <label class="qfg-step-label">Expected Result:</label>'
            || '      <p>' || expected_result || '</p>'
            || '    </div>'
            || '  </div>'
            || '</div>',
            ''
        )
         FROM test_steps
         WHERE test_case_id = _tc_id
         ORDER BY step_number),
        '<p style="padding: 20px; color: #999;">No test steps defined</p>'
    )
    || '  </div>'
    || '</div>';

-- ════════════════════════════════════════════════════════════════
-- TAB CONTENT: ATTACHMENTS
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
    '<div id="attachments" class="qfg-tab-content" style="display: none;">'
    || '  <div class="qfg-attachments-container">'
    || COALESCE(
        (SELECT GROUP_CONCAT(
            '<div class="qfg-attachment-item">'
            || '  <div class="qfg-attachment-icon">📎</div>'
            || '  <div class="qfg-attachment-info">'
            || '    <p class="qfg-attachment-name">' || file_name || '</p>'
            || '    <p class="qfg-attachment-size">' || file_size || '</p>'
            || '  </div>'
            || '  <a href="' || file_path || '" class="qfg-download-btn" download>Download</a>'
            || '</div>',
            ''
        )
         FROM test_attachments
         WHERE test_case_id = _tc_id),
        '<p style="padding: 20px; color: #999;">No attachments</p>'
    )
    || '  </div>'
    || '</div>';

-- ════════════════════════════════════════════════════════════════
-- TAB CONTENT: HISTORY
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
    '<div id="history" class="qfg-tab-content" style="display: none;">'
    || '  <div class="qfg-history-container">'
    || COALESCE(
        (SELECT GROUP_CONCAT(
            '<div class="qfg-history-item">'
            || '  <div class="qfg-history-dot"></div>'
            || '  <div class="qfg-history-content">'
            || '    <p class="qfg-history-title">' || action || '</p>'
            || '    <p class="qfg-history-meta">by ' || COALESCE(full_name, 'System') || ' on ' || DATE(change_timestamp) || '</p>'
            || '  </div>'
            || '</div>',
            ''
        )
         FROM (
            SELECT ta.change_timestamp, ta.action, tm.full_name, ta.change_details
            FROM test_case_audit_log ta
            LEFT JOIN team_members tm ON ta.changed_by = tm.id
            WHERE ta.test_case_id = _tc_id
            ORDER BY ta.change_timestamp DESC
            LIMIT 20
         )),
        '<p style="padding: 20px; color: #999;">No history available</p>'
    )
    || '  </div>'
    || '</div>';

-- ════════════════════════════════════════════════════════════════
-- JAVASCRIPT FOR INTERACTIVITY
-- ════════════════════════════════════════════════════════════════

SELECT 'html' AS component,
'<script>
// Back button handler
function goBackToSuites() {
    window.location.href = "index.sql";
}

// Edit test case
function editTestCase(id) {
    window.location.href = "edit_test_case.sql?id=" + encodeURIComponent(id);
}

// Delete test case
function deleteTestCase(id) {
    if (confirm("Are you sure you want to delete this test case? This action cannot be undone.")) {
        // Call your API endpoint
        fetch("/api/test-case/" + encodeURIComponent(id), {
            method: "DELETE"
        }).then(response => {
            if (response.ok) {
                showNotification("Test case deleted successfully", "success");
                setTimeout(() => {
                    window.location.href = "index.sql";
                }, 1500);
            } else {
                showNotification("Failed to delete test case", "error");
            }
        }).catch(err => {
            console.error("Delete error:", err);
            showNotification("Error: " + err.message, "error");
        });
    }
}

// Copy test case ID and title
function copyTestCase(id, title) {
    const text = id + ": " + title;
    navigator.clipboard.writeText(text).then(() => {
        showNotification("✓ Copied to clipboard", "success");
    }).catch(err => {
        console.error("Copy error:", err);
        showNotification("Failed to copy", "error");
    });
}

// Share test case
function shareTestCase(id) {
    const shareText = "Check out test case: " + id;
    navigator.clipboard.writeText(shareText).then(() => {
        showNotification("Share text copied to clipboard", "success");
    }).catch(err => {
        showNotification("Failed to copy", "error");
    });
}

// Tab switching
function switchTab(event, tabName) {
    // Hide all tab contents
    document.querySelectorAll(".qfg-tab-content").forEach(tab => {
        tab.style.display = "none";
    });
    
    // Remove active class from all buttons
    document.querySelectorAll(".qfg-tab-btn").forEach(btn => {
        btn.classList.remove("qfg-tab-active");
    });
    
    // Show selected tab
    document.getElementById(tabName).style.display = "block";
    
    // Mark button as active
    event.target.classList.add("qfg-tab-active");
}

// Notification system
function showNotification(message, type) {
    const notif = document.createElement("div");
    notif.className = "qfg-notification qfg-notification-" + type;
    notif.textContent = message;
    notif.style.cssText = "position:fixed;top:20px;right:20px;padding:12px 16px;background:" + 
        (type === "success" ? "#10b981" : "#ef4444") + ";color:white;border-radius:6px;z-index:9999;font-weight:500;animation:slideIn 0.3s ease;";
    document.body.appendChild(notif);
    
    setTimeout(() => {
        notif.style.animation = "slideOut 0.3s ease";
        setTimeout(() => notif.remove(), 300);
    }, 3000);
}

// Add slide animations
const style = document.createElement("style");
style.textContent = `
    @keyframes slideIn { from { transform: translateX(400px); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
    @keyframes slideOut { from { transform: translateX(0); opacity: 1; } to { transform: translateX(400px); opacity: 0; } }
`;
document.head.appendChild(style);
</script>' AS html;