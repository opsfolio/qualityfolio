-- ============================================================================
-- QualityFolio Tab Bar Component for SQLPage
-- ============================================================================
-- This component creates a modern tab bar with preview, hierarchy, markdown,
-- and JSON views. Can be integrated into any SQLPage application.
--
-- Usage in entries.sql:
-- SELECT 'html' AS component, qfg_tab_bar_html() AS html;
-- ============================================================================

-- ============================================================================
-- Function: Generate Tab Bar HTML with embedded styles
-- ============================================================================
-- SELECT 'html' AS component, qfg_tab_bar_html() AS html;

SELECT 'html' AS component, '
<div id="qfg-tab-bar" style="display:flex;gap:8px;margin:14px 0 10px;flex-wrap:wrap;align-items:center;">
  <button id="tab-btn-preview" class="qfg-tab-btn qfg-tab-active" data-tab="preview" title="View test cases in a readable format">
    <span style="margin-right:4px;">👁️</span> Preview
  </button>
  <button id="tab-btn-hierarchy" class="qfg-tab-btn" data-tab="hierarchy" title="View project hierarchy and structure">
    <span style="margin-right:4px;">🧩</span> Hierarchy
  </button>
  <button id="tab-btn-markdown" class="qfg-tab-btn qfg-tab-md" data-tab="markdown" title="View as Markdown format">
    <span style="margin-right:4px;">📄</span> Markdown
  </button>
  <button id="tab-btn-json" class="qfg-tab-btn qfg-tab-json" data-tab="json" title="View as JSON format">
    <span style="margin-right:4px;">&#123;&#125;</span> JSON
  </button>
</div>

<style>
  /* ══════════════════════════════════════════════════════════════════
     TAB BAR CONTAINER
     ══════════════════════════════════════════════════════════════════ */
  #qfg-tab-bar {
    display: flex;
    gap: 8px;
    margin: 14px 0 10px;
    flex-wrap: wrap;
    align-items: center;
    padding: 8px 0;
  }

  /* ══════════════════════════════════════════════════════════════════
     TAB BUTTONS
     ══════════════════════════════════════════════════════════════════ */
  .qfg-tab-btn {
    padding: 8px 16px;
    border: none;
    border-radius: 5px 5px 0 0;
    font-size: 0.8125rem;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.15s ease;
    background: #e2e8f0;
    color: #475569;
    display: flex;
    align-items: center;
    gap: 6px;
    white-space: nowrap;
    user-select: none;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
  }

  .qfg-tab-btn:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.06);
    opacity: 0.95;
  }

  .qfg-tab-btn:active {
    transform: translateY(0);
  }

  /* Active/Default Preview Tab */
  .qfg-tab-btn.qfg-tab-active {
    background: linear-gradient(135deg, #7c3aed, #6d28d9);
    color: #ffffff;
    font-weight: 700;
    box-shadow: 0 2px 8px rgba(124, 58, 237, 0.25);
  }

  .qfg-tab-btn.qfg-tab-active:hover {
    box-shadow: 0 4px 12px rgba(124, 58, 237, 0.3);
  }

  /* Markdown Tab */
  .qfg-tab-btn.qfg-tab-md {
    background: #0d9488;
    color: #ffffff;
    box-shadow: 0 2px 4px rgba(13, 148, 136, 0.15);
  }

  .qfg-tab-btn.qfg-tab-md:hover {
    background: #14b8a6;
    box-shadow: 0 2px 8px rgba(13, 148, 136, 0.25);
  }

  .qfg-tab-btn.qfg-tab-md.qfg-tab-active {
    background: #0d9488;
    box-shadow: 0 2px 8px rgba(13, 148, 136, 0.25);
  }

  /* JSON Tab */
  .qfg-tab-btn.qfg-tab-json {
    background: #d97706;
    color: #ffffff;
    box-shadow: 0 2px 4px rgba(217, 119, 6, 0.15);
  }

  .qfg-tab-btn.qfg-tab-json:hover {
    background: #ea580c;
    box-shadow: 0 2px 8px rgba(217, 119, 6, 0.25);
  }

  .qfg-tab-btn.qfg-tab-json.qfg-tab-active {
    background: #d97706;
    box-shadow: 0 2px 8px rgba(217, 119, 6, 0.25);
  }

  /* Hierarchy Tab */
  #tab-btn-hierarchy:not(.qfg-tab-active) {
    background: #0ea5e9;
    color: #ffffff;
    box-shadow: 0 2px 4px rgba(14, 165, 233, 0.15);
  }

  #tab-btn-hierarchy:not(.qfg-tab-active):hover {
    background: #38bdf8;
    box-shadow: 0 2px 8px rgba(14, 165, 233, 0.25);
  }

  /* ══════════════════════════════════════════════════════════════════
     TOOLTIP STYLES
     ══════════════════════════════════════════════════════════════════ */
  .qfg-tooltip-wrap {
    position: relative;
    cursor: help;
    display: inline-flex;
  }

  .qfg-tooltip-content {
    visibility: hidden;
    opacity: 0;
    position: absolute;
    bottom: 125%;
    left: 50%;
    transform: translateX(-50%) translateY(10px);
    background: #1e293b;
    color: #f8fafc;
    border-radius: 8px;
    padding: 14px 16px;
    min-width: 300px;
    max-width: 600px;
    width: max-content;
    z-index: 1000;
    font-size: 0.8125rem;
    font-weight: 500;
    line-height: 1.6;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
    pointer-events: none;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    text-align: left;
    border: 1px solid rgba(255, 255, 255, 0.1);
  }

  .qfg-tooltip-content::after {
    content: "";
    position: absolute;
    top: 100%;
    left: 50%;
    margin-left: -6px;
    border-width: 6px;
    border-style: solid;
    border-color: #1e293b transparent transparent transparent;
  }

  .qfg-tooltip-wrap:hover .qfg-tooltip-content {
    visibility: visible;
    opacity: 1;
    transform: translateX(-50%) translateY(0);
  }

  .qfg-tooltip-title {
    font-weight: 800;
    color: #38bdf8;
    margin-bottom: 8px;
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    border-bottom: 1px solid #334155;
    padding-bottom: 6px;
  }

  .qfg-tooltip-text {
    white-space: pre-wrap;
    word-wrap: break-word;
    max-height: 400px;
    overflow-y: auto;
    padding-right: 6px;
  }

  .qfg-tooltip-text::-webkit-scrollbar {
    width: 4px;
  }

  .qfg-tooltip-text::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 2px;
  }

  .qfg-tooltip-text::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.2);
    border-radius: 2px;
  }

  /* ══════════════════════════════════════════════════════════════════
     INPUT & SELECT STYLES
     ══════════════════════════════════════════════════════════════════ */
  .qfg-bulk-select,
  .qfg-bulk-input {
    background: #ffffff;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    padding: 6px 12px;
    font-size: 0.8rem;
    color: #1e293b;
    height: 36px;
    transition: all 0.15s ease;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.03);
    font-family: inherit;
  }

  .qfg-bulk-select:hover,
  .qfg-bulk-input:hover {
    border-color: #94a3b8;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06);
  }

  .qfg-bulk-select:focus,
  .qfg-bulk-input:focus {
    outline: none;
    border-color: #7c3aed;
    box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1), 0 1px 2px rgba(0, 0, 0, 0.05);
  }



  /* ══════════════════════════════════════════════════════════════════
     TAB CONTENT AREA (to be used with JS)
     ══════════════════════════════════════════════════════════════════ */
  .qfg-tab-content {
    display: none;
    animation: fadeIn 0.2s ease;
  }

  .qfg-tab-content.active {
    display: block;
  }

  @keyframes fadeIn {
    from {
      opacity: 0;
      transform: translateY(4px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  /* Responsive design */
  @media (max-width: 768px) {
    .qfg-tab-btn {
      padding: 6px 12px;
      font-size: 0.75rem;
    }

    .qfg-tooltip-content {
      min-width: 200px;
      max-width: 90vw;
      font-size: 0.75rem;
    }
  }
</style>

<script>
  (function initTabBar() {
    const tabButtons = document.querySelectorAll(".qfg-tab-btn");
    const tabContents = document.querySelectorAll(".qfg-tab-content");

    if (!tabButtons.length) return;

    // Attach click handlers to tab buttons
    tabButtons.forEach((button) => {
      button.addEventListener("click", function () {
        const tabName = this.getAttribute("data-tab");
        if (!tabName) return;

        // Remove active class from all buttons
        tabButtons.forEach((btn) => btn.classList.remove("qfg-tab-active"));

        // Add active class to clicked button
        this.classList.add("qfg-tab-active");

        // Hide all tab contents
        tabContents.forEach((content) => content.classList.remove("active"));

        // Show the selected tab content
        const activeContent = document.querySelector(
          `.qfg-tab-content[data-tab="${tabName}"]`
        );
        if (activeContent) {
          activeContent.classList.add("active");
        }

        // Dispatch custom event for external listeners
        window.dispatchEvent(
          new CustomEvent("qfg:tabChanged", { detail: { tab: tabName } })
        );
      });
    });

    // Set initial active tab content (if needed)
    const previewTab = document.querySelector(".qfg-tab-content[data-tab=\"preview\"]");
    if (previewTab) {
      previewTab.classList.add("active");
    }
  })();
</script>
' AS html;