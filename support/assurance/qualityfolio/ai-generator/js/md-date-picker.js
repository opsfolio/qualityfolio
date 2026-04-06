/**
 * md-date-picker.js — QualityFolio
 * Attaches Pikaday MM-DD-YYYY calendar pickers to all date fields
 * on both the Generator and Markdown Editor pages.
 * Loaded AFTER pikaday.js in the script list.
 */
(function () {
  "use strict";

  /* ── Helpers ─────────────────────────────────────────────────── */
  function isoToDisplay(iso) {
    if (!iso) return "";
    var p = iso.split("-");
    return p.length === 3 ? p[1] + "-" + p[2] + "-" + p[0] : iso;
  }
  function displayToIso(disp) {
    if (!disp) return "";
    var p = disp.split("-");
    return p.length === 3 ? p[2] + "-" + p[0] + "-" + p[1] : disp;
  }

  /* ── Core Pikaday attach ─────────────────────────────────────── */
  function attachPikaday(displayEl, hiddenEl, isoVal) {
    if (!displayEl) return;

    // Set initial value immediately
    if (isoVal) {
      if (hiddenEl) hiddenEl.value = isoVal;
      displayEl.value = isoToDisplay(isoVal);
    }

    // Retry up to 30× (3 s) in case Pikaday CDN is still loading
    var attempts = 0;
    function tryAttach() {
      if (typeof Pikaday === "undefined") {
        if (++attempts < 30) setTimeout(tryAttach, 100);
        return;
      }
      if (displayEl._pk) { displayEl._pk.destroy(); displayEl._pk = null; }

      var pk = new Pikaday({
        field: displayEl,
        trigger: displayEl,
        format: "MM-DD-YYYY",
        theme: "qf-pikaday",
        toString: function (date) {
          var m = String(date.getMonth() + 1).padStart(2, "0");
          var d = String(date.getDate()).padStart(2, "0");
          var y = date.getFullYear();
          return m + "-" + d + "-" + y;
        },
        parse: function (s) {
          var p = s.split("-");
          return p.length === 3 ? new Date(p[2], p[0] - 1, p[1]) : new Date();
        },
        onSelect: function (date) {
          var m = String(date.getMonth() + 1).padStart(2, "0");
          var d = String(date.getDate()).padStart(2, "0");
          var y = date.getFullYear();
          displayEl.value = m + "-" + d + "-" + y;
          if (hiddenEl) hiddenEl.value = y + "-" + m + "-" + d;
        },
      });

      // Pre-select existing value
      var isoSrc = (hiddenEl && hiddenEl.value) || isoVal || "";
      if (isoSrc) {
        var p = isoSrc.split("-");
        if (p.length === 3) pk.setDate(new Date(p[0], p[1] - 1, p[2]), true);
      }
      displayEl._pk = pk;
    }
    tryAttach();
  }

  /* ── Pikaday theme (injected once) ───────────────────────────── */
  function injectTheme() {
    if (document.getElementById("qf-pikaday-theme")) return;
    var s = document.createElement("style");
    s.id = "qf-pikaday-theme";
    s.textContent = [
      ".pika-single.qf-pikaday{font-family:'Inter',system-ui,sans-serif;border:1px solid #e2e8f0;border-radius:12px;box-shadow:0 8px 32px rgba(0,0,0,.12);background:#fff;overflow:hidden;}",
      ".qf-pikaday .pika-lendar{padding:10px 12px;}",
      ".qf-pikaday .pika-title{padding:4px 0 8px;}",
      ".qf-pikaday .pika-label{font-size:.85rem;font-weight:700;color:#1e293b;background:#fff;}",
      ".qf-pikaday .pika-prev,.qf-pikaday .pika-next{opacity:.7;transition:opacity .15s;}",
      ".qf-pikaday .pika-prev:hover,.qf-pikaday .pika-next:hover{opacity:1;}",
      ".qf-pikaday table{border-collapse:collapse;}",
      ".qf-pikaday th abbr{font-size:.7rem;font-weight:700;color:#94a3b8;text-decoration:none;text-transform:uppercase;}",
      ".qf-pikaday td{padding:2px;}",
      ".qf-pikaday .pika-button{border-radius:8px;font-size:.82rem;font-weight:500;color:#334155;padding:6px 4px;text-align:center;transition:background .12s,color .12s;}",
      ".qf-pikaday .pika-button:hover{background:#e0f2fe;color:#0369a1;}",
      ".qf-pikaday .is-today .pika-button{background:#f0fdf4;color:#16a34a;font-weight:700;}",
      ".qf-pikaday .is-selected .pika-button{background:linear-gradient(135deg,#2563eb,#0ea5e9);color:#fff!important;border-radius:8px;font-weight:700;}",
      ".qf-pikaday .is-disabled .pika-button{color:#cbd5e1;cursor:default;}"
    ].join("");
    document.head.appendChild(s);
  }

  /* ── Get today in ISO ─────────────────────────────────────────── */
  function todayIso() {
    var t = new Date();
    var m = String(t.getMonth() + 1).padStart(2, "0");
    var d = String(t.getDate()).padStart(2, "0");
    return t.getFullYear() + "-" + m + "-" + d;
  }

  /* ── Expose global helpers for dynamic rows ──────────────────── */
  window.qfAttachDatePicker = attachPikaday;
  window.qfIsoToDisplay = isoToDisplay;

  /* ── MutationObserver for dynamic fields ────────────────────── */
  function startObserver() {
    var observer = new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        mutation.addedNodes.forEach(function (node) {
          if (node.nodeType !== 1) return;

          // 1. Check if the node itself is a date field
          var isDate = node.classList && (
            node.classList.contains("ev-date") ||
            node.classList.contains("qf-date") ||
            node.classList.contains("qf-date-picker")
          );

          // 2. Find all date fields within the added node
          var fields = node.querySelectorAll ? Array.from(node.querySelectorAll(".ev-date, .qf-date, .qf-date-picker")) : [];
          if (isDate) fields.push(node);

          fields.forEach(function (f) {
            if (f._pk) return; // already attached

            // Find its hidden partner
            var p = f.parentNode;
            var hidden = p ? p.querySelector('input[type="hidden"]') : null;
            if (!hidden && f.id) {
              hidden = document.getElementById(f.id.replace("Text", ""));
            }

            attachPikaday(f, hidden, f.dataset.iso || (hidden ? hidden.value : null));
          });
        });
      });
    });
    observer.observe(document.body, { childList: true, subtree: true });
  }

  /* ── Wire everything after DOM ready ─────────────────────────── */
  function init() {
    injectTheme();
    var iso = todayIso();

    // ── Pre-fill and attach to all existing date fields ──────────
    // This catches everything currently in the DOM (static or injected early)
    var selectors = [
      "#bulkCycleDateText",
      "#qfg-cycle-date-display",
      "#editPlanDate",
      "#editSuiteDate",
      "#smartTCCycleDateText",
      "#smartPlanDateText",
      "#smartPlanSuiteDateText",
      "#smartSuiteDateText",
      ".ev-date",
      ".qf-date"
    ];

    selectors.forEach(function (sel) {
      document.querySelectorAll(sel).forEach(function (el) {
        if (el && !el._pk) {
          var hidden = el.parentNode.querySelector('input[type="hidden"]') ||
            document.getElementById(el.id.replace("Text", "").replace("-display", ""));
          attachPikaday(el, hidden, el.value ? displayToIso(el.value) : iso);
        }
      });
    });

    // Start watching for new ones (like in modals or dynamic rows)
    startObserver();
  }

  // Run after DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
