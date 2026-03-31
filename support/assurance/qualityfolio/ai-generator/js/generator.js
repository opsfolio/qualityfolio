// js/generator.js — QualityFolio AI Test Case Generator
// CSP-compliant: all event listeners attached programmatically, no inline handlers.
(function () {
  // ── Module-level state ───────────────────────────────────────────
  let _apiKey = "";
  let _apiModel = "llama-3.3-70b-versatile";
  let _members = [];
  let _types = [];
  let _statuses = ["Passed", "Failed", "Blocked", "To-do"];
  let _tcIdFormat = "TC-{NUM}";
  let _planIdFormat = "PL-{NUM}";
  let _suiteIdFormat = "ST-{NUM}";
  let _reqIdFormat = "RQ-{NUM}";
  let _markdownDest = "test-artifacts"; // destination folder, read from server
  let _cases = []; // live array mutated by edit/delete
  let _ctx = {}; // generation context (project, schema, suites, etc.)
  let _currentTab = "preview"; // Track current active tab for tab bar component

  // ════════════════════════════════════════════════════════════════════
  // TAB BAR COMPONENT — Integrated Tab Bar Rendering
  // ════════════════════════════════════════════════════════════════════
  /**
   * Generate the complete tab bar HTML with styles and functionality
   * Usage: const html = tabBarHTML();
   */
  function tabBarHTML() {
    return `
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
    `;
  }

  /**
   * Initialize tab bar event listeners
   * Call this after inserting the tab bar HTML into the DOM
   */
  function initTabBar() {
    const tabButtons = document.querySelectorAll(".qfg-tab-btn");
    const tabContents = document.querySelectorAll(".qfg-tab-content");
    if (!tabButtons.length) return;
    tabButtons.forEach((button) => {
      button.addEventListener("click", function (e) {
        e.preventDefault();
        const tabName = this.getAttribute("data-tab");
        if (!tabName) return;
        _currentTab = tabName;
        tabButtons.forEach((btn) => {
          btn.classList.remove("qfg-tab-active");
          if (btn.getAttribute("data-tab") === "markdown") btn.classList.add("qfg-tab-md");
          else if (btn.getAttribute("data-tab") === "json") btn.classList.add("qfg-tab-json");
        });
        this.classList.add("qfg-tab-active");
        this.classList.remove("qfg-tab-md", "qfg-tab-json");
        tabContents.forEach((content) => content.classList.remove("active"));
        const activeContent = document.querySelector(`.qfg-tab-content[data-tab="${tabName}"]`);
        if (activeContent) activeContent.classList.add("active");
        window.dispatchEvent(new CustomEvent("qfg:tabChanged", { detail: { tab: tabName } }));
      });
    });
    const previewTab = document.querySelector('.qfg-tab-content[data-tab="preview"]');
    if (previewTab) previewTab.classList.add("active");
  }

  /**
   * Insert tab bar into a specific container and initialize
   */
  function insertTabBar(container) {
    const el = typeof container === "string" ? document.querySelector(container) : container;
    if (!el) { console.warn("Tab bar container not found:", container); return; }
    el.innerHTML = tabBarHTML() + el.innerHTML;
    initTabBar();
  }

  /**
   * Switch to a specific tab programmatically
   */
  function switchTab(tabName) {
    const button = document.querySelector(`.qfg-tab-btn[data-tab="${tabName}"]`);
    if (button) button.click();
  }

  /**
   * Get the currently active tab name
   */
  function getCurrentTab() {
    return _currentTab;
  }

  // ── Date Utilities ───────────────────────────────────────────────
  // Convert ISO (YYYY-MM-DD) → display (MM-DD-YYYY)
  function isoToDisplay(iso) {
    if (!iso) return "";
    const p = iso.split("-");
    if (p.length === 3) return p[1] + "-" + p[2] + "-" + p[0];
    return iso;
  }
  // Convert display (MM-DD-YYYY) → ISO (YYYY-MM-DD)
  function displayToIso(disp) {
    if (!disp) return "";
    const p = disp.split("-");
    if (p.length === 3) return p[2] + "-" + p[0] + "-" + p[1];
    return disp;
  }

  /**
   * Attach a Pikaday calendar to a text display input.
   * @param {HTMLInputElement} displayEl  – text input showing MM-DD-YYYY
   * @param {HTMLInputElement} hiddenEl   – hidden date input holding ISO value
   * @param {string}           [isoVal]   – optional initial ISO value
   */
  function qfDatePicker(displayEl, hiddenEl, isoVal) {
    if (!displayEl) return;
    if (typeof window.qfAttachDatePicker === "function") {
      window.qfAttachDatePicker(displayEl, hiddenEl, isoVal);
    } else {
      // Emergency fallback if md-date-picker isn't loaded yet
      if (isoVal) {
        if (hiddenEl) hiddenEl.value = isoVal;
        displayEl.value = isoToDisplay(isoVal);
      }
      setTimeout(() => qfDatePicker(displayEl, hiddenEl, isoVal), 200);
    }
  }

  /**
   * Programmatically set a date field pair (used when opening modals).
   * @param {string} hiddenId   – id of the hidden date input
   * @param {string} displayId  – id of the display text input
   * @param {string} isoVal     – ISO date string YYYY-MM-DD
   */
  function setDateFields(hiddenId, displayId, isoVal) {
    const hiddenEl = document.getElementById(hiddenId);
    const displayEl = document.getElementById(displayId);
    if (hiddenEl) hiddenEl.value = isoVal || "";
    if (displayEl) displayEl.value = isoToDisplay(isoVal);
    // If there's a Pikaday instance, update it too
    if (displayEl && displayEl._pikadayInstance && isoVal) {
      const p = isoVal.split("-");
      if (p.length === 3) {
        displayEl._pikadayInstance.setDate(
          new Date(p[0], p[1] - 1, p[2]),
          true,
        );
      }
    }
  }

  // ── Init (runs after DOM ready) ─────────────────────────────────
  async function init() {
    await initializeMarkdownDestination();

    const cfg = document.getElementById("qfg-config");
    if (cfg) {
      _apiKey = cfg.dataset.key || "";
      _apiModel = cfg.dataset.model || "llama-3.3-70b-versatile";
      try {
        _members = JSON.parse(cfg.dataset.members || "[]");
        _types = JSON.parse(cfg.dataset.testtypes || "[]");
        let parsedSt = JSON.parse(cfg.dataset.statuses || "[]");
        if (parsedSt.length > 0) _statuses = parsedSt;
        if (cfg.dataset.model) _apiModel = cfg.dataset.model;
        if (cfg.dataset.tcidformat) _tcIdFormat = cfg.dataset.tcidformat;
        if (cfg.dataset.planidformat) _planIdFormat = cfg.dataset.planidformat;
        if (cfg.dataset.suiteidformat)
          _suiteIdFormat = cfg.dataset.suiteidformat;
        if (cfg.dataset.reqidformat) _reqIdFormat = cfg.dataset.reqidformat;
        if (cfg.dataset.markdownDest) _markdownDest = cfg.dataset.markdownDest;
      } catch (_) { }
    }
    const today = new Date().toLocaleDateString('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }).replaceAll('/', '-')

    // Init Requirement ID for 3-level if unset
    const prj = (document.getElementById("qfg-project")?.value || "").trim();
    if (!getVal("qfg-req-id")) {
      setVal("qfg-req-id", makeId(_reqIdFormat, 1, prj));
    }
    // Init Cycle Date field with Pikaday
    qfDatePicker(
      document.getElementById("qfg-cycle-date-display"),
      document.getElementById("qfg-cycle-date"),
      today,
    );
    fillSelect("qfg-creator", _members, "-- Select Creator --");
    if (_members.length > 0) setVal("qfg-creator", _members[0]);
    fillSelect("qfg-testtype", _types, "-- Select Test Type --");
    if (_types.length > 0) setVal("qfg-testtype", _types[0]);

    on("qfg-schema", "change", function () {
      onSchemaChange(this.value);
    });
    on("qfg-params-toggle", "click", function () {
      this.classList.toggle("open");
      const coll = document.getElementById("qfg-params-collapse");
      if (coll) coll.classList.toggle("open");
    });
    on("qfg-gen-btn", "click", generateTestCases);
    on("qfg-reset-btn", "click", resetForm);
    on("qfg-add-suite-btn", "click", addSuite);
    on("qfg-add-plan-btn", "click", addPlan);
    on("qfg-refine-btn", "click", aiRefineReq);
  }

  // ── Micro-helpers ────────────────────────────────────────────────
  function on(id, ev, fn) {
    const el = document.getElementById(id);
    if (el) el.addEventListener(ev, fn);
  }
  function setVal(id, v) {
    const el = document.getElementById(id);
    if (el) el.value = v;
  }
  function getVal(id) {
    const el = document.getElementById(id);
    return el ? el.value.trim() : "";
  }

  function esc(s) {
    if (Array.isArray(s)) s = s.join("\n");
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
  function toArr(v) {
    return Array.isArray(v)
      ? v.map(String)
      : String(v || "")
        .split("\n")
        .filter(Boolean);
  }
  function priClass(p) {
    return p === "High" ? "pri-high" : p === "Low" ? "pri-low" : "pri-medium";
  }

  // Build a TC ID from the format pattern stored in settings
  // Tokens: {REQ} → reqId, {NUM} → zero-padded number, {PRJ} → project slug, {SUITE} → first 3 chars of suite name
  /**
   * Universal ID builder using format patterns
   */
  function makeId(pattern, num, prj, suiteName, reqId) {
    const p = pattern || "{NUM}";
    // Use 4-digit padding for TC, 3-digit for others unless explicitly requested
    const pad = p.includes("TC") ? 4 : 3;

    return p
      .replace(/\{REQ\}/g, reqId || "")
      .replace(/\{NUM\}/g, String(num).padStart(pad, "0"))
      .replace(
        /\{PRJ\}/g,
        (prj || "")
          .toLowerCase()
          .replace(/\s+/g, "-")
          .replace(/[^a-z0-9-]/g, ""),
      )
      .replace(
        /\{SUITE\}/g,
        (suiteName || "").replace(/\s+/g, "").substring(0, 3).toUpperCase(),
      );
  }

  function makeTcId(reqId, num, prj, suiteName) {
    return makeId(_tcIdFormat || "{REQ}-TC-{NUM}", num, prj, suiteName, reqId);
  }

  function fillSelect(id, arr, placeholder) {
    const el = document.getElementById(id);
    if (!el) return;
    el.innerHTML =
      `<option value="">${placeholder}</option>` +
      arr.map((v) => `<option value="${esc(v)}">${esc(v)}</option>`).join("");
  }
  function memberOptions(blank) {
    return (
      `<option value="">${blank || "-- Select --"}</option>` +
      _members
        .map((m) => `<option value="${esc(m)}">${esc(m)}</option>`)
        .join("")
    );
  }

  // ── Schema reveal ────────────────────────────────────────────────
  const schemaInfo = {
    "3_level": {
      label: "3-Level",
      crumbs: ["📁 Project", "🗂 Test Cases", "📎 Evidence"],
    },
    "4_level": {
      label: "4-Level",
      crumbs: ["📁 Project", "📋 Suite", "🗂 Test Cases", "📎 Evidence"],
    },
    "5_level": {
      label: "5-Level",
      crumbs: [
        "📁 Project",
        "📌 Plan",
        "📋 Suite",
        "🗂 Test Cases",
        "📎 Evidence",
      ],
    },
  };
  function onSchemaChange(val) {
    const reveal = document.getElementById("qfg-reveal");
    const banner = document.getElementById("qfg-schema-banner");
    const planSec = document.getElementById("qfg-plan-section");
    const suiteSec = document.getElementById("qfg-suites-section"); // 4-level only
    if (!reveal) return;
    if (!val) {
      reveal.classList.remove("open");
      if (banner) banner.className = "qfg-schema-banner";
      return;
    }
    // Block reveal until Project Name is filled
    const projectVal = (
      document.getElementById("qfg-project")?.value || ""
    ).trim();
    if (!projectVal) {
      showModal("Enter Project Name", `Please enter a Project Name before proceeding.`);
      document.getElementById("qfg-schema").value = "";
      reveal.classList.remove("open");
      if (banner) banner.className = "qfg-schema-banner";
      document.getElementById("qfg-project")?.focus();
      return;
    }
    reveal.classList.add("open");
    if (banner) {
      const info = schemaInfo[val];
      const sep = '<span class="qfg-sep"> › </span>';
      banner.innerHTML = `<span class="qfg-badge">${info.label}</span>${sep}${info.crumbs.join(sep)}`;
      banner.className = "qfg-schema-banner show";
    }
    // Show plan section only for 5-level
    if (planSec) planSec.style.display = val === "5_level" ? "" : "none";
    // Show req-text section only for 3-level; for 4/5 req is per-suite
    const reqSection = document.getElementById("qfg-req-section");
    if (reqSection) reqSection.style.display = val === "3_level" ? "" : "none";
    // Suite section (4-level only — 5-level suites live inside each plan block)
    if (suiteSec) {
      suiteSec.style.display = val === "4_level" ? "" : "none";
      if (
        val === "4_level" &&
        !document.querySelector("#qfg-suite-list .qfg-suite-block")
      )
        addSuite();
    }
    // For 5-level: auto-add first plan if list is empty
    if (val === "5_level") {
      const planList = document.getElementById("qfg-plan-list");
      if (planList && !planList.querySelector(".qfg-plan-block")) addPlan();
    }
  }

  // ── Plan builder (5-level) ───────────────────────────────────────
  let planCount = 0;
  let planSuiteCounters = {}; // planIdx -> suite counter within that plan

  function addPlan() {
    planCount++;
    const today = new Date().toISOString().slice(0, 10);
    const todayFmt = (() => {
      const p = today.split("-");
      return `${p[1]}-${p[2]}-${p[0]}`;
    })();
    const opts = _members
      .map((m) => `<option value="${esc(m)}">${esc(m)}</option>`)
      .join("");
    const pid = planCount;
    planSuiteCounters[pid] = 0;

    const div = document.createElement("div");
    div.className = "qfg-plan-block";
    div.dataset.plan = pid;
    div.innerHTML = `
      <button class="qfg-remove-suite qfg-remove-plan" title="Remove Plan" style="top:10px;right:12px">✕</button>
      <div style="font-weight:700;font-size:.85rem;color:#35a0d0;margin-bottom:12px"> Plan ${pid}</div>
      <div class="qfg-row" style="margin-bottom:10px">
        <div class="qfg-field"><label>Plan Name<span class="req">*</span></label><input type="text" class="plan-name" placeholder="e.g. Regression Plan ${pid}"/></div>
        <div class="qfg-field"><label>Plan ID<span class="req">*</span></label><input type="text" class="plan-id" value="${makeId(_planIdFormat, pid, getVal("qfg-project"))}" placeholder="e.g. PLAN-00${pid}"/></div>
      </div>
      <div class="qfg-row" style="margin-bottom:14px">
        <div class="qfg-field"><label>Plan Date</label>
          <div style="position:relative;display:flex;align-items:center;">
            <input type="text" class="plan-date-text" value="${todayFmt}" placeholder="MM-DD-YYYY" style="width:100%;cursor:pointer;padding-right:28px;" />
            <input type="hidden" class="plan-date" value="${today}" />
            <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
          </div>
        </div>
        <div class="qfg-field"><label>Created By</label><select class="plan-creator"><option value="">-- Select --</option>${opts}</select></div>
      </div>
      <div style="border-top:1px dashed #c7d2fe;padding-top:12px;margin-top:4px">
        <div style="font-size:.78rem;font-weight:700;color:#35a0d0;margin-bottom:8px">📋 Suites for this Plan</div>
        <div class="plan-suite-list" data-plan="${pid}"></div>
        <button class="qfg-add-suite add-plan-suite-btn" data-plan="${pid}" style="margin-top:6px;font-size:.78rem;">+ Add Suite to Plan ${pid}</button>
      </div>
    `;
    div
      .querySelector(".qfg-remove-plan")
      .addEventListener("click", function () {
        this.closest(".qfg-plan-block").remove();
      });
    div
      .querySelector(".add-plan-suite-btn")
      .addEventListener("click", function () {
        addSuiteToContainer(this.dataset.plan, this.previousElementSibling);
      });
    document.getElementById("qfg-plan-list").appendChild(div);
    // Attach Pikaday to plan date after DOM insert
    qfDatePicker(
      div.querySelector(".plan-date-text"),
      div.querySelector(".plan-date"),
      today,
    );
    // Auto-add one suite for this new plan
    addSuiteToContainer(pid, div.querySelector(".plan-suite-list"));
  }

  // ── Suite builder (reference-framework aligned) ──────────────────
  let suiteCount = 0;
  function addSuite() {
    suiteCount++;
    const today = new Date().toISOString().slice(0, 10);
    const todayFmt = (() => {
      const p = today.split("-");
      return `${p[1]}-${p[2]}-${p[0]}`;
    })();
    const opts = _members
      .map((m) => `<option value="${esc(m)}">${esc(m)}</option>`)
      .join("");
    const div = document.createElement("div");
    div.className = "qfg-suite-block";
    div.dataset.suite = suiteCount;
    div.innerHTML = `
      <button class="qfg-remove-suite" title="Remove Suite">✕</button>
      <div style="font-weight:700;font-size:.82rem;color:#0ea5e9;margin-bottom:10px">📋 Suite ${suiteCount}</div>
      <div class="qfg-row">
        <div class="qfg-field"><label>Suite Name<span class="req">*</span></label><input type="text" class="suite-name" placeholder="e.g. Login Suite"/></div>
        <div class="qfg-field"><label>Suite ID<span class="req">*</span></label><input type="text" class="suite-id" value="${makeId(_suiteIdFormat, suiteCount, getVal("qfg-project"))}" placeholder="e.g. SUITE-00${suiteCount}"/></div>
      </div>
      <div class="qfg-row">
        <div class="qfg-field"><label>Suite Date</label>
          <div style="position:relative;display:flex;align-items:center;">
            <input type="text" class="suite-date-text" value="${todayFmt}" placeholder="MM-DD-YYYY" style="width:100%;cursor:pointer;padding-right:28px;" />
            <input type="hidden" class="suite-date" value="${today}" />
            <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
          </div>
        </div>
        <div class="qfg-field"><label>Created By</label><select class="suite-creator"><option value="">-- Select --</option>${opts}</select></div>
      </div>
      <div class="qfg-row">
        <div class="qfg-field"><label>Requirement ID<span class="req">*</span></label><input type="text" class="suite-req-id" value="${makeId(_reqIdFormat, suiteCount, getVal("qfg-project"))}" placeholder="e.g. REQ-S00${suiteCount}"/></div>
        <div class="qfg-field"><label>Requirement Title</label><input type="text" class="suite-req-title" placeholder="e.g. User Login Flow"/></div>
      </div>
      <div class="qfg-field" style="margin-top:2px">
        <label>Requirement Details<span class="req">*</span>
          <button type="button" class="btn btn-primary suite-refine-btn suite-refine-btn" style="float:right;margin-bottom:0.9rem">✨ AI Refine</button>
        </label>
        <textarea class="suite-req-text" rows="4" placeholder="Enter requirements for this suite (one per line or bullets)…"></textarea>
      </div>
      <div class="qfg-field">
        <label>Test Cases Count for this Suite<span class="req">*</span></label>
        <input type="number" class="suite-tc-count" value="5" min="1" max="50" style="width:80px"/>
      </div>`;
    div
      .querySelector(".qfg-remove-suite")
      .addEventListener("click", function () {
        this.closest(".qfg-suite-block").remove();
      });
    // Per-suite AI Refine button
    div
      .querySelector(".suite-refine-btn")
      .addEventListener("click", async function () {
        const ta =
          this.closest(".qfg-suite-block").querySelector(".suite-req-text");
        const btn = this;
        if (!ta || !ta.value.trim()) {
          ta && ta.focus();
          return;
        }
        btn.textContent = "⏳ Refining…";
        btn.disabled = true;
        try {
          ta.value = await refineRequirement(ta.value);
        } catch (e) {
          showModal("Refine failed", e.message);
        } finally {
          btn.textContent = "✨ AI Refine";
          btn.disabled = false;
        }
      });
    document.getElementById("qfg-suite-list").appendChild(div);
    // Attach Pikaday to suite date after DOM insert
    qfDatePicker(
      div.querySelector(".suite-date-text"),
      div.querySelector(".suite-date"),
      today,
    );
  }

  // Shared suite-block builder for containers (used by plan-owned suites in 5-level)
  function addSuiteToContainer(planIdKey, container) {
    if (!planSuiteCounters[planIdKey]) planSuiteCounters[planIdKey] = 0;
    planSuiteCounters[planIdKey]++;
    const sc = planSuiteCounters[planIdKey];
    const today = new Date().toISOString().slice(0, 10);
    const todayFmt = (() => {
      const p = today.split("-");
      return `${p[1]}-${p[2]}-${p[0]}`;
    })();
    const opts = _members
      .map((m) => `<option value="${esc(m)}">${esc(m)}</option>`)
      .join("");
    const div = document.createElement("div");
    div.className = "qfg-suite-block plan-owned-suite";
    div.dataset.suite = sc;
    div.style.cssText =
      "background:#fafafe;border:1.5px solid #e2e8f0;border-radius:10px;padding:14px;margin-bottom:10px;position:relative;";
    div.innerHTML = `
      <button class="qfg-remove-suite" title="Remove Suite" style="top:8px;right:10px">✕</button>
      <div style="font-weight:700;font-size:.82rem;color:#35a0d0;margin-bottom:10px">Suite ${sc}</div>
      <div class="qfg-row">
        <div class="qfg-field"><label>Suite Name<span class="req">*</span></label><input type="text" class="suite-name" placeholder="e.g. Login Suite"/></div>
        <div class="qfg-field"><label>Suite ID<span class="req">*</span></label><input type="text" class="suite-id" value="${makeId(_suiteIdFormat, sc, getVal("qfg-project"))}" placeholder="e.g. SUITE-00${sc}"/></div>
      </div>
      <div class="qfg-row">
        <div class="qfg-field"><label>Suite Date</label>
          <div style="position:relative;display:flex;align-items:center;">
            <input type="text" class="suite-date-text" value="${todayFmt}" placeholder="MM-DD-YYYY" style="width:100%;cursor:pointer;padding-right:28px;" />
            <input type="hidden" class="suite-date" value="${today}" />
            <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
          </div>
        </div>
        <div class="qfg-field"><label>Created By</label><select class="suite-creator"><option value="">-- Select --</option>${opts}</select></div>
      </div>
      <div class="qfg-row">
        <div class="qfg-field"><label>Requirement ID<span class="req">*</span></label><input type="text" class="suite-req-id" value="${makeId(_reqIdFormat, sc, getVal("qfg-project"), "", "P" + planIdKey)}" placeholder="e.g. REQ-P${planIdKey}-S${sc}"/></div>
        <div class="qfg-field"><label>Requirement Title</label><input type="text" class="suite-req-title" placeholder="e.g. User Login Flow"/></div>
      </div>
      <div class="qfg-field" style="margin-top:2px">
        <label>Requirement Details<span class="req">*</span>
          <button type="button" class="btn btn-primary suite-refine-btn" style="float:right; margin-bottom:0.9rem">✨ AI Refine</button>
        </label>
        <textarea class="suite-req-text" rows="4" placeholder="Enter requirements for this suite (one per line or bullets)…"></textarea>
      </div>
      <div class="qfg-field">
        <label>Test Cases Count for this Suite<span class="req">*</span></label>
        <input type="number" class="suite-tc-count" value="5" min="1" max="50" style="width:80px"/>
      </div>`;
    div
      .querySelector(".qfg-remove-suite")
      .addEventListener("click", function () {
        this.closest(".qfg-suite-block").remove();
      });
    div
      .querySelector(".suite-refine-btn")
      .addEventListener("click", async function () {
        const ta =
          this.closest(".qfg-suite-block").querySelector(".suite-req-text");
        const btn = this;
        if (!ta || !ta.value.trim()) {
          ta && ta.focus();
          return;
        }
        btn.textContent = "⏳ Refining…";
        btn.disabled = true;
        try {
          ta.value = await refineRequirement(ta.value);
        } catch (e) {
          showModal("Refine failed", e.message);

        } finally {
          btn.textContent = "✨ AI Refine";
          btn.disabled = false;
        }
      });
    container.appendChild(div);
    // Attach Pikaday to plan-owned suite date after DOM insert
    qfDatePicker(
      div.querySelector(".suite-date-text"),
      div.querySelector(".suite-date"),
      today,
    );
  }

  // ── AI Refine ────────────────────────────────────────────────────
  /**
   * Reusable AI Refine logic
   */
  async function refineRequirement(text) {
    if (!text || !text.trim()) return text;
    // If text already looks "professional" (long enough and has specific keywords), skip?
    // Actually user says "auto click" so we run it if it looks like raw input.
    return await callGroq(
      `Expand and improve these requirements into professional, comprehensive statements. Keep all points:\n\n${text}`,
      "You are a senior BA. Return improved requirements text only, no commentary.",
    );
  }

  async function aiRefineReq() {
    const ta = document.getElementById("qfg-req-text");
    const btn = document.getElementById("qfg-refine-btn");
    if (!ta || !ta.value.trim()) {
      if (ta) ta.focus();
      return;
    }
    btn.textContent = "⏳ Refining…";
    btn.disabled = true;
    try {
      ta.value = await refineRequirement(ta.value);
    } catch (e) {
      showModal("Refine failed", e.message);
    } finally {
      btn.textContent = "✨ AI Refine";
      btn.disabled = false;
    }
  }

  // ── AI Refine for individual case modal fields ───────────────────
  async function aiRefineCaseField(fieldId, btnEl) {
    const ta = document.getElementById(fieldId);
    if (!ta || !ta.value.trim()) {
      if (ta) ta.focus();
      return;
    }

    // Gather context from the modal fields
    const title = document.getElementById("ecTitle")?.value.trim() || "";
    const description = document.getElementById("ecDescription")?.value.trim() || "";
    const reqId = document.getElementById("ecReqId")?.value.trim() || "";

    // ecReqDetails uses a BA-style requirement refinement prompt;
    // all other QA fields use the test-case-focused prompt.
    const isReqField = fieldId === "ecReqDetails";

    const fieldLabels = {
      ecPreConditions: "pre-conditions",
      ecSteps: "test steps",
      ecExpected: "expected results",
      ecReqDetails: "requirement details",
    };
    const fieldLabel = fieldLabels[fieldId] || "content";

    const originalText = btnEl.textContent;
    btnEl.textContent = "⏳ Refining…";
    btnEl.disabled = true;

    try {
      if (isReqField) {
        // Requirement-focused refinement — same approach as the main aiRefineReq
        ta.value = await callGroq(
          `Expand and improve the following requirement details into professional, comprehensive statements.\n\n` +
          `Test Case ID context: ${reqId || "N/A"}\n` +
          `Test Case Title: ${title || "N/A"}\n\n` +
          `Current Requirement Details:\n${ta.value}\n\n` +
          `Return only the improved requirements text, no commentary or labels.`,
          "You are a senior Business Analyst. Return only the improved requirements text with no preamble, labels, or markdown fences."
        );
      } else {
        ta.value = await callGroq(
          `You are refining the "${fieldLabel}" section of a test case.\n\n` +
          `Test Case Title: ${title}\nDescription: ${description}\n\n` +
          `Current ${fieldLabel}:\n${ta.value}\n\n` +
          `Improve clarity, completeness, and professional quality. Keep one item per line. Return only the improved content, no commentary.`,
          "You are a Senior QA Engineer. Return only the improved content with no preamble, labels, or markdown."
        );
      }
    } catch (e) {
      showModal("Refine failed", e.message);
    } finally {
      btnEl.textContent = originalText;
      btnEl.disabled = false;
    }
  }

  // ── Groq API ─────────────────────────────────────────────────────
  async function callGroq(userMsg, sysMsg) {
    if (!_apiKey)
      throw new Error(
        "No API key. Check GROQ_API_KEY in .env and restart SQLPage.",
      );
    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: "Bearer " + _apiKey,
      },
      body: JSON.stringify({
        model: _apiModel,
        temperature: 0.4,
        messages: [
          { role: "system", content: sysMsg || "You are a QA expert." },
          { role: "user", content: userMsg },
        ],
      }),
    });
    if (!res.ok) {
      const e = await res.json().catch(() => ({}));
      throw new Error(e.error?.message || res.statusText);
    }
    return (await res.json()).choices?.[0]?.message?.content || "";
  }

  // ── Build AI prompt (shared) ─────────────────────────────────────
  function buildPrompt(opts) {
    const {
      schema,
      project,
      planName,
      suiteName,
      testType,
      reqId,
      reqTitle,
      reqText,
      count,
    } = opts;
    const schemaLabel =
      schema === "3_level"
        ? "3-Level: Project → Test Cases → Evidence"
        : schema === "4_level"
          ? "4-Level: Project → Suite → Test Cases → Evidence"
          : "5-Level: Project → Plan → Suite → Test Cases → Evidence";
    const countWord =
      count === 1 ? "EXACTLY ONE (1) test case" : `EXACTLY ${count} test cases`;

    // Fetch master arrays for dynamic properties
    const optCache = (key, fallback) => {
      try {
        const arr = JSON.parse(localStorage.getItem(key));
        if (Array.isArray(arr) && arr.length) return arr.join("|");
      } catch (e) { }
      return fallback;
    };
    const priStr = optCache("qf_priority_master", "High|Medium|Low|Critical");
    const scenStr = optCache(
      "qf_scenario_types_master",
      "Happy Path|Negative|Edge Case|Boundary|Security|Performance",
    );
    const execStr = optCache("qf_execution_types_master", "Manual|Automated");
    const tagsStr = optCache(
      "qf_tags_master",
      "Functional|Regression|Smoke|UI|API",
    );

    return (
      `You are a Senior QA Test Architect with 10+ years of experience in creating comprehensive test cases for enterprise applications.\n\n` +
      `═══════════════════════════════════════════════════════════\n` +
      `📋 TEST CONTEXT:\n` +
      `═══════════════════════════════════════════════════════════\n` +
      `Schema: ${schemaLabel}\n` +
      `Project: ${project}\n` +
      (planName ? `Plan: ${planName}\n` : "") +
      (suiteName ? `Suite: ${suiteName}\n` : "") +
      `Test Type: ${testType}\n` +
      `Requirement ID: ${reqId}\n` +
      (reqTitle ? `Requirement Title: ${reqTitle}\n` : "") +
      `Requirements:\n${reqText}\n\n` +
      `═══════════════════════════════════════════════════════════\n` +
      `🚨 CRITICAL: Generate ${countWord} — NOT MORE, NOT LESS.\n` +
      `═══════════════════════════════════════════════════════════\n\n` +
      `📝 TITLE RULES (MOST IMPORTANT):\n` +
      `- Titles MUST be full, descriptive sentences (10–20 words)\n` +
      `- ALWAYS start with a verb: "Verify that...", "Ensure...", "Validate...", "Confirm...", "Check..."\n` +
      `- Include the ACTION, the OBJECT/FEATURE, and the CONDITION or EXPECTED BEHAVIOR\n` +
      `- ✅ GOOD: "Verify that a user can login using valid email address and password"\n` +
      `- ✅ GOOD: "Ensure login fails when invalid password is entered with a valid email"\n` +
      `- ✅ GOOD: "Validate that the password field masks input and shows a visibility toggle"\n` +
      `- ❌ BAD: "Valid Login"  (too short, no verb, no context)\n` +
      `- ❌ BAD: "Test login"   (vague, no outcome)\n` +
      `- ❌ BAD: "Invalid login attempt" (no verb, no context)\n\n` +
      `🎨 TEST CASE DISTRIBUTION:\n` +
      `- 50% Happy Path / Positive scenarios (valid inputs, expected workflows)\n` +
      `- 25% Negative / Edge Cases (invalid inputs, boundary values, error handling)\n` +
      `- 15% Security scenarios (injection, auth bypass, data protection)\n` +
      `- 10% UI / UX scenarios (field validation messages, responsiveness)\n\n` +
      `Return ONLY a raw JSON object with the following structure (start with {, end with }, no markdown, no extra text):\n` +
      `{\n` +
      `  "metadata": {\n` +
      `    "project_description": "1-2 sentences summarizing the project validation scope",\n` +
      `    "project_objectives": ["objective 1", "objective 2"],\n` +
      `    "project_risks": ["risk 1", "risk 2"],\n` +
      `    "plan_objectives": ["plan objective 1"],\n` +
      `    "plan_risks": ["plan risk 1"],\n` +
      `    "plan_cycle_goals": ["goal 1"],\n` +
      `    "suite_scope": ["scope point 1"]\n` +
      `  },\n` +
      `  "cases": [\n` +
      `    {\n` +
      `      "testCaseId": "generate a unique ID e.g. TC-001",\n` +
      `      "title": "...",\n` +
      `      "priority": "select 1 from: ${priStr}",\n` +
      `      "scenarioType": "select 1 from: ${scenStr}",\n` +
      `      "executionType": "select 1 from: ${execStr}",\n` +
      `      "tags": ["select 1 or more from: ${tagsStr}"],\n` +
      `      "description": "...",\n` +
      `      "preConditions": ["..."],\n` +
      `      "steps": ["1. ..."],\n` +
      `      "expectedResult": "..."\n` +
      `    }\n` +
      `  ]\n` +
      `}\n\n` +
      `Make sure the "cases" array has EXACTLY ${count} element${count === 1 ? "" : "s"}.`
    );
  }

  // ── Call Groq and parse JSON ──────────────────────────────────────
  async function callGroqForCases(prompt) {
    const raw = await callGroq(
      prompt,
      "You are a Senior QA Architect. Return ONLY a valid JSON object starting with { and ending with }, no markdown, no fences. Each test case title MUST be a full sentence starting with Verify/Ensure/Validate/Confirm/Check.",
    );
    let json = raw.trim();
    const si = json.indexOf("{");
    if (si >= 0) json = json.slice(si);
    const ei = json.lastIndexOf("}");
    if (ei !== -1 && ei < json.length - 1) json = json.slice(0, ei + 1);
    try {
      return JSON.parse(json);
    } catch (_) {
      throw new Error(
        "AI returned invalid JSON. Try again.\n\nRaw: " + raw.slice(0, 300),
      );
    }
  }

  // ── Generate (schema-branched, reference-framework aligned) ───────
  async function generateTestCases() {
    const schema = getVal("qfg-schema");
    const project = getVal("qfg-project");
    if (!schema) {
      showModal("No Schema Level", "Please select a Schema Level.");
      return;
    }
    if (!project) {
      showModal("No Project Name", "Please enter a Project Name.");
      return;
    }

    const creator = getVal("qfg-creator");
    const testType = getVal("qfg-testtype") || "Functional";
    const cycle = getVal("qfg-cycle") || "1.0";
    const cycleDate = getVal("qfg-cycle-date");

    // ── Collect suites for 4-level (standalone suite list) ────────────
    const suiteBlocks4 = Array.from(
      document.querySelectorAll("#qfg-suite-list > .qfg-suite-block"),
    );
    const suites = suiteBlocks4.map((b, i) => ({
      name: b.querySelector(".suite-name")?.value.trim() || `Suite ${i + 1}`,
      id: b.querySelector(".suite-id")?.value.trim() || "",
      date: b.querySelector(".suite-date")?.value || cycleDate,
      creator: b.querySelector(".suite-creator")?.value || creator,
      reqId:
        b.querySelector(".suite-req-id")?.value.trim() || `REQ-S00${i + 1}`,
      reqTitle: b.querySelector(".suite-req-title")?.value.trim() || "",
      reqText: b.querySelector(".suite-req-text")?.value.trim() || "",
      countRaw: b.querySelector(".suite-tc-count")?.value || "",
      count: parseInt(b.querySelector(".suite-tc-count")?.value) || 0,
    }));

    // ── Collect plans for 5-level (each plan has its own suite list) ──
    const planBlocks = Array.from(
      document.querySelectorAll("#qfg-plan-list .qfg-plan-block"),
    );
    const plansInput = planBlocks.map((pb, pi) => {
      const planName =
        pb.querySelector(".plan-name")?.value.trim() || `Plan ${pi + 1}`;
      const planId =
        pb.querySelector(".plan-id")?.value.trim() || `PLAN-00${pi + 1}`;
      const planDate = pb.querySelector(".plan-date")?.value || cycleDate;
      const planCreator = pb.querySelector(".plan-creator")?.value || creator;
      const planSuiteBlocks = Array.from(
        pb.querySelectorAll(".qfg-suite-block"),
      );
      const planSuites = planSuiteBlocks.map((b, si) => ({
        name: b.querySelector(".suite-name")?.value.trim() || `Suite ${si + 1}`,
        id: b.querySelector(".suite-id")?.value.trim() || "",
        countRaw: b.querySelector(".suite-tc-count")?.value || "",
        date: b.querySelector(".suite-date")?.value || planDate,
        creator: b.querySelector(".suite-creator")?.value || planCreator,
        reqId:
          b.querySelector(".suite-req-id")?.value.trim() ||
          `REQ-P${pi + 1}-S${si + 1}`,
        reqTitle: b.querySelector(".suite-req-title")?.value.trim() || "",
        reqText: b.querySelector(".suite-req-text")?.value.trim() || "",
        count: parseInt(b.querySelector(".suite-tc-count")?.value) || 5,
      }));
      return { planName, planId, planDate, planCreator, suites: planSuites };
    });

    const genBtn = document.getElementById("qfg-gen-btn");
    const btnIcon = document.getElementById("qfg-btn-icon");
    const btnText = document.getElementById("qfg-btn-text");
    genBtn.disabled = true;
    if (btnIcon) btnIcon.innerHTML = '<div class="qfg-spinner"></div>';
    if (btnText) btnText.textContent = "Generating…";
    document.getElementById("qfg-results").style.display = "none";

    try {
      let allCases = [];
      let tcNum = 1;
      const usedTitles = new Set();

      // Helper: deduplicate titles
      function dedup(cases) {
        return cases.map((c) => {
          let t = c.title;
          let s = 2;
          while (usedTitles.has(t)) t = `${c.title} (${s++})`;
          usedTitles.add(t);
          c.title = t;
          if (!c.assignee) c.assignee = creator;
          return c;
        });
      }

      if (schema === "3_level") {
        // ── 3-Level: single requirement, single API call ───────────────
        const reqId = getVal("qfg-req-id");
        if (!reqId) {
          showModal("No Requirement ID", "Please enter a Requirement ID.");
          document.getElementById("qfg-req-id")?.focus();
          return;
        }
        let reqText = getVal("qfg-req-text");
        if (!reqText) {
          showModal("No Requirement Details", "Please enter a Requirement Details.");
          genBtn.disabled = false;
          if (btnIcon) btnIcon.innerHTML = "✨";
          if (btnText) btnText.textContent = "Create Test Cases";
          return;
        }

        // Auto-refine if not already "professional" (heuristics or just run it)
        if (reqText.length < 300) {
          // Simple heuristic: if it's short, it needs polish
          if (btnText) btnText.textContent = "Polishing Requirements...";
          reqText = await refineRequirement(reqText);
          setVal("qfg-req-text", reqText);
        }

        const reqTitle = getVal("qfg-req-title");
        const countRaw = getVal("qfg-count");
        if (!countRaw || isNaN(parseInt(countRaw)) || parseInt(countRaw) < 1) {
          showModal("Enter Test Case Count", "Please enter a valid Test Cases Count (minimum 1).");
          document.getElementById("qfg-count")?.focus();
          return;
        }
        const count = parseInt(countRaw);
        const prompt = buildPrompt({
          schema,
          project,
          planName: "",
          testType,
          reqId,
          reqTitle,
          reqText,
          count,
        });
        let resp = await callGroqForCases(prompt);
        let cases = resp.cases || [];
        if (cases.length > count) cases = cases.slice(0, count);
        allCases = dedup(cases);
        _ctx = {
          project,
          schema,
          reqId,
          reqTitle,
          reqText,
          creator,
          testType,
          cycle,
          cycleDate,
          suites: [],
          planName: "",
          planId: "",
          metadata: resp.metadata || {},
        };
      } else if (schema === "4_level") {
        // ── 4-Level: per-suite requirement → separate API call per suite
        if (!suites.length) {
          showModal("Select Suite", "Please add at least one Suite.");
          return;
        }
        const suitesWithCases = [];
        for (const s of suites) {
          if (!s.name) {
            showModal("Enter Suite Name", "Please enter a Suite Name for all suites.");
            return;
          }
          if (!s.id) {
            showModal("Enter Suite ID", `Please enter a Suite ID for suite "${s.name}".`);
            return;
          }
          if (!s.reqId) {
            showModal("Enter Requirement ID", `Please enter a Requirement ID for suite "${s.name}".`);
            return;
          }
          let sReqText = s.reqText;
          if (!sReqText) {
            showModal("Enter Requirement Details", `Please enter Requirement Details for suite "${s.name}".`);
            return;
          }
          if (sReqText.length < 300) {
            if (btnText) btnText.textContent = `Polishing Suite "${s.name}"...`;
            sReqText = await refineRequirement(sReqText);
            // Update the UI
            const b = suiteBlocks4.find(
              (block) => block.dataset.suite == suites.indexOf(s) + 1,
            );
            if (b) {
              const ta = b.querySelector(".suite-req-text");
              if (ta) ta.value = sReqText;
            }
          }

          const prompt = buildPrompt({
            schema,
            project,
            suiteName: s.name,
            testType,
            reqId: s.reqId,
            reqTitle: s.reqTitle,
            reqText: sReqText,
            count: s.count,
          });
          let resp = await callGroqForCases(prompt);
          let cases = resp.cases || [];
          if (cases.length > s.count) cases = cases.slice(0, s.count);
          suitesWithCases.push({
            ...s,
            cases: dedup(cases),
            metadata: resp.metadata || {},
          });
          allCases = allCases.concat(
            suitesWithCases[suitesWithCases.length - 1].cases,
          );
        }
        _ctx = {
          project,
          schema,
          reqId: suites[0].reqId,
          reqTitle: suites[0].reqTitle,
          reqText: suites[0].reqText,
          creator,
          testType,
          cycle,
          cycleDate,
          suites,
          suitesWithCases,
          planName: "",
          planId: "",
          metadata:
            suitesWithCases.length > 0 ? suitesWithCases[0].metadata : {},
        };
      } else {
        // ── 5-Level: multiple plans, each with their own suites
        if (!plansInput.length) {
          showModal("Add Plan", "Please add at least one Plan.");
          return;
        }
        const plansWithData = [];
        for (const plan of plansInput) {
          if (!plan.planName) {
            showModal("Enter Plan Name", "Please enter a Plan Name for all plans.");
            return;
          }
          if (!plan.planId) {
            showModal("Enter Plan ID", `Please enter a Plan ID for plan "${plan.planName}".`);
            return;
          }
          if (!plan.suites.length) {
            showModal("Add Suite to Plan", `Please add at least one Suite to Plan "${plan.planName}".`);
            return;
          }
          const suitesWithCases = [];
          for (const s of plan.suites) {
            if (!s.name) {
              showModal("Enter Suite Name", `Please enter a Suite Name for all suites in Plan "${plan.planName}".`);
              return;
            }
            if (!s.id) {
              showModal("Enter Suite ID", `Please enter a Suite ID for suite "${s.name}" in Plan "${plan.planName}".`);
              return;
            }
            if (!s.reqId) {
              showModal("Enter Requirement ID", `Please enter a Requirement ID for suite "${s.name}" in Plan "${plan.planName}".`);
              return;
            }
            let sReqText = s.reqText;
            if (!sReqText) {
              showModal("Enter Requirement Details", `Please enter Requirement Details for suite "${s.name}" in Plan "${plan.planName}".`);
              return;
            }
            if (sReqText.length < 300) {
              if (btnText)
                btnText.textContent = `Polishing "${plan.planName}" > "${s.name}"...`;
              sReqText = await refineRequirement(sReqText);
              // Update the UI
              const pb = planBlocks.find(
                (block) => block.dataset.plan == plansInput.indexOf(plan) + 1,
              );
              if (pb) {
                const sb = Array.from(
                  pb.querySelectorAll(".qfg-suite-block"),
                ).find(
                  (block) => block.dataset.suite == plan.suites.indexOf(s) + 1,
                );
                if (sb) {
                  const ta = sb.querySelector(".suite-req-text");
                  if (ta) ta.value = sReqText;
                }
              }
            }

            const prompt = buildPrompt({
              schema,
              project,
              planName: plan.planName,
              suiteName: s.name,
              testType,
              reqId: s.reqId,
              reqTitle: s.reqTitle,
              reqText: sReqText,
              count: s.count,
            });
            let resp = await callGroqForCases(prompt);
            let cases = resp.cases || [];
            if (cases.length > s.count) cases = cases.slice(0, s.count);
            const dedupedCases = dedup(cases);
            suitesWithCases.push({
              ...s,
              cases: dedupedCases,
              metadata: resp.metadata || {},
            });
            allCases = allCases.concat(dedupedCases);
          }
          plansWithData.push({
            planName: plan.planName,
            planId: plan.planId,
            planDate: plan.planDate,
            planCreator: plan.planCreator,
            suitesWithCases,
          });
        }
        _ctx = {
          project,
          schema,
          reqId: plansInput[0].suites[0]?.reqId || "REQ-001",
          reqTitle: plansInput[0].suites[0]?.reqTitle || "",
          reqText: plansInput[0].suites[0]?.reqText || "",
          creator,
          testType,
          cycle,
          cycleDate,
          suites: plansInput[0].suites, // kept for compat with buildMarkdown fallback
          plans: plansWithData, // multi-plan array
          planName: plansWithData[0].planName,
          planId: plansWithData[0].planId,
          metadata: plansWithData[0].suitesWithCases[0]?.metadata || {},
        };
      }

      // Seed default evidenceHistory on every case that doesn't already have one.
      // This ensures the duplicate-cycle check in ADD RUN works from the very first click,
      // matching what the Edit modal UI shows by default.
      const _defaultDate = cycleDate || new Date().toISOString().split("T")[0];
      allCases.forEach((c) => {
        if (
          !Array.isArray(c.evidenceHistory) ||
          c.evidenceHistory.length === 0
        ) {
          c.evidenceHistory = [
            {
              cycle: cycle || "1.0",
              date: _defaultDate,
              assignee: c.assignee || creator || "",
              status: "To-do",
            },
          ];
        }
      });

      _cases = allCases;
      renderResults(_cases, _ctx);
    } catch (e) {
      const res = document.getElementById("qfg-results");
      res.style.display = "block";
      res.innerHTML = `<div class="qfg-error"><strong>⚠️ Generation Failed</strong><br/>${esc(e.message)}</div>`;
    } finally {
      genBtn.disabled = false;
      if (btnIcon) btnIcon.textContent = "✨";
      if (btnText) btnText.textContent = "Create Test Cases with AI";
    }
  }

  // ── Render Results ───────────────────────────────────────────────
  function renderResults(cases, ctx) {
    const el = document.getElementById("qfg-results");
    el.style.display = "block";

    const today = new Date().toISOString().slice(0, 10);
    const mOpts = memberOptions("-- Assignee --");

    el.innerHTML =
      headerHTML(cases, ctx) +
      tabBarHTML() +
      // ── Preview tab (default active) ────────────────────────────────
      '<div id="qfg-tab-preview">' +
      //bulkToolbarHTML(cases, ctx, today, mOpts) +
      '<div id="qfg-cards-list" style="margin-bottom:12px;">' +
      hierarchyHTML(cases, ctx) +
      "</div>" +
      "</div>" +
      // ── Hierarchy tab ───────────────────────────────────────────────
      '<div id="qfg-tab-hierarchy" style="display:none">' +
      '<div id="qfg-hierarchy-panel" style="padding:16px 0;"></div>' +
      "</div>" +
      // ── Markdown tab (EDITABLE) ─────────────────────────────────────
      '<div id="qfg-tab-markdown" style="display:none">' +
      '<div style="background:#1e293b;border-radius:10px;overflow:hidden">' +
      '<div style="display:flex;align-items:center;gap:8px;padding:10px 14px;background:#0f172a;border-bottom:1px solid #334155;flex-wrap:wrap">' +
      '<span style="font-size:.72rem;font-weight:800;color:#94a3b8;text-transform:uppercase;letter-spacing:.08em">&#128196; Editable Markdown</span>' +
      '<span style="flex:1"></span>' +
      '<button id="qfg-md-copy-btn" style="padding:4px 12px;background:#334155;color:#94a3b8;border:none;border-radius:6px;font-size:.75rem;font-weight:700;cursor:pointer">&#128203; Copy</button>' +
      '<button id="qfg-md-format-btn" style="padding:4px 12px;background:#334155;color:#94a3b8;border:none;border-radius:6px;font-size:.75rem;font-weight:700;cursor:pointer">&#9889; Re-generate</button>' +
      '<button id="qfg-md-dl-btn" style="padding:4px 14px;background:#0d9488;color:#fff;border:none;border-radius:6px;font-size:.75rem;font-weight:700;cursor:pointer">&#11015; Download .md</button>' +
      "</div>" +
      '<textarea id="qfg-md-panel" spellcheck="false" style="width:100%;box-sizing:border-box;background:#0f172a;color:#e2e8f0;padding:20px;font-family:Consolas,monospace;font-size:0.78rem;line-height:1.7;resize:vertical;min-height:480px !important;border:none;outline:none;"></textarea>' +
      "</div>" +
      "</div>" +
      // ── JSON tab ───────────────────────────────────────────────────────
      '<div id="qfg-tab-json" style="display:none">' +
      '<pre id="qfg-json-panel" style="background:#0f172a;color:#a5f3fc;padding:20px;border-radius:10px;overflow-x:auto;font-size:0.78rem;line-height:1.6;white-space:pre-wrap;word-break:break-word;"></pre>' +
      "</div>";

    let modalsContainer = document.getElementById("qfg-modals-container");
    if (!modalsContainer) {
      modalsContainer = document.createElement("div");
      modalsContainer.id = "qfg-modals-container";
      document.body.appendChild(modalsContainer);
    }
    modalsContainer.innerHTML =
      editCaseModalHTML(mOpts) +
      viewCaseModalHTML() +
      editSuiteModalHTML() +
      editPlanModalHTML();

    wireEvents(cases, ctx);

    // ── Init Pikaday on bulk toolbar date (rendered fresh each time) ──
    qfDatePicker(
      document.getElementById("bulkCycleDateText"),
      document.getElementById("bulkCycleDate"),
      today,
    );

    // ── Inject Pikaday theme CSS (once) ──────────────────────────────
    if (!document.getElementById("qf-pikaday-theme")) {
      const ps = document.createElement("style");
      ps.id = "qf-pikaday-theme";
      ps.textContent = `
        .pika-single.qf-pikaday {
          font-family: 'Inter', system-ui, sans-serif;
          border: 1px solid #e2e8f0;
          border-radius: 12px;
          box-shadow: 0 8px 32px rgba(0,0,0,.12);
          background: #fff;
          overflow: hidden;
        }
        .qf-pikaday .pika-lendar { padding: 10px 12px; }
        .qf-pikaday .pika-title { padding: 4px 0 8px; }
        .qf-pikaday .pika-label {
          font-size: .85rem; font-weight: 700; color: #1e293b;
          background: #fff;
        }
        .qf-pikaday .pika-prev, .qf-pikaday .pika-next {
          opacity: .7; transition: opacity .15s;
        }
        .qf-pikaday .pika-prev:hover, .qf-pikaday .pika-next:hover { opacity: 1; }
        .qf-pikaday table { border-collapse: collapse; }
        .qf-pikaday th abbr {
          font-size: .7rem; font-weight: 700; color: #94a3b8;
          text-decoration: none; text-transform: uppercase;
        }
        .qf-pikaday td { padding: 2px; }
        .qf-pikaday .pika-button {
          border-radius: 8px; font-size: .82rem; font-weight: 500;
          color: #334155; padding: 6px 4px; text-align: center;
          transition: background .12s, color .12s;
        }
        .qf-pikaday .pika-button:hover { background: #e0f2fe; color: #0369a1; }
        .qf-pikaday .is-today .pika-button { background: #f0fdf4; color: #16a34a; font-weight: 700; }
        .qf-pikaday .is-selected .pika-button {
          background: linear-gradient(135deg,#2563eb,#0ea5e9);
          color: #fff !important; border-radius: 8px; font-weight: 700;
        }
        .qf-pikaday .is-disabled .pika-button { color: #cbd5e1; cursor: default; }
      `;
      document.head.appendChild(ps);
    }

    // ── Inject hierarchy tree CSS (once) ────────────────────
    if (!document.getElementById("qfg-tree-style")) {
      const s = document.createElement("style");
      s.id = "qfg-tree-style";
      s.textContent = `
        .qfg-tree-node{margin-bottom:4px;}
        .qfg-tree-header{display:flex;align-items:center;gap:8px;padding:9px 14px;border-radius:8px;cursor:pointer;user-select:none;transition:background .15s;}
        .qfg-tree-header:hover{filter:brightness(1.05);}
        .qfg-tree-toggle{font-size:.7rem;color:#94a3b8;min-width:14px;transition:transform .2s;display:inline-block;}
        .qfg-tree-node.open > .qfg-tree-children{display:block;}
        .qfg-tree-node:not(.open) > .qfg-tree-children{display:none;}
        .qfg-tree-node:not(.open) > .qfg-tree-header .qfg-tree-toggle{transform:rotate(-90deg);}
        .qfg-tree-children{padding-left:18px;margin-top:4px;border-left:2px solid #e2e8f0;margin-left:16px;}
        .qfg-tree-actions{display:flex;gap:5px;margin-left:auto;opacity:0;transition:opacity .15s;flex-shrink:0;}
        .qfg-tree-header:hover .qfg-tree-actions{opacity:1;}
        .qfg-tree-act{padding:2px 8px;border-radius:5px;font-size:.7rem;font-weight:700;border:1px solid;cursor:pointer;white-space:nowrap;}
        .qfg-tree-act.edit{background:#eff6ff;border-color:#bfdbfe;color:#1d4ed8;}
        .qfg-tree-act.edit:hover{background:#dbeafe;}
        .qfg-tree-act.del{background:#fff1f2;border-color:#fecaca;color:#b91c1c;}
        .qfg-tree-act.del:hover{background:#fee2e2;}
        .qfg-tree-ev{font-size:.68rem;padding:2px 7px;border-radius:999px;font-weight:600;}
      `;
      document.head.appendChild(s);
    }

    el.scrollIntoView({ behavior: "smooth", block: "start" });
  }

  // ─── HTML builders ───────────────────────────────────────────────

  function headerHTML(cases, ctx) {
    const inp = (id, ph, val, w) =>
      `<input id="${id}" type="text" value="${val}" placeholder="${ph}" class="qfg-bulk-input" style="width:${w};"/>`;

    const btn = (id, label, extraStyle = "") =>
      `<button id="${id}" class="btn btn-sm btn-primary" style="font-weight:700;${extraStyle}">${label}</button>`;
    return `
    <div class="qfg-results-header">
      <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap">
        <h2 style="margin:0">&#9989; ${cases.length} Test Case${cases.length === 1 ? "" : "s"} Generated</h2>
      </div>
      <p style="margin:6px 0 0">AI-generated HFM markdown — use bulk tools and per-case controls to refine, then download.</p>
      <div class="qfg-results-meta">
        <span style="display: flex;align-items: center;gap: 8px;color: #FFF;background: oklch(0.65 0.06 235.9);border-radius:5px">
          &#128193; ${esc(ctx.project)} 
          <button class="qfg-action-sm" id="editProjectBtn" style="background:#fff!important;color:#1e40af!important;border:none!important;box-shadow:0 1px 3px rgba(0,0,0,0.1)!important;padding:2px 8px;font-size:0.7rem;">&#128393; </button>
        </span>
        <span>&#128204; ${ctx.schema === "3_level" ? "3-Level Schema" : ctx.schema === "4_level" ? "4-Level Schema" : "5-Level Schema"}</span>
        <span class="qfg-tooltip-wrap">
          &#128194; ${esc(ctx.reqId)}
          <div class="qfg-tooltip-content">
            <div class="qfg-tooltip-title">Requirement Details</div>
            <div class="qfg-tooltip-text">${esc(ctx.reqText)}</div>
          </div>
        </span>
        <span>&#9881; ${esc(ctx.testType)}</span>
        <span>&#128197; Cycle ID: ${esc(ctx.cycle)}</span>
        <span>&#128196; Cycle Date: ${ctx.cycleDate}</span>
      </div>
      <div style="display:flex;align-items:flex-end;gap:14px;flex-wrap:nowrap;margin: 25px 0 12px 0;">
        
        <!-- File Settings (Outside) -->
        <div style="display:flex;flex-direction:column;gap:4px;flex:1.5;min-width:180px;">
          <span style="font-size:.68rem;font-weight:700;color:#94a3b8;text-transform:uppercase;letter-spacing:0.02em;">File Name</span>
          ${inp("bulkFilename", "filename", esc(ctx.project.replace(/\s+/g, "_") + "_" + ctx.reqId), "100%")}
        </div>

        <div style="display:flex;align-items:center;gap:10px;flex-shrink:0;">
          ${btn("bulkDownloadBtn", '<i class="fas fa-download"></i> Download .md', "font-size: 0.85rem !important; color: #fff;white-space: nowrap; gap:0 !important; padding:10px !important;")}
        </div>
      </div>
    </div>`;
  }

  function tabBarHTML() {
    return `
    <div id="qfg-tab-bar" style="display:flex;gap:8px;margin:14px 0 10px;flex-wrap:wrap; border-bottom :1px solid #F0F0F0">
      <button id="tab-btn-preview"   class="qfg-tab-btn qfg-tab-active" data-tab="preview">&#128065; Preview</button>
      <button id="tab-btn-hierarchy" class="qfg-tab-btn" data-tab="hierarchy">&#127795; Hierarchy</button>
      <button id="tab-btn-markdown"  class="qfg-tab-btn qfg-tab-md" data-tab="markdown">&#128196; Markdown</button>
      <button id="tab-btn-json"      class="qfg-tab-btn qfg-tab-json" data-tab="json">&#123;&#125; JSON</button>
    </div>
    <style>
      .qfg-tooltip-wrap { position: relative; cursor: help; }
      .qfg-tooltip-content {
        visibility: hidden; opacity: 0;
        position: absolute; bottom: 125%; left: 50%; transform: translateX(-50%) translateY(10px);
        background: #1e293b; color: #f8fafc; border-radius: 8px; padding: 14px 16px;
        min-width: 350px; max-width: 700px; width: max-content; z-index: 1000; font-size: 0.85rem; font-weight: 500; line-height: 1.6;
        box-shadow: 0 10px 25px rgba(0,0,0,0.25); pointer-events: none;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        text-align: left;
      }
      .qfg-tooltip-content::after {
        content: ""; position: absolute; top: 100%; left: 50%; margin-left: -6px;
        border-width: 6px; border-style: solid; border-color: #1e293b transparent transparent transparent;
      }
      .qfg-tooltip-wrap:hover .qfg-tooltip-content {
        visibility: visible; opacity: 1; transform: translateX(-50%) translateY(0);
      }
      .qfg-tooltip-title { font-weight: 800; color: #38bdf8; margin-bottom: 8px; font-size: 0.78rem; text-transform: uppercase; letter-spacing: 0.05em; border-bottom: 1px solid #334155; padding-bottom: 4px; }
      .qfg-tooltip-text { white-space: pre-wrap; word-wrap: break-word; max-height: 450px; overflow-y: auto; padding-right: 4px; }
      
      /* Keep existing tab button styles below */
      .qfg-tab-btn{padding:7px 18px;border:none; border-radius: 5px 5px 0 0; font-size:.78rem;font-weight:700;cursor:pointer;transition:all .15s;background:#e2e8f0;color:#475569;}
      .qfg-tab-btn:hover{opacity:.88;}
      .qfg-tab-active{background:oklch(67.66% .1481 238.14)!important;color:#fff!important;}
      .qfg-tab-btn:not(.qfg-tab-active){background: #FFF;color: #333; border: 1px solid #CCC;border-bottom: 0;}
      .qfg-bulk-select, .qfg-bulk-input {
        background: #fff; border: 1px solid #cbd5e1; border-radius: 6px; padding: 10px !important;
        font-size: .8rem; color: #1e293b; transition: all 0.2s;
      }
      .qfg-bulk-select:hover, .qfg-bulk-input:hover { border-color: #94a3b8; }
      .qfg-bulk-select:focus, .qfg-bulk-input:focus { 
        outline: none; border-color: #7c3aed; box-shadow: 0 0 0 3px rgba(124, 58, 237, 0.1); 
      }
      .qfg-bulk-divider { width: 1px; height: 32px; background: #e2e8f0; align-self: flex-end; }
      .qfg-bulk-details[open] summary i.fa-chevron-right, .qfg-run-details[open] summary i.fa-chevron-right { transform: rotate(90deg); }
      .qfg-bulk-details summary:hover , .qfg-run-details summary:hover { background: #ede9fe!important; color: #6d28d9!important; }
      .qfg-bulk-details summary ,.qfg-run-details summary { border: 1px solid transparent; }

    </style>`;
  }

  // function bulkToolbarHTML(cases, ctx, today, mOpts) {
  //   const sel = (id, ph, opts, extraStyle = "") =>
  //     `<select id="${id}" class="qfg-bulk-select" style="${extraStyle}">
  //     <option value="">${ph}</option>${opts}
  //   </select>`;

  //   const inp = (id, ph, val, w) =>
  //     `<input id="${id}" type="text" value="${val}" placeholder="${ph}" class="qfg-bulk-input" style="width:${w};"/>`;

  //   const btn = (id, label, extraStyle = "") =>
  //     `<button id="${id}" class="btn btn-sm" style="font-weight:700;${extraStyle}">${label}</button>`;

  //   const priOpts = `<option>High</option><option>Medium</option><option>Low</option><option>Critical</option>`;
  //   const scOpts = `<option>Happy Path</option><option>Negative</option><option>Edge Case</option><option>Boundary</option><option>Security</option><option>Performance</option>`;
  //   const exOpts = `<option>Manual</option><option>Automated</option>`;
  //   const stOpts = `<option>To-do</option><option>In Progress</option><option>Passed</option><option>Failed</option><option>Blocked</option><option>Skipped</option><option>Pending</option>`;

  //   const tParts = today.split("-");
  //   const todayFmt =
  //     tParts.length === 3 ? `${tParts[1]}-${tParts[2]}-${tParts[0]}` : today;

  //   return `

  //    <!-- ROW 1: Permanent Controls (Select, File Name, Download, Reset) -->

  //   <div class="qfg-bulk-toolbar" style="padding:12px 16px;">      

  //     <!-- Bulk Update Section -->
  //     <section class="bulk-section" style="margin-bottom:20px;">
  //       <h3 style="margin-bottom:10px;"><i class="fas fa-tools"></i> Bulk Update</h3>
  //       <div style="display:flex; gap:25px; align-items:flex-end;">
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Scenario</span>
  //           ${sel("bulkScenarioTypeSelect", "-- Type --", scOpts, "width:100%;")}
  //         </div>
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Execution</span>
  //           ${sel("bulkExecutionTypeSelect", "-- Type --", exOpts, "width:100%;")}
  //         </div>
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Tags</span>
  //           <input id="bulkTagsInput" type="text" value="" placeholder="+ Tag" class="qfg-bulk-input" style="width:100%;"/>
  //         </div>

  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Assignee</span>
  //           ${sel("bulkAssignSelect", "-- Assignee --", mOpts, "width:100%;")}
  //         </div>
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Priority</span>
  //           ${sel("bulkPrioritySelect", "-- Priority --", priOpts, "width:100%;")}
  //         </div>
  //         <div>
  //           ${btn("applyBulkActions", "APPLY", "background:#169fb9;color:#fff;height:42px;padding:10px;margin-top:20px;width:150px;")}
  //         </div>
  //       </div>
  //     </section>

  //     <!-- Run Config Section -->
  //     <section class="run-section">
  //       <h3 style="margin-bottom:10px;"><i class="fas fa-tools"></i> Run Config</h3>
  //       <div style="display:flex; gap:25px; align-items:flex-end;">
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Cycle</span>
  //           ${inp("bulkCycleName", "1.0", esc(ctx.cycle), "100%")}
  //         </div>
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Date</span>
  //           <div style="position:relative;display:flex;align-items:center;">
  //             <input type="text" id="bulkCycleDateText" value="${todayFmt}" class="qfg-bulk-input qf-date" style="width:100%;cursor:pointer;padding-right:26px;" />
  //             <input type="hidden" id="bulkCycleDate" value="${today}" />
  //             <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:0.8rem;"></i>
  //           </div>
  //         </div>
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Run Assignee</span>
  //           ${sel("bulkCycleAssignee", "-- Assignee --", mOpts, "width:100%;")}
  //         </div>
  //         <div style="flex:1;">
  //           <span style="font-size:.65rem;font-weight:700;color:#94a3b8;text-transform:uppercase;">Status</span>
  //           ${sel("bulkCycleStatus", "-- Status --", stOpts, "width:100%;")}
  //         </div>
  //         <div>
  //           ${btn("applyBulkCycle", "ADD RUN", "background:#169fb9;color:#fff;height:42px;padding:10px;margin-top:20px;width:150px;")}
  //         </div>
  //       </div>
  //     </section>
  //   </div>`;
  // }



  // ── Hierarchical cards HTML ──────────────────────────────────────
  function hierarchyHTML(cases, ctx) {
    let html = `<div style="display: flex;align-items: flex-end;gap: 14px;justify-content: space-between;margin-bottom: 12px;background: #b4b2d51a;padding: 10px 15px;">
       <!-- Selection -->
        <div style="display:flex;flex-direction:column;gap:15px;flex-shrink:0;">
          <div style="display:flex;align-items:center;gap:8px;height:34px;">
            <label class="qfg-select-all-label" style="display:flex;align-items:center;gap:6px;white-space:nowrap;padding:0 4px;margin:0;cursor:pointer;">
              <input type="checkbox" id="selectAllTcs" style="width:16px;height:16px;cursor:pointer;">
              <span style="font-size:.78rem;font-weight:700;color:#475569;">ALL TEST CASES</span>
            </label>
            <span id="selCount" class="badge" style="background:#e0f2fe;color:#0369a1;border:1px solid #bae6fd;font-size:.72rem;font-weight:700;padding:3px 10px;border-radius:10px !important;white-space:nowrap;">0 SELECTED</span>
          </div>
        </div>

        <div style="display:flex;">
          <button id="bulkRunBtn" class="btn btn-primary btn-bulk-action" style="margin-right: 1rem;">
          Run Cycle
          </button>
          <button id="bulkEditBtn" class="btn btn-primary btn-bulk-action" style="margin-right: 1rem;">
          Bulk Update
          </button>
          <button id="qfg-add-case-btn" class="btn btn-primary btn-bulk-action">
          &#43;ADD NEW TEST CASE
          </button>

        </div>
      </div>`;
    // 5-level: use multi-plan structure if available
    if (ctx.schema === "5_level" && ctx.plans && ctx.plans.length) {
      let globalCaseIdx = 0;
      ctx.plans.forEach((plan, pi) => {
        html += planHeaderHTML(plan, pi);
        plan.suitesWithCases.forEach((suite, si) => {
          html += suiteHeaderHTML(suite, si);
          (suite.cases || []).forEach((c, ci) => {
            html += caseCardHTML(c, globalCaseIdx++, ctx);
          });
        });
      });
      return html;
    }
    // 4-level: standalone suites
    if (ctx.schema === "4_level" && ctx.suites && ctx.suites.length) {
      const perSuite = Math.ceil(cases.length / ctx.suites.length);
      ctx.suites.forEach((suite, si) => {
        const batchStart = si * perSuite;
        const batch = cases.slice(batchStart, batchStart + perSuite);
        html += suiteHeaderHTML(suite, si);
        batch.forEach((c, bi) => {
          html += caseCardHTML(c, batchStart + bi, ctx);
        });
      });
      return html;
    }
    // 3-level: flat list
    return html + cases.map((c, i) => caseCardHTML(c, i, ctx)).join("");
  }

  function planHeaderHTML(plan, pi) {
    return `
    <div class="qfg-group-header plan-header" data-planidx="${pi}">
      <span class="qfg-group-icon">&#128204;</span>
      <span class="qfg-group-label">Plan: <strong>${esc(plan.planName || plan.name || "Plan")}</strong></span>
      <div class="qfg-group-actions">
        <button class="qfg-action-btn edit-plan-results-btn" data-planidx="${pi}">&#9998; Edit Plan</button>
        <button class="qfg-action-btn del delete-plan-results-btn" data-planidx="${pi}">&#128465; Delete Plan</button>
      </div>
    </div>`;
  }

  function suiteHeaderHTML(suite, si) {
    return `
    <div class="qfg-group-header suite-header" data-suiteidx="${si}">
      <span class="qfg-group-icon">&#128203;</span>
      <span class="qfg-group-label">Suite: <strong>${esc(suite.name || "Suite")}</strong></span>
      <div class="qfg-group-actions">
        <button class="qfg-action-btn add-case-to-suite-btn" data-suiteidx="${si}">+ Add Case</button>
        <button class="qfg-action-btn edit-suite-results-btn" data-suiteidx="${si}">&#9998; Edit Suite</button>
        <button class="qfg-action-btn del delete-suite-results-btn" data-suiteidx="${si}">&#128465; Delete Suite</button>
      </div>
    </div>`;
  }

  function caseCardHTML(c, i, ctx) {
    const tcId = ctx.reqId + "-TC-" + String(i + 1).padStart(4, "0");
    const priCls = priClass(c.priority);
    const checkList = (val) =>
      toArr(val)
        .map(
          (s) => `<div class="qfg-check-item">&#9989; ${esc(String(s))}</div>`,
        )
        .join("");
    const mOpts = memberOptions("-- Assignee --");

    const evHist =
      c.evidenceHistory && c.evidenceHistory.length > 0
        ? c.evidenceHistory[c.evidenceHistory.length - 1]
        : null;
    let displayAssignee = evHist ? evHist.assignee : c.assignee;

    return `
    <div class="qfg-case-card" data-idx="${i}">
      <div class="qfg-case-head">
        <input type="checkbox" class="tc-checkbox" data-idx="${i}"/>
        <button class="qfg-case-id tc-view-btn" data-idx="${i}" title="View test case details">${esc(c.testCaseId || `TC-${String(i + 1).padStart(2, "0")}`)}</button>
        <span class="qfg-case-title">${esc(c.title || "Untitled")}</span>
        <span class="qfg-case-pill ${priCls}">${esc(c.priority || "Medium")}</span>
        <span class="qfg-case-pill" style="background:#f1f5f9;color:#475569">${esc(c.scenarioType || c.scenario_type || "—")}</span>
        ${c.tags && c.tags.length > 0 ? `<span class="qfg-case-pill" style="background: #f3e8ff;color: #905fba;">&#127991; ${esc(Array.isArray(c.tags) ? c.tags.join(", ") : c.tags)}</span>` : ""}
        <span class="qfg-case-pill" style="background:#eff6ff;color:#677cc1;margin-left:auto;margin-right:1rem;">${esc(displayAssignee || "Unassigned")}</span>
        <div class="tc-actions">
          <button class="btn btn-sm btn-edit-action tc-edit-btn" data-idx="${i}">
          <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
          </button>
          <button class="btn btn-sm btn-delete-action tc-delete-btn" data-idx="${i}">
            <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
          </button>
        </div>
      </div>
    </div>`;
  }

  function attachEvidenceRow(ev) {
    const ctn = document.getElementById("ecEvidenceListContainer");
    if (!ctn) return;

    // Normalise date from either ISO (YYYY-MM-DD) or display (MM-DD-YYYY)
    const isoDate = ev.date || ev.cycleDate || "";
    let displayDate = "";
    let isoVal = "";
    if (isoDate) {
      const p = isoDate.split("-");
      if (p.length === 3) {
        if (p[0].length === 4) {
          // Already ISO YYYY-MM-DD
          isoVal = isoDate;
          displayDate = p[1] + "-" + p[2] + "-" + p[0];
        } else {
          // MM-DD-YYYY display format → convert to ISO
          isoVal = p[2] + "-" + p[0] + "-" + p[1];
          displayDate = isoDate;
        }
      }
    }

    const div = document.createElement("div");
    div.className = "ec-evidence-row";
    div.style.cssText = [
      "position:relative",
      "background:#f8fafc",
      "border:1px solid #e2e8f0",
      "border-radius:10px",
      "padding:12px 36px 12px 14px",
      "margin-bottom:10px",
    ].join(";");

    // ── 4-column grid: Cycle | Status | Date | Assignee ──────────────
    const grid = document.createElement("div");
    grid.style.cssText =
      "display:grid; grid-template-columns:110px 1fr 170px 1fr; gap:10px; align-items:end;";

    const mkLabel = (txt) => {
      const l = document.createElement("label");
      l.textContent = txt;
      l.style.cssText =
        "display:block; font-size:0.72rem; font-weight:700; color:#64748b; margin-bottom:3px; text-transform:uppercase; letter-spacing:0.05em;";
      return l;
    };

    const fieldStyle =
      "width:100%; padding:7px 9px; border:1.5px solid #e2e8f0; border-radius:7px; font-size:0.83rem; color:#1e293b; background:#fff; box-sizing:border-box;";

    // Cycle input
    const cWrap = document.createElement("div");
    cWrap.appendChild(mkLabel("Cycle"));
    const cInp = document.createElement("input");
    cInp.type = "text";
    cInp.className = "ec-ev-cycle";
    cInp.value = ev.cycle || "";
    cInp.placeholder = "e.g. 1.0";
    cInp.style.cssText = fieldStyle;
    cWrap.appendChild(cInp);

    // Status select
    const sWrap = document.createElement("div");
    sWrap.appendChild(mkLabel("Status"));
    const sSel = document.createElement("select");
    sSel.className = "ec-ev-status";
    sSel.style.cssText = fieldStyle + " cursor:pointer;";
    const val = ev.status || "To-do";
    let statusHtml = _statuses
      .map((s) => `<option value="${esc(s)}">${esc(s)}</option>`)
      .join("");
    if (!_statuses.includes(val)) {
      statusHtml =
        `<option value="${esc(val)}">${esc(val)}</option>` + statusHtml;
    }
    sSel.innerHTML = statusHtml;
    sSel.value = val;
    sWrap.appendChild(sSel);

    // Date field – text input, Pikaday attached after DOM insert
    const dWrap = document.createElement("div");
    dWrap.appendChild(mkLabel("📅 Date"));
    const dTextInp = document.createElement("input");
    dTextInp.type = "text";
    dTextInp.value = displayDate;
    dTextInp.placeholder = "MM-DD-YYYY";
    dTextInp.style.cssText =
      fieldStyle + " cursor:pointer; padding-right:28px;";
    // Hidden ISO holder (read by save handler via .ec-ev-date)
    const dInp = document.createElement("input");
    dInp.type = "hidden";
    dInp.className = "ec-ev-date";
    dInp.value = isoVal;
    dWrap.appendChild(dTextInp);
    dWrap.appendChild(dInp);

    // Assignee select
    const aWrap = document.createElement("div");
    aWrap.appendChild(mkLabel("Assignee"));
    const aSel = document.createElement("select");
    aSel.className = "ec-ev-assignee";
    aSel.style.cssText = fieldStyle + " cursor:pointer;";
    aSel.innerHTML = memberOptions("-- Assignee --");
    aSel.value = ev.assignee || "";
    aWrap.appendChild(aSel);

    grid.appendChild(cWrap);
    grid.appendChild(sWrap);
    grid.appendChild(dWrap);
    grid.appendChild(aWrap);

    // Remove button
    const xBtn = document.createElement("button");
    xBtn.innerHTML = "&#10005;";
    xBtn.title = "Remove row";
    xBtn.style.cssText =
      "position:absolute; top:10px; right:10px; color:#ef4444; cursor:pointer; font-size:0.9rem; line-height:1; background:none; border:none; font-weight:700;";
    xBtn.onclick = () => div.remove();

    div.appendChild(grid);
    div.appendChild(xBtn);
    ctn.appendChild(div);

    // Attach Pikaday to evidence date field after it's in the DOM
    qfDatePicker(dTextInp, dInp, isoVal || undefined);
  }

  // ── Modal HTML ───────────────────────────────────────────────────
  function editCaseModalHTML(mOpts) {
    return `
    <div class="qfg-modal-overlay" id="editCaseModal" style="display:none">
      <div class="qfg-modal" style="width:min(680px,96vw)">
        <div class="qfg-modal-header">
          <span id="editCaseModalTitle">&#9998; Edit Test Case</span>
          <button class="qfg-modal-close" id="editCaseModalClose">&#10005;</button>
        </div>
        <div class="qfg-modal-body" style="padding: 1.5rem; max-height: 70vh; overflow-y: auto;">
          
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
              <div class="qfg-field">
                  <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">ID (@id) <span style="color:#ef4444">*</span></label>
                  <input type="text" id="ecId" placeholder="e.g. TC-BIM-0001" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 4px; background: #f8fafc;" />
              </div>
              <div class="qfg-field">
                  <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Requirement ID <span style="color:#ef4444">*</span></label>
                  <input type="text" id="ecReqId" placeholder="e.g. INDS-001" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 4px; background: #f8fafc;" />
              </div>
          </div>
          <div class="qfg-field" style="margin-bottom: 1rem;">
              <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Title <span style="color:#ef4444">*</span></label>
              <input type="text" id="ecTitle" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 4px;" />
          </div>

          <div class="qfg-field" style="margin-bottom: 1rem;">
              <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Description</label>
              <textarea id="ecDescription" rows="3" placeholder="" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px; resize:vertical; font-family: inherit; font-size:0.85rem; color: #1e293b;"></textarea>
          </div>

          <div class="qfg-field" style="margin-bottom: 1rem;">
              <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Pre-conditions <span style="font-size:0.75rem;color:#94a3b8">(one per line)</span></label>
              <textarea id="ecPreConditions" rows="3" placeholder="e.g. User is logged in" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px; resize:vertical; font-family: inherit; font-size:0.85rem; color: #1e293b;"></textarea>
          </div>
          <div class="qfg-field" style="margin-bottom: 1rem;">
                        <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Requirements </label>
                    <button type="button" id="ecAiRefineBtn" class="qfg-refine-btn btn btn-primary suite-refine-btn" style="float:right">✨ AI Refine</button>
                        <textarea id="ecReqDetails" rows="3" placeholder="e.g. User is logged in" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px; resize:vertical; font-family: inherit; font-size:0.85rem; color: #1e293b;"></textarea>
                    </div>
          <div class="qfg-field" style="margin-bottom: 1rem;">
              <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Steps</label>
              <textarea id="ecSteps" rows="5" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px; resize:vertical; font-family: inherit; font-size: 0.85rem; color: #1e293b;"></textarea>
          </div>
          <div class="qfg-field" style="margin-bottom: 1rem;">
              <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Expected Result</label>
              <textarea id="ecExpected" rows="3" style="width: 100%; padding: 8px; border: 1px solid #cbd5e1; border-radius: 6px; resize:vertical; font-family: inherit; font-size: 0.85rem; color: #1e293b;"></textarea>
          </div>
          
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
              <div class="qfg-field">
                  <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Scenario Type</label>
                  <div style="display: flex; gap: 0.5rem;">
                      <input type="text" id="ecScenarioVal" placeholder="Happy Path" style="flex: 1; padding: 6px 8px; border: 1px solid #cbd5e1; border-radius: 4px; font-size:0.85rem;" />
                      <select id="ecScenarioSelect" style="width: auto; padding: 6px; border: 1px solid #cbd5e1; border-radius: 4px; background: white; font-size:0.85rem;" onchange="if(this.value)document.getElementById('ecScenarioVal').value=this.value">
                          <option value="">Select</option>
                          <option value="Happy Path">Happy Path</option>
                          <option value="Negative">Negative</option>
                          <option value="Edge Case">Edge Case</option>
                          <option value="Boundary">Boundary</option>
                      </select>
                  </div>
              </div>
              <div class="qfg-field">
                  <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Execution Type</label>
                  <div style="display: flex; gap: 0.5rem;">
                      <input type="text" id="ecExecutionVal" placeholder="Manual" style="flex: 1; padding: 6px 8px; border: 1px solid #cbd5e1; border-radius: 4px; font-size:0.85rem;" />
                      <select id="ecExecutionSelect" style="width: auto; padding: 6px; border: 1px solid #cbd5e1; border-radius: 4px; background: white; font-size:0.85rem;" onchange="if(this.value)document.getElementById('ecExecutionVal').value=this.value">
                          <option value="">Select</option>
                          <option value="Manual">Manual</option>
                          <option value="Automated">Automated</option>
                      </select>
                  </div>
              </div>
          </div>

          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;">
              <div class="qfg-field">
                  <label style="font-size: 0.8rem; color: #475569; display: block; margin-bottom: 4px;">Priority</label>
                  <select id="ecPriority" style="width: 100%; padding: 6px; border: 1px solid #cbd5e1; border-radius: 4px; background: white; font-size: 0.85rem;">
                      <option>High</option><option>Medium</option><option>Low</option>
                  </select>
              </div>
              <div class="qfg-field">
                  <label style="font-size: 0.8rem; color: #1d8397; display: block; margin-bottom: 4px;">Tags (comma separated)</label>
                  <div style="display: flex; gap: 0.5rem;">
                      <input type="text" id="ecTags" style="flex: 1; padding: 6px 8px; border: 1px solid #cbd5e1; border-radius: 4px; font-size:0.85rem;" />
                      <select id="ecTagsSelect" style="width: auto; padding: 6px; border: 1px solid #cbd5e1; border-radius: 4px; background: white; font-size:0.85rem;" onchange="if(this.value){let el=document.getElementById('ecTags');el.value=el.value?el.value+', '+this.value:this.value;this.value=''}">
                          <option value="">+ Add Tag</option>
                          <option value="Regression">Regression</option>
                          <option value="Smoke">Smoke</option>
                      </select>
                  </div>
              </div>
          </div>
          
          <div style="border-top: 1px solid #e2e8f0; margin-top: 1.5rem; padding-top: 1rem; margin-bottom: 1.5rem;">
              <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                  <h4 style="margin: 0; font-size: 1rem; color: #0f172a;">Evidence History</h4>
                  <button type="button" id="ecAddEvidenceRow" style="background:#eff6ff; color:#1e40af; border:1px solid #bfdbfe; border-radius:999px; padding:4px 12px; font-size:0.75rem; font-weight:600; cursor:pointer;">+ Add Evidence</button>
              </div>
              <div id="ecEvidenceListContainer" style="display:flex; flex-direction:column; gap:12px;"></div>
          </div>



        </div>
        <div class="qfg-modal-footer" style="padding: 1rem 1.5rem; background: #f8fafc; border-top: 1px solid #e2e8f0; display:flex; justify-content:flex-end; gap:0.5rem; border-radius: 0 0 8px 8px;">
          <button class="btn btn-secondary qfg-btn-reset" id="editCaseModalCancel" style="padding: 8px 16px; border-radius: 6px;">Cancel</button>
          <button class="btn btn-primary qfg-btn-generate" id="editCaseModalSave" style="padding: 8px 16px; border-radius: 6px;"><span id="editCaseModalSaveLabel">Save Changes</span></button>
        </div>
      </div>
    </div>`;
  }

  // ── View (Detail) Modal HTML ─────────────────────────────────────
  function viewCaseModalHTML() {
    return `
    <div class="qfg-modal-overlay" id="viewCaseModal" style="display:none">
      <div class="qfg-modal" style="width:min(720px,96vw);max-height:92vh;display:flex;flex-direction:column;">
        <!-- Header -->
        <div class="qfg-modal-header" style="display:flex;align-items:center;gap:12px;flex-shrink:0;">
          <span id="vcModalTcId" style="font-size:.78rem;font-weight:800;padding:3px 10px;border-radius:6px;background:#e0f2fe;color:#0369a1;letter-spacing:.03em;"></span>
          <span id="vcModalTitle" style="font-size:.95rem;font-weight:700;color:#0f172a;flex:1;line-height:1.4;"></span>
          <button class="qfg-modal-close" id="viewCaseModalClose">&#10005;</button>
        </div>
        <!-- Meta ribbon -->
        <div id="vcMetaRibbon" style="display:flex;flex-wrap:wrap;gap:8px;padding:10px 20px;background:#f8fafc;border-bottom:1px solid #e2e8f0;flex-shrink:0;"></div>
        <!-- Body -->
        <div style="overflow-y:auto;flex:1;padding:20px 24px;display:flex;flex-direction:column;gap:18px;">
          <!-- Description -->
          <div id="vcDescBlock" style="display:none">
            <div class="vc-section-label">📋 Description</div>
            <div id="vcDescription" class="vc-prose"></div>
          </div>
          <!-- Pre-conditions -->
          <div id="vcPreBlock" style="display:none">
            <div class="vc-section-label">⚙️ Pre-conditions</div>
            <ol id="vcPreConditions" class="vc-list"></ol>
          </div>
          <!-- Steps -->
          <div id="vcStepsBlock" style="display:none">
            <div class="vc-section-label">🪜 Steps</div>
            <ol id="vcSteps" class="vc-list vc-steps-list"></ol>
          </div>
          <!-- Expected Result -->
          <div id="vcExpBlock" style="display:none">
            <div class="vc-section-label">✅ Expected Result</div>
            <ol id="vcExpected" class="vc-list"></ol>
          </div>
          <!-- Evidence History -->
          <div id="vcEvBlock" style="display:none">
            <div class="vc-section-label">📎 Evidence History</div>
            <div id="vcEvidenceList" style="display:flex;flex-direction:column;gap:8px;"></div>
          </div>
        </div>
        <!-- Footer -->
        <div class="qfg-modal-footer" style="padding:12px 20px;background:#f8fafc;border-top:1px solid #e2e8f0;display:flex;justify-content:flex-end;gap:8px;flex-shrink:0;">
          <button class="btn btn-secondary qfg-btn-reset" id="viewCaseModalEdit" style="padding:8px 16px;border-radius:6px;">✏️ Edit</button>
          <button class="btn btn-primary qfg-btn-reset" id="viewCaseModalClose2" style="padding:8px 16px;border-radius:6px;">Close</button>
        </div>
      </div>
    </div>
    <style>
      .vc-section-label{font-size:.72rem;font-weight:800;color:#64748b;text-transform:uppercase;letter-spacing:.06em;margin-bottom:8px;padding-bottom:5px;border-bottom:1.5px solid #e2e8f0;}
      .vc-prose{font-size:.875rem;color:#334155;line-height:1.7;white-space:pre-wrap;}
      .vc-list{margin:0;padding-left:20px;display:flex;flex-direction:column;gap:6px;}
      .vc-list li{font-size:.875rem;color:#334155;line-height:1.6;padding:4px 0;}
      .vc-steps-list li{background:#f8fafc;border-left:3px solid #0ea5e9;border-radius:0 6px 6px 0;padding:7px 12px;list-style:decimal;margin-left:4px;}
      .vc-meta-pill{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:999px;font-size:.75rem;font-weight:700;}
      .vc-ev-row{display:flex;flex-wrap:wrap;gap:8px;align-items:center;padding:9px 14px;border-radius:8px;border-left:3px solid #94a3b8;background:#f8fafc;}
      .qfg-case-id.tc-view-btn{background:none;border:none;cursor:pointer;font-weight:800;font-size:.72rem;padding:2px 8px;border-radius:5px;background:#e0f2fe;color:#0369a1;letter-spacing:.04em;transition:background .15s;}
      .qfg-case-id.tc-view-btn:hover{background:#bae6fd;text-decoration:underline;}
    </style>`;
  }

  function editSuiteModalHTML() {
    return `
    <div class="qfg-modal-overlay" id="editSuiteModal" style="display:none">
      <div class="qfg-modal" style="width:min(480px,96vw)">
        <div class="qfg-modal-header">
          <span>&#9998; Edit Suite</span>
          <button class="qfg-modal-close" id="editSuiteModalClose">&#10005;</button>
        </div>
        <div class="qfg-modal-grid">
          <div class="qfg-field"><label>Suite Name</label><input type="text" id="esSuiteName"/></div>
          <div class="qfg-field"><label>Suite ID</label><input type="text" id="esSuiteId"/></div>
          <div class="qfg-field"><label>Suite Date</label>
            <div style="position:relative; width:100%;">
              <input type="text" id="esSuiteDateText" style="width:100%; border:1px solid #cbd5e1; border-radius:4px; padding:6px 8px; font-size:0.85rem; background:#fff; cursor:pointer;" placeholder="MM-DD-YYYY" />
              <input type="hidden" id="esSuiteDate" />
            </div>
          </div>
          <div class="qfg-field"><label>Created By</label>
            <select id="esSuiteCreator">${memberOptions()}</select>
          </div>
        </div>
        <div class="qfg-modal-footer">
          <button class="btn btn-secondary qfg-btn-reset"    id="editSuiteModalCancel">Cancel</button>
          <button class="btn btn-primary qfg-btn-generate" id="editSuiteModalSave">Save Suite</button>
        </div>
      </div>
    </div>`;
  }

  function editPlanModalHTML() {
    return `
    <div class="qfg-modal-overlay" id="editPlanModal" style="display:none">
      <div class="qfg-modal" style="width:min(420px,96vw)">
        <div class="qfg-modal-header">
          <span>&#9998; Edit Plan</span>
          <button class="qfg-modal-close" id="editPlanModalClose">&#10005;</button>
        </div>
        <div class="qfg-modal-grid">
          <div class="qfg-field"><label>Plan Name</label><input type="text" id="epPlanName"/></div>
          <div class="qfg-field"><label>Plan ID</label><input type="text" id="epPlanId"/></div>
          <div class="qfg-field"><label>Plan Date</label>
            <div style="position:relative; width:100%;">
              <input type="text" id="epPlanDateText" style="width:100%; border:1px solid #cbd5e1; border-radius:4px; padding:6px 8px; font-size:0.85rem; background:#fff; cursor:pointer;" placeholder="MM-DD-YYYY" />
              <input type="hidden" id="epPlanDate" />
            </div>
          </div>
          <div class="qfg-field"><label>Created By</label>
            <select id="epPlanCreator">${memberOptions()}</select>
          </div>
        </div>
        <div class="qfg-modal-footer">
          <button class="btn btn-secondary qfg-btn-reset"    id="editPlanModalCancel">Cancel</button>
          <button class="btn btn-primary qfg-btn-generate" id="editPlanModalSave">Save Plan</button>
        </div>
      </div>
    </div>
    <!-- Bulk Edit Modal -->
    <div class="qfg-modal-overlay" id="bulkEditModal" style="display:none">
      <div class="qfg-modal">
        <div class="qfg-modal-header">
          <span>Bulk Edit Selected Cases</span>
          <button class="qfg-modal-close" id="bulkEditModalClose">&#10005;</button>
        </div>
        <p class="qfg-modal-hint">Changes will be applied to all selected test cases. Leave fields empty to keep existing values.</p>
        <div class="qfg-modal-grid">
          <div class="qfg-field"><label>Assignee</label>
            <select id="modalAssignee">${memberOptions("-- No Change --")}</select></div>
          <div class="qfg-field"><label>Priority</label>
            <select id="modalPriority">
              <option value="">-- No Change --</option>
              <option>High</option><option>Medium</option><option>Low</option>
            </select></div>
          <div class="qfg-field"><label>Scenario Type</label>
            <select id="modalScenarioType">
              <option value="">-- No Change --</option>
              <option>Happy Path</option><option>Negative</option><option>Edge Case</option><option>Boundary</option>
            </select></div>
          <div class="qfg-field"><label>Execution Type</label>
            <select id="modalExecutionType">
              <option value="">-- No Change --</option>
              <option>Manual</option><option>Automated</option>
            </select></div>
        </div>
        <div class="qfg-field" style="margin-top:12px">
          <label>Add Tags (comma separated)</label>
          <input type="text" id="modalTags" placeholder="e.g. Functional, Login"/>
          <div style="color:#1d8397;font-size:.72rem;margin-top:4px">New tags will be appended to existing ones.</div>
        </div>
        <div class="qfg-modal-footer">
          <button class="btn btn-secondary qfg-btn-reset"    id="bulkEditModalCancel">Cancel</button>
          <button class="btn btn-primary qfg-btn-generate" id="bulkEditModalApply">Apply Changes</button>
        </div>
      </div>
    </div>
    <!-- Bulk Run Modal -->
    <div class="qfg-modal-overlay" id="bulkRunModal" style="display:none">
      <div class="qfg-modal" style="width:min(520px,96vw)">
        <div class="qfg-modal-header">
          <span>&#9654; Run Cycle — Selected Cases</span>
          <button class="qfg-modal-close" id="bulkRunModalClose">&#10005;</button>
        </div>
        <p class="qfg-modal-hint">A new run entry will be added to all selected test cases using the config below.</p>
        <div class="qfg-modal-grid">
          <div class="qfg-field">
            <label>Cycle <span style="color:#ef4444">*</span></label>
            <input type="text" id="modalRunCycle" placeholder="e.g. 1.0" />
          </div>
          <div class="qfg-field">
            <label>&#128197; Date</label>
            <div style="position:relative;display:flex;align-items:center;">
              <input type="text" id="modalRunCycleDateText" placeholder="MM-DD-YYYY"
                style="width:100%;cursor:pointer;padding-right:28px;" />
              <input type="hidden" id="modalRunCycleDate" />
              <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:.85rem;"></i>
            </div>
          </div>
          <div class="qfg-field">
            <label>Run Assignee</label>
            <select id="modalRunAssignee">${memberOptions("-- Assignee --")}</select>
          </div>
          <div class="qfg-field">
            <label>Status</label>
            <select id="modalRunStatus">
              <option value="To-do">To-do</option>
              <option value="In Progress">In Progress</option>
              <option value="Passed">Passed</option>
              <option value="Failed">Failed</option>
              <option value="Blocked">Blocked</option>
              <option value="Skipped">Skipped</option>
              <option value="Pending">Pending</option>
            </select>
          </div>
        </div>
        <div class="qfg-modal-footer">
          <button class="qfg-btn-reset"    id="bulkRunModalCancel">Cancel</button>
          <button class="qfg-btn-generate" id="bulkRunModalApply">&#9654; Add Run</button>
        </div>
      </div>
    </div>`;
  }

  /**
 * Enhanced save function that uses the server-fetched destination
 * This should replace or update your existing save function
 */
  async function saveMarkdownToServer(filename, content) {
    try {
      // Ensure we have a destination (should be set by initializeMarkdownDestination)
      if (!_markdownDest) {
        throw new Error('Markdown destination not set. Please check Settings → Markdown Paths.');
      }

      const formData = new FormData();
      formData.append('filename', filename);
      formData.append('content', content);

      const response = await fetch('/pages/save_markdown.sql', {
        method: 'POST',
        body: formData
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: Could not save markdown`);
      }

      const result = await response.json();

      if (result.success) {
        console.log('✓ Markdown saved successfully');
        console.log('Location:', result.folder + '/' + result.filename);
        return {
          success: true,
          folder: result.folder,
          filename: result.filename,
          message: 'Markdown file saved successfully to: ' + result.folder
        };
      } else {
        throw new Error(result.message || 'Unknown error saving markdown');
      }
    } catch (error) {
      console.error('Error saving markdown:', error);
      return {
        success: false,
        error: error.message,
        hint: 'Check that markdown destination is set in Settings → Markdown Paths'
      };
    }
  }

  /**
   * Display markdown destination in UI (optional)
   * Shows user where files are being saved
   */
  function displayMarkdownDestination() {
    const element = document.getElementById('markdown-destination-display');
    if (element) {
      element.textContent = _markdownDest;
      element.title = 'Current markdown destination folder';
    }
  }


  // ── Wire all events ──────────────────────────────────────────────
  function wireEvents(cases, ctx) {
    const selectedIdx = () =>
      Array.from(document.querySelectorAll(".tc-checkbox:checked")).map((c) =>
        parseInt(c.dataset.idx),
      );

    // ── Tab switcher ─────────────────────────────────────────────────
    const tabs = ["preview", "hierarchy", "markdown", "json"];
    document.querySelectorAll(".qfg-tab-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        const target = btn.dataset.tab;

        // Toggle active state on buttons
        document
          .querySelectorAll(".qfg-tab-btn")
          .forEach((b) => b.classList.remove("qfg-tab-active"));
        btn.classList.add("qfg-tab-active");

        // Show/hide panels
        tabs.forEach((t) => {
          const panel = document.getElementById("qfg-tab-" + t);
          if (panel) panel.style.display = t === target ? "" : "none";
        });

        // Rebuild Hierarchy panel fresh on each tab click (keeps state in sync)
        if (target === "hierarchy") {
          const hp = document.getElementById("qfg-hierarchy-panel");
          if (hp) {
            hp.innerHTML = buildHierarchyTree(cases, ctx);
            // Single delegated listener on the panel — handles toggle + actions
            hp.addEventListener("click", (e) => {
              // Collapse / expand toggle
              const hdr = e.target.closest(".qfg-tree-header");
              if (hdr && !e.target.closest(".qfg-tree-act")) {
                hdr.parentElement.classList.toggle("open");
                return;
              }
              // Action buttons
              const btn = e.target.closest(".qfg-tree-act");
              if (!btn) return;
              const action = btn.dataset.action;
              const idx = parseInt(btn.dataset.idx);
              const si =
                btn.dataset.si !== undefined
                  ? parseInt(btn.dataset.si)
                  : undefined;
              if (action === "edit-tc") openEditCaseModal(idx);
              if (action === "del-tc") {
                if (confirm(`Delete "${_cases[idx]?.title || "this case"}"?`)) {
                  _cases.splice(idx, 1);
                  renderResults(_cases, _ctx);
                }
              }
              if (action === "edit-suite") openEditSuiteModal(si);
              if (action === "del-suite") {
                const sname = _ctx.suites[si]?.name || "this suite";
                if (confirm(`Delete suite "${sname}" and all its cases?`)) {
                  const perSuite = Math.ceil(
                    _cases.length / _ctx.suites.length,
                  );
                  _cases.splice(si * perSuite, perSuite);
                  _ctx.suites.splice(si, 1);
                  renderResults(_cases, _ctx);
                }
              }
              if (action === "edit-plan") openEditPlanModal();
            });
          }
        }

        // Lazily build Markdown panel (editable textarea)
        if (target === "markdown") {
          const mp = document.getElementById("qfg-md-panel");
          if (mp && !mp.dataset.loaded) {
            mp.value = buildMarkdown(cases, ctx);
            mp.dataset.loaded = "1";
          }
          // Wire markdown toolbar buttons
          const copyBtn = document.getElementById("qfg-md-copy-btn");
          if (copyBtn && !copyBtn.dataset.wired) {
            copyBtn.dataset.wired = "1";
            copyBtn.addEventListener("click", () => {
              const mp2 = document.getElementById("qfg-md-panel");
              if (!mp2) return;
              navigator.clipboard
                .writeText(mp2.value)
                .then(() => {
                  copyBtn.textContent = "\u2705 Copied!";
                  setTimeout(() => {
                    copyBtn.textContent = "\ud83d\udccb Copy";
                  }, 1800);
                })
                .catch(() => {
                  mp2.select();
                  document.execCommand("copy");
                  copyBtn.textContent = "\u2705 Copied!";
                  setTimeout(() => {
                    copyBtn.textContent = "\ud83d\udccb Copy";
                  }, 1800);
                });
            });
          }
          const fmtBtn = document.getElementById("qfg-md-format-btn");
          if (fmtBtn && !fmtBtn.dataset.wired) {
            fmtBtn.dataset.wired = "1";
            fmtBtn.addEventListener("click", () => {
              const mp2 = document.getElementById("qfg-md-panel");
              if (mp2) {
                mp2.value = buildMarkdown(_cases, _ctx);
                mp2.dataset.loaded = "1";
              }
            });
          }
          const dlBtn = document.getElementById("qfg-md-dl-btn");
          if (dlBtn && !dlBtn.dataset.wired) {
            dlBtn.dataset.wired = "1";
            dlBtn.addEventListener("click", async () => {
              const mp2 = document.getElementById("qfg-md-panel");
              if (!mp2) return;
              const fname =
                (_ctx.project || "testcases").replace(/\s+/g, "_") +
                "_" +
                (_ctx.reqId || "REQ") +
                ".md";
              await saveMarkdownToServer(fname, mp2.value);
            });
          }
        }

        // Lazily build JSON panel
        if (target === "json") {
          const jp = document.getElementById("qfg-json-panel");
          if (jp)
            jp.textContent = JSON.stringify({ context: ctx, cases }, null, 2);
        }
      });
    });

    const updateCount = () => {
      const n = document.querySelectorAll(".tc-checkbox:checked").length;
      const el = document.getElementById("selCount");
      if (el) el.textContent = n + " SELECTED";
    };

    // Select all
    on("selectAllTcs", "change", function () {
      document.querySelectorAll(".tc-checkbox").forEach((cb) => {
        cb.checked = this.checked;
      });
      updateCount();
    });

    // Card list delegation
    const cardList = document.getElementById("qfg-cards-list");
    if (cardList) {
      cardList.addEventListener("change", (e) => {
        if (e.target.classList.contains("tc-checkbox")) {
          updateCount();
          const sa = document.getElementById("selectAllTcs");
          const all = document.querySelectorAll(".tc-checkbox");
          const chk = document.querySelectorAll(".tc-checkbox:checked");
          if (sa) sa.checked = all.length === chk.length;
        }
        if (e.target.classList.contains("tc-priority-select")) {
          const i = parseInt(e.target.dataset.idx);
          _cases[i].priority = e.target.value;
          renderResults(_cases, _ctx);
        }
        if (e.target.classList.contains("tc-assignee-select")) {
          const i = parseInt(e.target.dataset.idx);
          _cases[i].assignee = e.target.value;
        }
      });

      // Per-card Edit/Delete (including plan-level for 5-level)
      cardList.addEventListener("click", (e) => {
        const viewBtn = e.target.closest(".tc-view-btn");
        const editBtn = e.target.closest(".tc-edit-btn");
        const delBtn = e.target.closest(".tc-delete-btn");
        const suiteEditBtn = e.target.closest(".edit-suite-results-btn");
        const suiteDelBtn = e.target.closest(".delete-suite-results-btn");
        const addCaseBtn = e.target.closest(".add-case-to-suite-btn");
        const planEditBtn = e.target.closest(".edit-plan-results-btn");
        const planDelBtn = e.target.closest(".delete-plan-results-btn");

        if (viewBtn) openViewCaseModal(parseInt(viewBtn.dataset.idx));
        if (editBtn) openEditCaseModal(parseInt(editBtn.dataset.idx));
        if (delBtn) {
          const i = parseInt(delBtn.dataset.idx);
          if (confirm(`Delete "${_cases[i]?.title || "this test case"}"?`)) {
            _cases.splice(i, 1);
            renderResults(_cases, _ctx);
          }
        }
        if (suiteEditBtn)
          openEditSuiteModal(parseInt(suiteEditBtn.dataset.suiteidx));
        if (suiteDelBtn) {
          const si = parseInt(suiteDelBtn.dataset.suiteidx);
          if (_ctx.schema === "5_level" && _ctx.plans) {
            // Find and remove suite from correct plan
            const pi = parseInt(
              suiteDelBtn.closest("[data-planidx]")?.dataset.planidx || 0,
            );
            const plan = _ctx.plans[pi];
            if (plan) {
              const sname = plan.suitesWithCases[si]?.name || "this suite";
              if (confirm(`Delete suite "${sname}" and all its cases?`)) {
                // Remove cases belonging to this suite from allCases
                const suiteCases = plan.suitesWithCases[si]?.cases || [];
                suiteCases.forEach((sc) => {
                  const idx = _cases.indexOf(sc);
                  if (idx !== -1) _cases.splice(idx, 1);
                });
                plan.suitesWithCases.splice(si, 1);
                renderResults(_cases, _ctx);
              }
            }
          } else {
            const sname = _ctx.suites[si]?.name || "this suite";
            if (confirm(`Delete suite "${sname}" and all its cases?`)) {
              const perSuite = Math.ceil(_cases.length / _ctx.suites.length);
              _cases.splice(si * perSuite, perSuite);
              _ctx.suites.splice(si, 1);
              renderResults(_cases, _ctx);
            }
          }
        }
        if (addCaseBtn) {
          const si = parseInt(addCaseBtn.dataset.suiteidx);
          const pb = addCaseBtn.closest("[data-planidx]");
          const pi = pb ? parseInt(pb.dataset.planidx) : -1;
          addBlankCase(si, pi);
        }

        // Multi-plan edit/delete (5-level)
        if (planEditBtn) {
          const pi = parseInt(planEditBtn.dataset.planidx || 0);
          openEditPlanModal(pi);
        }
        if (planDelBtn) {
          const pi = parseInt(planDelBtn.dataset.planidx || 0);
          const plan = _ctx.plans && _ctx.plans[pi];
          const pname = plan?.planName || "this plan";
          if (confirm(`Delete plan "${pname}" and all its suites/cases?`)) {
            // Remove all cases of this plan
            if (plan) {
              plan.suitesWithCases.forEach((suite) => {
                (suite.cases || []).forEach((sc) => {
                  const idx = _cases.indexOf(sc);
                  if (idx !== -1) _cases.splice(idx, 1);
                });
              });
              _ctx.plans.splice(pi, 1);
            }
            renderResults(_cases, _ctx);
          }
        }
      });
    }

    // Global Add Case
    on("qfg-add-case-btn", "click", () => {
      // For 3-level or if no suite/plan selected, just add at end
      addBlankCase(-1, -1);
    });

    // Project edit
    on("editProjectBtn", "click", () => {
      const name = prompt("Edit project name:", _ctx.project);
      if (name && name.trim()) {
        _ctx.project = name.trim();
        renderResults(_cases, _ctx);
      }
    });

    // Unified Bulk Update + Properties
    on("applyBulkActions", "click", () => {
      const ids = selectedIdx();
      if (!ids.length) {
        showModal("No Test Cases Selected", "Please select at least one test case before applying bulk updates.");
        return;
      }

      // Collect values from both sets of inputs
      const pri = document.getElementById("bulkPrioritySelect")?.value;
      const asgn = document.getElementById("bulkAssignSelect")?.value;
      const sc = document.getElementById("bulkScenarioTypeSelect")?.value;
      const ex = document.getElementById("bulkExecutionTypeSelect")?.value;
      const tags = document.getElementById("bulkTagsInput")?.value.trim();

      ids.forEach((i) => {
        // --- Bulk Actions ---
        if (pri) _cases[i].priority = pri;
        if (asgn) {
          _cases[i].assignee = asgn;
          if (!_cases[i].evidenceHistory) _cases[i].evidenceHistory = [];
          if (_cases[i].evidenceHistory.length > 0) {
            _cases[i].evidenceHistory[0].assignee = asgn;
          } else {
            _cases[i].evidenceHistory.push({
              cycle: "1.0",
              cycleDate: new Date().toISOString().split("T")[0],
              status: "To-do",
              assignee: asgn,
            });
          }
          if (_cases[i].evidenceHistory[0]) {
            _cases[i].run = _cases[i].evidenceHistory[0];
          }
        }

        // --- Bulk Properties ---
        if (sc) _cases[i].scenarioType = sc;
        if (ex) _cases[i].executionType = ex;
        if (tags) {
          const ex2 = Array.isArray(_cases[i].tags) ? _cases[i].tags : [];
          _cases[i].tags = [
            ...ex2,
            ...tags.split(",").map((t) => t.trim()).filter(Boolean),
          ];
        }
      });

      renderResults(_cases, _ctx);
    });


    // Run cycle
    on("applyBulkCycle", "click", () => {
      const ids = selectedIdx();
      const cycle =
        document.getElementById("bulkCycleName")?.value.trim() ||
        _ctx.cycle ||
        "1.0";
      const date =
        document.getElementById("bulkCycleDate")?.value || _ctx.cycleDate || "";
      const asgn =
        document.getElementById("bulkCycleAssignee")?.value ||
        _ctx.creator ||
        "";
      const status =
        document.getElementById("bulkCycleStatus")?.value || "To-do";

      if (!ids.length) {
        showModal("No Test Cases Selected", "Please select at least one test case before running.");
        return;
      }
      if (!cycle) {
        showModal("No Cycle Number Added", "Please enter a Cycle number.");
        return;
      }

      // ── Validate: check for duplicate cycle number in selected cases ──
      const duplicates = [];
      ids.forEach((i) => {
        const tc = _cases[i];
        if (
          Array.isArray(tc.evidenceHistory) &&
          tc.evidenceHistory.some((ev) => ev.cycle === cycle)
        ) {
          duplicates.push(tc.testCaseId || `TC-${i + 1}`);
        }
      });
      if (duplicates.length > 0) {
        showModal("Cycle Exists", `Cycle "${cycle}" already exists in: ${duplicates.join(", ")}.\nPlease use a different cycle number.`);
        return;
      }

      let okCount = 0;
      ids.forEach((i) => {
        let tc = _cases[i];
        if (!tc.evidenceHistory) tc.evidenceHistory = [];
        // Push new run with correct key "date" (not cycleDate)
        tc.evidenceHistory.push({
          cycle,
          date, // ← correct key used by attachEvidenceRow
          assignee: asgn,
          status,
        });
        tc.run = tc.evidenceHistory[tc.evidenceHistory.length - 1];
        okCount++;
      });
      if (okCount > 0)
        showModal("Duplicate Cycle Number", `Run cycle "${cycle}" added to ${okCount} case(s).`);
      renderResults(_cases, _ctx);
    });

    // Reset
    on("resetBulkActions", "click", () => {
      [
        "bulkAssignSelect",
        "bulkPrioritySelect",
        "bulkScenarioTypeSelect",
        "bulkExecutionTypeSelect",
        "bulkTagsInput",
        "bulkCycleAssignee",
        "bulkCycleStatus",
      ].forEach((id) => {
        const el = document.getElementById(id);
        if (el) el.value = "";
      });
    });

    // Download / Save to server
    on("bulkDownloadBtn", "click", async () => {
      const md = buildMarkdown(_cases, _ctx);
      const nm =
        (document.getElementById("bulkFilename")?.value.trim() ||
          _ctx.project.replace(/\s+/g, "_") + "_" + _ctx.reqId) + ".md";
      await saveMarkdownToServer(nm, md);
    });

    // Bulk edit modal
    on("bulkEditBtn", "click", () => {
      if (!selectedIdx().length) {
        showModal("No Test Cases Selected", `Select at least one test case first.`);
        return;
      }
      document.getElementById("bulkEditModal").style.display = "flex";
    });
    ["bulkEditModalClose", "bulkEditModalCancel"].forEach((id) =>
      on(id, "click", () => {
        document.getElementById("bulkEditModal").style.display = "none";
      }),
    );
    on("bulkEditModalApply", "click", () => {
      const ids = selectedIdx();
      const pri = document.getElementById("modalPriority")?.value;
      const sc = document.getElementById("modalScenarioType")?.value;
      const ex = document.getElementById("modalExecutionType")?.value;
      const asgn = document.getElementById("modalAssignee")?.value;
      const tgs = document.getElementById("modalTags")?.value.trim();
      ids.forEach((i) => {
        if (pri) _cases[i].priority = pri;
        if (sc) _cases[i].scenarioType = sc;
        if (ex) _cases[i].executionType = ex;
        if (asgn) _cases[i].assignee = asgn;
        if (tgs) {
          const e2 = Array.isArray(_cases[i].tags) ? _cases[i].tags : [];
          _cases[i].tags = [
            ...e2,
            ...tgs
              .split(",")
              .map((t) => t.trim())
              .filter(Boolean),
          ];
        }
      });
      document.getElementById("bulkEditModal").style.display = "none";
      renderResults(_cases, _ctx);
    });

    // Bulk run modal
    on("bulkRunBtn", "click", () => {
      if (!selectedIdx().length) {
        showModal("No Test Cases Selected", `Select at least one test case first.`);
        return;
      }
      // Pre-fill Cycle from toolbar value, Date from today
      const runCycleEl = document.getElementById("modalRunCycle");
      if (runCycleEl) runCycleEl.value = document.getElementById("bulkCycleName")?.value.trim() || _ctx.cycle || "1.0";
      const today = new Date().toISOString().slice(0, 10);
      qfDatePicker(
        document.getElementById("modalRunCycleDateText"),
        document.getElementById("modalRunCycleDate"),
        document.getElementById("bulkCycleDate")?.value || today,
      );
      const runAsgn = document.getElementById("modalRunAssignee");
      if (runAsgn) runAsgn.value = document.getElementById("bulkCycleAssignee")?.value || "";
      const runStatus = document.getElementById("modalRunStatus");
      if (runStatus) runStatus.value = document.getElementById("bulkCycleStatus")?.value || "To-do";
      document.getElementById("bulkRunModal").style.display = "flex";
    });
    ["bulkRunModalClose", "bulkRunModalCancel"].forEach((id) =>
      on(id, "click", () => {
        document.getElementById("bulkRunModal").style.display = "none";
      }),
    );
    on("bulkRunModalApply", "click", () => {
      const ids = selectedIdx();
      const cycle = document.getElementById("modalRunCycle")?.value.trim();
      const date = document.getElementById("modalRunCycleDate")?.value || new Date().toISOString().slice(0, 10);
      const asgn = document.getElementById("modalRunAssignee")?.value || _ctx.creator || "";
      const status = document.getElementById("modalRunStatus")?.value || "To-do";

      if (!ids.length) {
        showModal("No Test Cases Selected", "Please select at least one test case before running.");
        return;
      }
      if (!cycle) {
        showModal("No Cycle Number", "Please enter a Cycle number.");
        return;
      }

      // Validate: no duplicate cycle in selected cases
      const duplicates = [];
      ids.forEach((i) => {
        const tc = _cases[i];
        if (Array.isArray(tc.evidenceHistory) && tc.evidenceHistory.some((ev) => ev.cycle === cycle)) {
          duplicates.push(tc.testCaseId || `TC-${i + 1}`);
        }
      });
      if (duplicates.length > 0) {
        showModal("Cycle Exists", `Cycle "${cycle}" already exists in: ${duplicates.join(", ")}.\nPlease use a different cycle number.`);
        return;
      }

      let okCount = 0;
      ids.forEach((i) => {
        const tc = _cases[i];
        if (!tc.evidenceHistory) tc.evidenceHistory = [];
        tc.evidenceHistory.push({ cycle, date, assignee: asgn, status });
        tc.run = tc.evidenceHistory[tc.evidenceHistory.length - 1];
        okCount++;
      });
      document.getElementById("bulkRunModal").style.display = "none";
      if (okCount > 0) showModal("Run Added", `Run cycle "${cycle}" added to ${okCount} case(s).`);
      renderResults(_cases, _ctx);
    });

    // Click-outside for all overlays
    document.querySelectorAll(".qfg-modal-overlay").forEach((ov) => {
      ov.addEventListener("click", function (e) {
        if (e.target === this) this.style.display = "none";
      });
    });

    // Single case modal save
    on("editCaseModalSave", "click", () => {
      const mo = document.getElementById("editCaseModal");
      const iStr = mo.dataset.idx;
      const siStr = mo.dataset.si;
      const piStr = mo.dataset.pi;

      const get = (id) => document.getElementById(id)?.value || "";

      const idVal = get("ecId").trim();
      if (!idVal) {
        showModal("No Case ID", `Case ID is a mandatory field.`);
        return;
      }
      const reqIdVal = get("ecReqId").trim();
      if (!reqIdVal) {
        showModal("No Requirement ID", `Requirement ID is a mandatory field.`);
        return;
      }
      const titleVal = get("ecTitle").trim();
      if (!titleVal) {
        showModal("No Title", `Title is a mandatory field.`);
        return;
      }

      const seenCycles = new Set();
      const newEv = [];
      const evRows = document.querySelectorAll(
        "#ecEvidenceListContainer .ec-evidence-row",
      );
      for (const row of Array.from(evRows)) {
        const cycle = row.querySelector(".ec-ev-cycle")?.value.trim() || "";
        if (cycle) {
          if (seenCycles.has(cycle)) {
            showModal("Duplicate Cycle Number", `Duplicate Cycle Number "${cycle}" is not allowed. Please use unique cycle numbers for each evidence row.`);
            return;
          }
          seenCycles.add(cycle);
        }
        newEv.push({
          cycle,
          status: row.querySelector(".ec-ev-status")?.value || "Passed",
          date: row.querySelector(".ec-ev-date")?.value || "",
          assignee: row.querySelector(".ec-ev-assignee")?.value || "",
        });
      }

      const caseData = {
        testCaseId: get("ecId"),
        reqId: get("ecReqId"),
        title: get("ecTitle"),
        priority: get("ecPriority"),
        scenarioType: get("ecScenarioVal"),
        executionType: get("ecExecutionVal"),
        tags: get("ecTags")
          .split(",")
          .map((s) => s.trim())
          .filter(Boolean),
        description: get("ecDescription"),
        reqDetails: get("ecReqDetails"),
        preConditions: get("ecPreConditions").split("\n").filter(Boolean),
        steps: get("ecSteps").split("\n").filter(Boolean),
        expectedResult: get("ecExpected").split("\n").filter(Boolean),
        evidenceHistory: newEv,
      };

      if (!iStr || iStr === "-1") {
        // CREATION MODE
        const pi = parseInt(piStr || "-1");
        const si = parseInt(siStr || "-1");

        if (_ctx.schema === "5_level" && pi >= 0 && si >= 0 && _ctx.plans[pi]) {
          const suite = _ctx.plans[pi].suitesWithCases[si];
          if (suite) {
            if (!suite.cases) suite.cases = [];
            suite.cases.push(caseData);
            // Sync flat _cases
            const flat = [];
            _ctx.plans.forEach((p) => {
              p.suitesWithCases.forEach((s) => {
                (s.cases || []).forEach((c) => flat.push(c));
              });
            });
            _cases = flat;
          }
        } else {
          // 3-level or 4-level
          _cases.push(caseData);
        }
      } else {
        // EDIT MODE
        const i = parseInt(iStr);
        _cases[i] = { ..._cases[i], ...caseData };
      }

      mo.style.display = "none";
      renderResults(_cases, _ctx);
    });
    ["editCaseModalClose", "editCaseModalCancel"].forEach((id) =>
      on(id, "click", () => {
        document.getElementById("editCaseModal").style.display = "none";
      }),
    );

    // View modal close + edit
    ["viewCaseModalClose", "viewCaseModalClose2"].forEach((id) =>
      on(id, "click", () => {
        document.getElementById("viewCaseModal").style.display = "none";
      }),
    );
    on("viewCaseModalEdit", "click", () => {
      const mo = document.getElementById("viewCaseModal");
      const idx = parseInt(mo.dataset.idx);
      mo.style.display = "none";
      openEditCaseModal(idx);
    });

    // Evidence row add
    on("ecAddEvidenceRow", "click", () => {
      const uInp = document.getElementById("qfg-creator")?.value || "";
      const evRows = document.querySelectorAll(
        "#ecEvidenceListContainer .ec-ev-cycle",
      );
      let nextCycle = "1.0";
      if (evRows.length > 0) {
        let maxC = 0;
        evRows.forEach((el) => {
          let c = parseFloat(el.value);
          if (!isNaN(c) && c > maxC) maxC = c;
        });
        if (maxC > 0) nextCycle = (maxC + 0.1).toFixed(1);
      }
      attachEvidenceRow({
        cycle: nextCycle,
        status: "To-do",
        date: new Date().toISOString().split("T")[0],
        assignee: uInp,
      });
    });

    // AI Refine button inside editCaseModal
    on("ecAiRefineBtn", "click", function () {
      // Refines whichever textarea is most relevant — defaults to pre-conditions.
      // You can make this smarter (e.g. refine whichever field was last focused).
      aiRefineCaseField("ecReqDetails", this);
    });

    // Suite modal save
    on("editSuiteModalSave", "click", () => {
      const si = parseInt(
        document.getElementById("editSuiteModal").dataset.suiteidx || "0",
      );
      _ctx.suites[si] = {
        ..._ctx.suites[si],
        name: document.getElementById("esSuiteName")?.value || "Suite",
        id: document.getElementById("esSuiteId")?.value || "",
        date: document.getElementById("esSuiteDate")?.value || _ctx.cycleDate,
        creator:
          document.getElementById("esSuiteCreator")?.value || _ctx.creator,
      };
      document.getElementById("editSuiteModal").style.display = "none";
      renderResults(_cases, _ctx);
    });
    ["editSuiteModalClose", "editSuiteModalCancel"].forEach((id) =>
      on(id, "click", () => {
        document.getElementById("editSuiteModal").style.display = "none";
      }),
    );

    // Plan modal save
    on("editPlanModalSave", "click", () => {
      const pi = parseInt(
        document.getElementById("editPlanModal").dataset.planidx || 0,
      );
      const newName = document.getElementById("epPlanName")?.value || "";
      const newId = document.getElementById("epPlanId")?.value || "";
      const newDate =
        document.getElementById("epPlanDate")?.value || _ctx.cycleDate;
      const newCreator =
        document.getElementById("epPlanCreator")?.value || _ctx.creator;
      if (_ctx.plans && _ctx.plans[pi]) {
        _ctx.plans[pi].planName = newName;
        _ctx.plans[pi].planId = newId;
        _ctx.plans[pi].planDate = newDate;
        _ctx.plans[pi].planCreator = newCreator;
      } else {
        // Legacy single-plan fallback
        _ctx.planName = newName;
        _ctx.planId = newId;
        _ctx.cycleDate = newDate;
        _ctx.creator = newCreator;
      }
      document.getElementById("editPlanModal").style.display = "none";
      renderResults(_cases, _ctx);
    });
    ["editPlanModalClose", "editPlanModalCancel"].forEach((id) =>
      on(id, "click", () => {
        document.getElementById("editPlanModal").style.display = "none";
      }),
    );
  }

  // ── Open single-case edit modal ──────────────────────────────────
  function openEditCaseModal(i, si = -1, pi = -1) {
    const mo = document.getElementById("editCaseModal");
    mo.dataset.idx = i === null ? "-1" : i;
    mo.dataset.si = si;
    mo.dataset.pi = pi;

    const isNew = i === null;
    const titleEl = document.getElementById("editCaseModalTitle");
    if (titleEl) titleEl.innerHTML = isNew ? "&#10133; Add New Test Case" : "&#9998; Edit Test Case";
    const saveLabelEl = document.getElementById("editCaseModalSaveLabel");
    if (saveLabelEl) saveLabelEl.textContent = isNew ? "Add Test Case" : "Save Changes";
    const c = isNew
      ? {
        testCaseId: makeId(_tcIdFormat, _cases.length + 1, getVal("qfg-project")),
        title: "",
        priority: "Medium",
        scenarioType: "Happy Path",
        executionType: "Manual",
        description: "",
        preConditions: [],
        steps: ["1. Open application", "2. Perform action", "3. Verify result"],
        expectedResult: ["Application behaves as expected."],
        tags: [],
        evidenceHistory: [
          {
            cycle: _ctx.cycle || "1.0",
            status: "To-do",
            date: _ctx.cycleDate || new Date().toISOString().split("T")[0],
            assignee: _ctx.creator || "",
          },
        ],
      }
      : _cases[i];

    const set = (id, v) => {
      const el = document.getElementById(id);
      if (el) el.value = v || "";
    };
    set("ecId", c.testCaseId || "");
    set("ecReqId", c.reqId || _ctx.reqId || "");
    set("ecTitle", Array.isArray(c.title) ? c.title.join(" ") : c.title);
    set("ecPriority", c.priority || "Medium");

    // Scenario Type — resolve
    const sType = (() => {
      const raw = c.scenarioType || c.scenario_type || c.scenario || "";
      return Array.isArray(raw) ? raw.join(", ") : raw.toString().trim() || "Happy Path";
    })();
    const ecSVal = document.getElementById("ecScenarioVal");
    if (ecSVal) ecSVal.value = sType;
    const ecSSel = document.getElementById("ecScenarioSelect");
    if (ecSSel) {
      if (!Array.from(ecSSel.options).some((o) => o.value === sType) && sType) {
        const opt = document.createElement("option");
        opt.value = sType;
        opt.textContent = sType;
        ecSSel.appendChild(opt);
      }
      ecSSel.value = sType;
    }

    // Execution Type
    const eType = (() => {
      const raw = c.executionType || c.execution_type || c.execution || "";
      return Array.isArray(raw) ? raw.join(", ") : raw.toString().trim() || "Manual";
    })();
    const ecEVal = document.getElementById("ecExecutionVal");
    if (ecEVal) ecEVal.value = eType;
    const ecESel = document.getElementById("ecExecutionSelect");
    if (ecESel) {
      if (!Array.from(ecESel.options).some((o) => o.value === eType) && eType) {
        const opt = document.createElement("option");
        opt.value = eType;
        opt.textContent = eType;
        ecESel.appendChild(opt);
      }
      ecESel.value = eType;
    }

    set("ecTags", Array.isArray(c.tags) ? c.tags.join(", ") : c.tags || "");
    set("ecDescription", Array.isArray(c.description) ? c.description.join("\n") : c.description || "");
    set("ecReqDetails", c.reqDetails || "");
    set("ecPreConditions", toArr(c.preConditions || c.pre_conditions).join("\n"));
    set("ecSteps", toArr(c.steps).join("\n"));
    set("ecExpected", toArr(c.expectedResult || c.expected_result).join("\n"));

    const evCtn = document.getElementById("ecEvidenceListContainer");
    if (evCtn) {
      evCtn.innerHTML = "";
      (c.evidenceHistory || []).forEach((ev) => attachEvidenceRow(ev));
      if (!c.evidenceHistory || c.evidenceHistory.length === 0) {
        attachEvidenceRow({
          cycle: "1.0",
          status: "To-do",
          date: new Date().toISOString().split("T")[0],
          assignee: document.getElementById("qfg-creator")?.value || "",
        });
      }
    }

    mo.style.display = "flex";
  }

  // ── Open view (detail) modal ────────────────────────────────────
  function openViewCaseModal(i) {
    const c = _cases[i];
    if (!c) return;

    const mo = document.getElementById("viewCaseModal");
    mo.dataset.idx = i;

    const tcId = c.testCaseId || `TC-${String(i + 1).padStart(2, "0")}`;
    const title = Array.isArray(c.title) ? c.title.join(" ") : (c.title || "Untitled");

    // Header
    document.getElementById("vcModalTcId").textContent = tcId;
    document.getElementById("vcModalTitle").textContent = title;

    // Meta ribbon
    const priColor = (p) => p === "High" ? "#ef4444" : p === "Low" ? "#22c55e" : p === "Critical" ? "#7c3aed" : "#f59e0b";
    const evHist = c.evidenceHistory && c.evidenceHistory.length > 0 ? c.evidenceHistory[c.evidenceHistory.length - 1] : null;
    const assignee = evHist ? evHist.assignee : (c.assignee || "Unassigned");
    const status = evHist ? (evHist.status || "To-do") : "To-do";
    const statusColor = status === "Passed" ? "#16a34a" : status === "Failed" ? "#dc2626" : status === "In Progress" ? "#2563eb" : status === "Blocked" ? "#9333ea" : "#64748b";

    const pills = [
      `<span class="vc-meta-pill" style="background:${priColor(c.priority || "Medium")}18;color:${priColor(c.priority || "Medium")};border:1px solid ${priColor(c.priority || "Medium")}44">⚡ ${esc(c.priority || "Medium")}</span>`,
      c.scenarioType ? `<span class="vc-meta-pill" style="background:#f1f5f9;color:#475569;border:1px solid #cbd5e1">🎯 ${esc(c.scenarioType)}</span>` : "",
      c.executionType ? `<span class="vc-meta-pill" style="background:#eff6ff;color:#1d4ed8;border:1px solid #bfdbfe">🔧 ${esc(c.executionType)}</span>` : "",
      c.reqId || _ctx.reqId ? `<span class="vc-meta-pill" style="background:#fefce8;color:#a16207;border:1px solid #fef08a">📌 ${esc(c.reqId || _ctx.reqId)}</span>` : "",
      assignee ? `<span class="vc-meta-pill" style="background:#faf5ff;color:#6d28d9;border:1px solid #e9d5ff">👤 ${esc(assignee)}</span>` : "",
      `<span class="vc-meta-pill" style="background:${statusColor}18;color:${statusColor};border:1px solid ${statusColor}44">● ${esc(status)}</span>`,
      c.tags && c.tags.length > 0 ? `<span class="vc-meta-pill" style="background:#f3e8ff;color:#7c3aed;border:1px solid #e9d5ff">🏷️ ${esc(Array.isArray(c.tags) ? c.tags.join(", ") : c.tags)}</span>` : "",
    ].filter(Boolean).join("");
    document.getElementById("vcMetaRibbon").innerHTML = pills;

    // Description
    const desc = Array.isArray(c.description) ? c.description.join("\n") : (c.description || "");
    const descBlock = document.getElementById("vcDescBlock");
    if (desc.trim()) {
      document.getElementById("vcDescription").textContent = desc;
      descBlock.style.display = "";
    } else {
      descBlock.style.display = "none";
    }

    // Helper: render array to <li> list
    const fillList = (elId, blockId, val) => {
      const items = toArr(val).filter(Boolean);
      const block = document.getElementById(blockId);
      if (items.length) {
        document.getElementById(elId).innerHTML = items.map(s => `<li>${esc(String(s))}</li>`).join("");
        block.style.display = "";
      } else {
        block.style.display = "none";
      }
    };

    fillList("vcPreConditions", "vcPreBlock", c.preConditions || c.pre_conditions);
    fillList("vcSteps", "vcStepsBlock", c.steps);
    fillList("vcExpected", "vcExpBlock", c.expectedResult || c.expected_result);

    // Evidence history
    const evBlock = document.getElementById("vcEvBlock");
    const evList = document.getElementById("vcEvidenceList");
    const history = c.evidenceHistory || [];
    if (history.length > 0) {
      const statusCol = (s) => s === "Passed" ? "#16a34a" : s === "Failed" ? "#dc2626" : s === "In Progress" ? "#2563eb" : s === "Blocked" ? "#9333ea" : "#64748b";
      evList.innerHTML = history.map((ev) => {
        const s = ev.status || "To-do";
        const sc = statusCol(s);
        return `<div class="vc-ev-row" style="border-left-color:${sc}">
          <span style="display:inline-flex;align-items:center;gap:4px;background:#eff6ff;border:1px solid #bfdbfe;border-radius:6px;padding:2px 9px;font-size:.75rem;font-weight:700;color:#1d4ed8">
            CYCLE ${esc(ev.cycle || "—")}
          </span>
          <span style="display:inline-flex;align-items:center;gap:4px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:6px;padding:2px 9px;font-size:.75rem;color:#15803d">
            📅 ${esc(ev.cycleDate || ev.date || "—")}
          </span>
          <span style="font-size:.73rem;font-weight:700;padding:2px 10px;border-radius:999px;background:${sc}18;color:${sc};border:1px solid ${sc}44">${esc(s)}</span>
          <span style="display:inline-flex;align-items:center;gap:4px;background:#faf5ff;border:1px solid #e9d5ff;border-radius:6px;padding:2px 9px;font-size:.75rem;color:#6d28d9">
            👤 ${esc(ev.assignee || "Unassigned")}
          </span>
        </div>`;
      }).join("");
      evBlock.style.display = "";
    } else {
      evBlock.style.display = "none";
    }

    mo.style.display = "flex";
  }

  // ── Open suite edit modal ────────────────────────────────────────
  function openEditSuiteModal(si) {
    const suite = _ctx.suites[si];
    const mo = document.getElementById("editSuiteModal");
    mo.dataset.suiteidx = si;
    const setV = (id, v) => {
      const el = document.getElementById(id);
      if (el) el.value = v || "";
    };
    setV("esSuiteName", suite.name);
    setV("esSuiteId", suite.id);
    setV("esSuiteCreator", suite.creator);
    // Normalise date — could be ISO or MM-DD-YYYY
    const suiteIso = suite.date
      ? suite.date.match(/^\d{4}-\d{2}-\d{2}$/)
        ? suite.date
        : displayToIso(suite.date)
      : new Date().toISOString().slice(0, 10);
    setDateFields("esSuiteDate", "esSuiteDateText", suiteIso);
    qfDatePicker(
      document.getElementById("esSuiteDateText"),
      document.getElementById("esSuiteDate"),
      suiteIso,
    );
    mo.style.display = "flex";
  }

  // ── Open plan edit modal ─────────────────────────────────────────
  function openEditPlanModal(pi = 0) {
    const mo = document.getElementById("editPlanModal");
    mo.dataset.planidx = pi;
    const setV = (id, v) => {
      const el = document.getElementById(id);
      if (el) el.value = v || "";
    };
    const plan = (_ctx.plans && _ctx.plans[pi]) || null;
    setV("epPlanName", plan ? plan.planName : _ctx.planName);
    setV("epPlanId", plan ? plan.planId : _ctx.planId);
    setV("epPlanCreator", plan ? plan.planCreator : _ctx.creator);
    // Normalise date — could be ISO or MM-DD-YYYY
    const rawDate = plan ? plan.planDate : _ctx.cycleDate;
    const planIso = rawDate
      ? rawDate.match(/^\d{4}-\d{2}-\d{2}$/)
        ? rawDate
        : displayToIso(rawDate)
      : new Date().toISOString().slice(0, 10);
    setDateFields("epPlanDate", "epPlanDateText", planIso);
    qfDatePicker(
      document.getElementById("epPlanDateText"),
      document.getElementById("epPlanDate"),
      planIso,
    );
    mo.style.display = "flex";
  }

  // ── Add blank case to suite ──────────────────────────────────────
  function addBlankCase(si, pi = -1) {
    // We no longer push to _cases here. 
    // Instead, we open the modal in 'new' mode (null index).
    // The data is saved to _cases only when 'Save Changes' is clicked.
    openEditCaseModal(null, si, pi);
  }

  // ── Build Hierarchy Tree — QF reference style ────────────────────────
  function buildHierarchyTree(cases, ctx) {
    const priColor = (p) =>
      p === "High" ? "#ef4444" : p === "Low" ? "#22c55e" : "#f59e0b";
    const priStyle = (p) => `background:${priColor(p)}22;color:${priColor(p)};`;
    const statusBadge = (s = "To-do") => {
      const col =
        s === "Passed"
          ? "#16a34a"
          : s === "Failed"
            ? "#dc2626"
            : s === "In Progress"
              ? "#2563eb"
              : "#64748b";
      return `<span class="qfg-tree-ev" style="background:${col}18;color:${col};border:1px solid ${col}44">${esc(s)}</span>`;
    };

    const treeNode = (
      iconHtml,
      labelHtml,
      actionsHtml,
      childrenHtml,
      open = true,
    ) => `
      <div class="qfg-tree-node ${open ? "open" : ""}">
        <div class="qfg-tree-header">
          <span class="qfg-tree-toggle">▼</span>
          ${iconHtml}
          <span style="flex:1">${labelHtml}</span>
          <div class="qfg-tree-actions">${actionsHtml}</div>
        </div>
        <div class="qfg-tree-children">${childrenHtml}</div>
      </div>`;

    const leafNode = (iconHtml, labelHtml, actionsHtml) => `
      <div class="qfg-tree-node" style="margin-bottom:3px">
        <div class="qfg-tree-header" style="cursor:default;">
          ${iconHtml}
          <span style="flex:1">${labelHtml}</span>
          <div class="qfg-tree-actions">${actionsHtml}</div>
        </div>
      </div>`;

    const tcNode = (c, tcIdx, tcId) => {
      const evHistory =
        c.evidenceHistory && c.evidenceHistory.length > 0
          ? c.evidenceHistory
          : [
            {
              cycle: _ctx.cycle || "1.0",
              status: "To-do",
              date: _ctx.cycleDate || "",
              assignee: c.assignee || _ctx.creator || "Unassigned",
            },
          ];

      // Build one evidence card per cycle run
      const evCards = evHistory
        .map((ev, evIdx) => {
          const s = ev.status || "To-do";
          const sCol =
            s === "Passed"
              ? "#16a34a"
              : s === "Failed"
                ? "#dc2626"
                : s === "In Progress"
                  ? "#2563eb"
                  : s === "Blocked"
                    ? "#9333ea"
                    : "#64748b";
          const cycleLabel = ev.cycle || "1.0";
          const dateLabel = ev.cycleDate || ev.date || "—";
          const assignee = ev.assignee || ev.executedBy || "Unassigned";
          return `
        <div style="display:flex;align-items:center;flex-wrap:wrap;gap:8px;padding:7px 10px 7px 12px;background:#f8fafc;border-radius:7px;margin-bottom:4px;border-left:3px solid ${sCol};">
          <span style="font-size:.85rem">&#128247;</span>
          <span style="font-size:.7rem;font-weight:800;color:#94a3b8;text-transform:uppercase;letter-spacing:.04em">Evidence</span>
          <!-- Cycle pill -->
          <span style="display:inline-flex;align-items:center;gap:4px;background:#eff6ff;border:1px solid #bfdbfe;border-radius:6px;padding:2px 8px;">
            <span style="font-size:.62rem;color:#3b82f6;font-weight:800">CYCLE</span>
            <span style="font-size:.75rem;font-weight:700;color:#1d4ed8">${esc(cycleLabel)}</span>
          </span>
          <!-- Date pill -->
          <span style="display:inline-flex;align-items:center;gap:4px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:6px;padding:2px 8px;">
            <span style="font-size:.62rem;color:#16a34a;font-weight:800">&#128197;</span>
            <span style="font-size:.75rem;color:#15803d">${esc(dateLabel)}</span>
          </span>
          <!-- Status badge -->
          <span style="font-size:.72rem;font-weight:700;padding:2px 9px;border-radius:999px;background:${sCol}18;color:${sCol};border:1px solid ${sCol}44;">${esc(s)}</span>
          <!-- Assignee -->
          <span style="display:inline-flex;align-items:center;gap:4px;background:#faf5ff;border:1px solid #e9d5ff;border-radius:6px;padding:2px 8px;">
            <span style="font-size:.62rem;color:#7c3aed;font-weight:800">&#128100;</span>
            <span style="font-size:.75rem;color:#6d28d9">${esc(assignee)}</span>
          </span>
        </div>`;
        })
        .join("");

      const evChildren = `<div style="margin-top:6px;padding-left:4px;">${evCards}</div>`;

      const title = esc(
        Array.isArray(c.title) ? c.title.join(" ") : c.title || "Untitled",
      );
      return treeNode(
        `<span style="font-size:.85rem">&#128196;</span>`,
        `<span style="font-size:.8rem;font-weight:600;color:#0f172a">
           <span style="font-size:.68rem;font-weight:800;padding:1px 6px;border-radius:4px;${priStyle(c.priority || "Medium")};margin-right:4px">${esc(c.priority || "Medium")}</span>
           <span style="font-size:.68rem;color:#94a3b8;margin-right:6px">${esc(tcId)}</span>
           ${title}
           <span style="font-size:.68rem;color:#94a3b8;margin-left:6px">${esc(c.scenarioType || c.scenario_type || "")}</span>
           ${c.tags && c.tags.length > 0 ? `<span style="font-size:.68rem;color:#7e22ce;background:#f3e8ff;padding:1px 6px;border-radius:4px;margin-left:6px">&#127991; ${esc(Array.isArray(c.tags) ? c.tags.join(", ") : c.tags)}</span>` : ""}
         </span>`,
        `<button class="qfg-tree-act edit" data-action="edit-tc" data-idx="${tcIdx}">&#9998; Edit</button>
         <button class="qfg-tree-act del"  data-action="del-tc"  data-idx="${tcIdx}">&#128465; Delete</button>`,
        evChildren,
        true,
      );
    };

    let html = `<div style="font-family:inherit;">`;

    // Project root node
    const projChildren = (() => {
      if (
        (ctx.schema === "4_level" || ctx.schema === "5_level") &&
        ctx.suites &&
        ctx.suites.length
      ) {
        const perSuite = Math.ceil(cases.length / ctx.suites.length);
        let inner = "";

        // 5-level: Plan wrapper
        if (ctx.schema === "5_level" && ctx.planName) {
          const planActionsHtml = `
            <button class="qfg-tree-act edit" data-action="edit-plan">&#9998; Edit Plan</button>`;
          const suiteNodes = ctx.suites
            .map((suite, si) => {
              const batch = cases.slice(si * perSuite, (si + 1) * perSuite);
              const suiteId =
                suite.id || "SUITE-" + String(si + 1).padStart(3, "0");
              const tcNodes = batch
                .map((c, i) =>
                  tcNode(
                    c,
                    si * perSuite + i,
                    makeTcId(
                      ctx.reqId,
                      si * perSuite + i + 1,
                      ctx.project,
                      suite.name,
                    ),
                  ),
                )
                .join("");
              return treeNode(
                `<span style="font-size:.85rem">&#128203;</span>`,
                `<span style="font-weight:700;color:#0369a1;font-size:.85rem">Suite: <strong>${esc(suite.name || "Suite")}</strong></span>
               <span style="font-size:.68rem;color:#94a3b8;margin-left:6px">${suiteId} &middot; ${batch.length} case${batch.length === 1 ? "" : "s"}</span>`,
                `<button class="qfg-tree-act edit" data-action="add-case-suite" data-si="${si}">+ Case</button>
               <button class="qfg-tree-act edit" data-action="edit-suite" data-si="${si}">&#9998; Edit</button>
               <button class="qfg-tree-act del"  data-action="del-suite"  data-si="${si}">&#128465; Del</button>`,
                tcNodes,
              );
            })
            .join("");
          inner = treeNode(
            `<span style="font-size:.85rem">&#128204;</span>`,
            `<span style="font-weight:700;color:#7c3aed;font-size:.88rem">Plan: <strong>${esc(ctx.planName)}</strong></span>
             <span style="font-size:.68rem;color:#94a3b8;margin-left:6px">${esc(ctx.planId || "")}</span>`,
            planActionsHtml,
            suiteNodes,
          );
        } else {
          // 4-level: suites directly under project
          inner = ctx.suites
            .map((suite, si) => {
              const batch = cases.slice(si * perSuite, (si + 1) * perSuite);
              const suiteId =
                suite.id || "SUITE-" + String(si + 1).padStart(3, "0");
              const tcNodes = batch
                .map((c, i) =>
                  tcNode(
                    c,
                    si * perSuite + i,
                    makeTcId(
                      ctx.reqId,
                      si * perSuite + i + 1,
                      ctx.project,
                      suite.name,
                    ),
                  ),
                )
                .join("");
              return treeNode(
                `<span style="font-size:.85rem">&#128203;</span>`,
                `<span style="font-weight:700;color:#0369a1;font-size:.85rem">Suite: <strong>${esc(suite.name || "Suite")}</strong></span>
               <span style="font-size:.68rem;color:#94a3b8;margin-left:6px">${suiteId} &middot; ${batch.length} case${batch.length === 1 ? "" : "s"}</span>`,
                `<button class="qfg-tree-act edit" data-action="add-case-suite" data-si="${si}">+ Case</button>
               <button class="qfg-tree-act edit" data-action="edit-suite" data-si="${si}">&#9998; Edit</button>
               <button class="qfg-tree-act del"  data-action="del-suite"  data-si="${si}">&#128465; Del</button>`,
                tcNodes,
              );
            })
            .join("");
        }
        return inner;
      } else {
        // 3-level: test cases directly under project
        return cases
          .map((c, i) =>
            tcNode(c, i, makeTcId(ctx.reqId, i + 1, ctx.project, "")),
          )
          .join("");
      }
    })();

    html += treeNode(
      `<span style="font-size:.9rem">&#128193;</span>`,
      `<span style="font-weight:800;color:#1e293b;font-size:.92rem">${esc(ctx.project)}</span>
       <span style="font-size:.68rem;padding:2px 8px;border-radius:999px;background:#eff6ff;color:#2563eb;margin-left:8px;font-weight:700">${ctx.schema.replace("_", "-")}</span>`,
      `<span style="font-size:.72rem;color:#64748b">${cases.length} total test case${cases.length === 1 ? "" : "s"}</span>`,
      projChildren,
    );

    html += `</div>`;
    return html;
  }

  // ── Build HFM Markdown ───────────────────────────────────────────
  function buildMarkdown(cases, ctx) {
    const nl = "\n";
    const str = (v) => toArr(v).join("\n");
    const listul = (v) =>
      toArr(v)
        .map((s) => `- ${s}`)
        .join(nl);
    const chk = (v, numbered) => {
      return toArr(v)
        .map((s, i) => {
          const text = String(s).replace(/^\d+\.\s*/, "");
          return `- [x] ${numbered ? i + 1 + ". " : ""}${text}`;
        })
        .join(nl);
    };

    let md = `---${nl}doc-classify:${nl}`;
    md += `  - select: heading[depth="1"]${nl}    role: project${nl}`;
    if (ctx.schema === "5_level") {
      md += `  - select: heading[depth="2"]${nl}    role: plan${nl}`;
      md += `  - select: heading[depth="3"]${nl}    role: suite${nl}`;
      md += `  - select: heading[depth="4"]${nl}    role: case${nl}`;
      md += `  - select: heading[depth="5"]${nl}    role: evidence${nl}`;
    } else if (ctx.schema === "4_level") {
      md += `  - select: heading[depth="2"]${nl}    role: suite${nl}`;
      md += `  - select: heading[depth="3"]${nl}    role: case${nl}`;
      md += `  - select: heading[depth="4"]${nl}    role: evidence${nl}`;
    } else {
      md += `  - select: heading[depth="2"]${nl}    role: case${nl}`;
      md += `  - select: heading[depth="3"]${nl}    role: evidence${nl}`;
    }
    md += `---${nl}${nl}`;

    const projId = ctx.project.toLowerCase().replace(/\s+/g, "-") + "-project";
    md += `# ${ctx.project}${nl}${nl}@id ${projId}${nl}${nl}`;

    const meta = ctx.metadata || {};
    md += `${meta.project_description || `This project provides a comprehensive validation framework for **${ctx.project}**.`}${nl}${nl}`;

    if (meta.project_objectives && meta.project_objectives.length > 0) {
      md += `**Objectives**${nl}${nl}${listul(meta.project_objectives)}${nl}${nl}`;
    }
    if (meta.project_risks && meta.project_risks.length > 0) {
      md += `**Risks**${nl}${nl}${listul(meta.project_risks)}${nl}${nl}`;
    }

    // In Level 3 only, Requirements come right after project header.
    if (ctx.schema === "3_level" && ctx.reqText) {
      md += `**Requirements**${nl}${nl}${ctx.reqText}${nl}${nl}`;
    }
    md += `---${nl}${nl}`;

    // 5-level: emit each plan with its suites
    if (ctx.schema === "5_level" && ctx.plans && ctx.plans.length) {
      ctx.plans.forEach((plan) => {
        const planMeta = plan.suitesWithCases[0]?.metadata || meta;
        const planId = plan.planId || "PLAN-001";
        md += `## ${plan.planName}${nl}${nl}@id ${planId}${nl}${nl}`;
        md += `\`\`\`yaml HFM${nl}  plan-name: ${plan.planName}${nl}  plan-date: ${plan.planDate || ctx.cycleDate}${nl}  created-by: ${plan.planCreator || ctx.creator || "User"}${nl}\`\`\`${nl}${nl}`;

        if (planMeta.plan_objectives && planMeta.plan_objectives.length > 0) {
          md += `**Objectives**${nl}${nl}${listul(planMeta.plan_objectives)}${nl}${nl}`;
        }
        if (planMeta.plan_risks && planMeta.plan_risks.length > 0) {
          md += `**Risks**${nl}${nl}${listul(planMeta.plan_risks)}${nl}${nl}`;
        }
        if (planMeta.plan_cycle_goals && planMeta.plan_cycle_goals.length > 0) {
          md += `**Cycle Goals**${nl}${nl}${listul(planMeta.plan_cycle_goals)}${nl}${nl}`;
        }
        md += `---${nl}${nl}`;
      });
    } else if (ctx.schema === "5_level" && ctx.planName) {
      // Legacy single-plan fallback
      const planId = ctx.planId || "PLAN-001";
      md += `## ${ctx.planName}${nl}${nl}@id ${planId}${nl}${nl}`;
      md += `\`\`\`yaml HFM${nl}  plan-name: ${ctx.planName}${nl}  plan-date: ${ctx.cycleDate}${nl}  created-by: ${ctx.creator || "User"}${nl}\`\`\`${nl}${nl}`;

      if (meta.plan_objectives && meta.plan_objectives.length > 0) {
        md += `**Objectives**${nl}${nl}${listul(meta.plan_objectives)}${nl}${nl}`;
      }
      if (meta.plan_risks && meta.plan_risks.length > 0) {
        md += `**Risks**${nl}${nl}${listul(meta.plan_risks)}${nl}${nl}`;
      }
      if (meta.plan_cycle_goals && meta.plan_cycle_goals.length > 0) {
        md += `**Cycle Goals**${nl}${nl}${listul(meta.plan_cycle_goals)}${nl}${nl}`;
      }
      if (ctx.reqText) {
        md += `**Requirements**${nl}${nl}${ctx.reqText}${nl}${nl}`;
      }
      md += `---${nl}${nl}`;
    }

    const evPfx =
      ctx.schema === "5_level"
        ? "#####"
        : ctx.schema === "4_level"
          ? "####"
          : "###";
    const casePfx =
      ctx.schema === "3_level"
        ? "##"
        : ctx.schema === "4_level"
          ? "###"
          : "####";

    const serCase = (c, tcId) => {
      let s = `${casePfx} ${str(c.title) || "Test Case"}${nl}${nl}@id ${tcId}${nl}${nl}`;
      s += `\`\`\`yaml HFM${nl}  requirementID: ${ctx.reqId}${nl}  Priority: ${c.priority || "Medium"}${nl}`;
      s += `  Tags: ${JSON.stringify(c.tags || [])}${nl}  Scenario Type: ${c.scenarioType || c.scenario_type || "Happy Path"}${nl}`;
      s += `  Execution Type: ${c.executionType || c.execution_type || "Manual"}${nl}\`\`\`${nl}${nl}`;
      s += `**Description**${nl}${nl}${str(c.description || "—")}${nl}${nl}`;
      if (c.reqDetails && String(c.reqDetails).trim()) {
        s += `**Requirements**${nl}${nl}${str(c.reqDetails)}${nl}${nl}`;
      }
      s += `**Preconditions**${nl}${nl}${chk(c.preConditions || c.pre_conditions || ["—"])}${nl}${nl}`;
      s += `**Steps**${nl}${nl}${chk(c.steps || ["—"], true)}${nl}${nl}`;
      s += `**Expected Results**${nl}${nl}${chk(c.expectedResult || c.expected_result || ["—"])}${nl}${nl}`;
      const evHistArray =
        c.evidenceHistory && c.evidenceHistory.length > 0
          ? c.evidenceHistory
          : [
            {
              cycle: ctx.cycle,
              date: ctx.cycleDate,
              assignee: c.assignee || ctx.creator || "Unassigned",
              status: "To-do",
            },
          ];

      evHistArray.forEach((evHist) => {
        const rCycle = evHist.cycle || ctx.cycle || "1.0";
        const rDate = evHist.cycleDate || evHist.date || ctx.cycleDate;
        const rAsgn =
          evHist.assignee || c.assignee || ctx.creator || "Unassigned";
        const rStatus = evHist.status || "To-do";

        s += `${evPfx} Evidence${nl}${nl}@id ${tcId}${nl}${nl}`;
        s += `\`\`\`yaml META${nl}  cycle: ${rCycle}${nl}  cycle-date: ${rDate}${nl}  severity: ${c.priority || "Medium"}${nl}  assignee: ${rAsgn}${nl}  status: ${rStatus}${nl}\`\`\`${nl}${nl}`;
        s += `**Attachments**${nl}${nl}`;
        if (
          evHist.attachments &&
          typeof evHist.attachments === "string" &&
          evHist.attachments.trim().length > 0
        ) {
          s += `${evHist.attachments.trim()}${nl}${nl}`;
        } else {
          s += `- [Result JSON](./evidence/${tcId}/${rCycle}/result.auto.json)${nl}`;
          s += `- [Screenshot](./evidence/${tcId}/${rCycle}/screenshot.auto.png)${nl}`;
          s += `- [Run MD](./evidence/${tcId}/${rCycle}/run.auto.md)${nl}${nl}`;
        }
      });
      s += `---${nl}${nl}`;
      return s;
    };

    // 5-level: iterate plans → suites → cases
    if (ctx.schema === "5_level" && ctx.plans && ctx.plans.length) {
      let globalTcNum = 0;
      ctx.plans.forEach((plan) => {
        plan.suitesWithCases.forEach((suite) => {
          const suiteId =
            suite.id || "SUITE-" + String(++globalTcNum).padStart(3, "0");
          md += `### ${suite.name || "Suite"}${nl}${nl}@id ${suiteId}${nl}${nl}`;
          md += `\`\`\`yaml HFM${nl}  suite-name: ${suite.name || "Suite"}${nl}  suite-date: ${suite.date || ctx.cycleDate}${nl}  created-by: ${suite.creator || ctx.creator || "User"}${nl}\`\`\`${nl}${nl}`;
          const suiteMeta = suite.metadata || meta;
          if (suiteMeta.suite_scope && suiteMeta.suite_scope.length > 0) {
            md += `**Scope**${nl}${nl}${listul(suiteMeta.suite_scope)}${nl}${nl}`;
          }
          md += `**Test Cases**${nl}${nl}`;
          (suite.cases || []).forEach((c, i) => {
            md += `- **${makeTcId(suite.reqId || ctx.reqId, i + 1, ctx.project, suite.name)}** – ${str(c.title)}${nl}`;
          });
          md += `${nl}`;
          (suite.cases || []).forEach((c, i) => {
            md += serCase(
              c,
              makeTcId(
                suite.reqId || ctx.reqId,
                i + 1,
                ctx.project,
                suite.name,
              ),
            );
          });
        });
      });
    } else if (ctx.schema === "4_level" && ctx.suites && ctx.suites.length) {
      const perSuite = Math.ceil(cases.length / ctx.suites.length);
      ctx.suites.forEach((suite, si) => {
        const batch = cases.slice(si * perSuite, (si + 1) * perSuite);
        const suiteId = suite.id || "SUITE-" + String(si + 1).padStart(3, "0");
        md += `## ${suite.name || "Suite"}${nl}${nl}@id ${suiteId}${nl}${nl}`;
        md += `\`\`\`yaml HFM${nl}  suite-name: ${suite.name || "Suite"}${nl}  suite-date: ${suite.date || ctx.cycleDate}${nl}  created-by: ${suite.creator || ctx.creator || "User"}${nl}\`\`\`${nl}${nl}`;

        const suiteMeta =
          (ctx.suitesWithCases &&
            ctx.suitesWithCases[si] &&
            ctx.suitesWithCases[si].metadata) ||
          meta;
        if (suiteMeta.suite_scope && suiteMeta.suite_scope.length > 0) {
          md += `**Scope**${nl}${nl}${listul(suiteMeta.suite_scope)}${nl}${nl}`;
        }

        md += `**Test Cases**${nl}${nl}`;
        batch.forEach((c, i) => {
          md += `- **${makeTcId(ctx.reqId, si * perSuite + i + 1, ctx.project, suite.name)}** – ${str(c.title)}${nl}`;
        });
        md += `${nl}`;

        if (suite.reqText) {
          md += `**Requirements**${nl}${nl}${suite.reqText}${nl}${nl}`;
        }

        batch.forEach((c, i) => {
          md += serCase(
            c,
            makeTcId(ctx.reqId, si * perSuite + i + 1, ctx.project, suite.name),
          );
        });
      });
    } else {
      cases.forEach((c, i) => {
        md += serCase(c, makeTcId(ctx.reqId, i + 1, ctx.project, ""));
      });
    }
    return md;
  }

  function showModal(title, message) {
    document.getElementById("bulkModalTitle").textContent = title;
    document.getElementById("bulkModalMessage").textContent = message;
    document.getElementById("bulkModal").style.display = "block";
  }

  function closeModal() {
    document.getElementById("bulkModal").style.display = "none";
  }

  document.getElementById("bulkModalClose").onclick = closeModal;
  document.getElementById("bulkModalOk").onclick = closeModal;
  window.onclick = function (event) {
    if (event.target === document.getElementById("bulkModal")) {
      closeModal();
    }
  };

  // ── Reset ────────────────────────────────────────────────────────
  function resetForm() {
    const schema = document.getElementById("qfg-schema");
    if (schema) schema.value = "";
    onSchemaChange("");
    ["qfg-project", "qfg-req-title", "qfg-req-text", "qfg-req-desc"].forEach(
      (id) => {
        const el = document.getElementById(id);
        if (el) el.value = "";
      },
    );
    const reqId = document.getElementById("qfg-req-id");
    if (reqId) reqId.value = "REQ-001";
    const sl = document.getElementById("qfg-suite-list");
    if (sl) sl.innerHTML = "";
    const pl = document.getElementById("qfg-plan-list");
    if (pl) pl.innerHTML = "";
    suiteCount = 0;
    planCount = 0;
    planSuiteCounters = {};
    _cases = [];
    _ctx = {};
    const res = document.getElementById("qfg-results");
    if (res) res.style.display = "none";
  }

  // ── Markdown destination fetch (inside IIFE so _markdownDest is in scope) ──
  async function initializeMarkdownDestination() {
    try {
      // SQLPage serves pages without the .sql extension in the URL
      const response = await fetch('/pages/get_markdown_destination.sql');
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: Could not fetch markdown destination`);
      }
      const data = await response.json();
      if (data.destination) {
        _markdownDest = data.destination; // correctly writes to IIFE-scoped variable
        console.log('✓ Markdown destination loaded from server:', _markdownDest);
      } else {
        console.warn('No destination in response, using default');
        _markdownDest = 'test-artifacts';
      }
    } catch (error) {
      console.error('Could not fetch markdown destination from server:', error);
      _markdownDest = 'test-artifacts';
    }
  }

  // ── Boot ─────────────────────────────────────────────────────────
  // Public API - Tab Bar Methods
  window.QFGenerator = window.QFGenerator || {};
  window.QFGenerator.tabBarHTML = tabBarHTML;
  window.QFGenerator.initTabBar = initTabBar;
  window.QFGenerator.insertTabBar = insertTabBar;
  window.QFGenerator.switchTab = switchTab;
  window.QFGenerator.getCurrentTab = getCurrentTab;

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();