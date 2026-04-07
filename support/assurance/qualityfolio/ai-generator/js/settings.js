// js/settings.js — QualityFolio Settings Page Modal Handler
// CSP-compliant: all event listeners attached programmatically, no inline handlers.
(function () {
  "use strict";

  // ── Modal Registry ──────────────────────────────────────────────────
  // Maps tab / entity names to their config:
  //   addUrl    – POST endpoint for add
  //   editUrl   – POST endpoint for edit
  //   deleteUrl – POST endpoint for delete
  //   fields    – array of field descriptors for the modal form
  const ENTITY_CONFIG = {
    team_members: {
      label: "Team Member",
      addUrl: "/pages/settings/save_team_member.sql",
      editUrl: "/pages/settings/update_team_member.sql",
      deleteUrl: "/pages/settings/delete_team_member.sql",
      fields: [
        { name: "full_name", label: "Full Name", type: "text", placeholder: "e.g. Jane Smith", required: true },
        { name: "designation", label: "Designation", type: "text", placeholder: "e.g. QA Engineer", required: false }
      ]
    },
    test_types: {
      label: "Test Type",
      addUrl: "/pages/settings/save_test_type.sql",
      editUrl: "/pages/settings/update_test_type.sql",
      deleteUrl: "/pages/settings/delete_test_type.sql",
      fields: [
        { name: "name", label: "Test Type Name", type: "text", placeholder: "e.g. Integration", required: true }
      ]
    },
    scenario_types: {
      label: "Scenario Type",
      addUrl: "/pages/settings/save_scenario_type.sql",
      editUrl: "/pages/settings/update_scenario_type.sql",
      deleteUrl: "/pages/settings/delete_scenario_type.sql",
      fields: [
        { name: "name", label: "Scenario Type Name", type: "text", placeholder: "e.g. Happy Path", required: true }
      ]
    },
    execution_types: {
      label: "Execution Type",
      addUrl: "/pages/settings/save_execution_type.sql",
      editUrl: "/pages/settings/update_execution_type.sql",
      deleteUrl: "/pages/settings/delete_execution_type.sql",
      fields: [
        { name: "name", label: "Execution Type Name", type: "text", placeholder: "e.g. Automated", required: true }
      ]
    },
    tags: {
      label: "Tag",
      addUrl: "/pages/settings/save_tag.sql",
      editUrl: "/pages/settings/update_tag.sql",
      deleteUrl: "/pages/settings/delete_tag.sql",
      fields: [
        { name: "name", label: "Tag Name", type: "text", placeholder: "e.g. Regression", required: true }
      ]
    },
    test_case_statuses: {
      label: "Status",
      addUrl: "/pages/test_cases/save_status.sql",
      editUrl: "/pages/test_cases/update_status.sql",
      deleteUrl: "/pages/test_cases/delete_status.sql",
      fields: [
        { name: "name", label: "Status Name", type: "text", placeholder: "e.g. Passed", required: true }
      ]
    },
    markdown_paths: {
      label: "Markdown Path",
      addUrl: "/pages/settings/save_markdown_path.sql",
      editUrl: "/pages/settings/update_markdown_path.sql",
      deleteUrl: "/pages/settings/delete_markdown_path.sql",
      fields: [
        { name: "path_name", label: "Configuration Name", type: "text", placeholder: "e.g. Production", required: true },
        { name: "path_type", label: "Path Type", type: "select", placeholder: "Select type", required: true, options: ["local", "project", "remote"] },
        { name: "destination_path", label: "Destination Path", type: "text", placeholder: "e.g. /home/user/markdown or ./docs/markdown", required: true },
        { name: "is_default", label: "Set as Default", type: "checkbox", required: false }
      ]
    }
  };

  // ── Helpers ─────────────────────────────────────────────────────────
  function esc(str) {
    return String(str || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function getEntityType() {
    const params = new URLSearchParams(window.location.search);
    return params.get("tab") || "team_members";
  }

  // ── Modal Infrastructure ─────────────────────────────────────────────
  function createModals() {
    if (document.getElementById("cfg-modal-overlay")) return; // already created

    const overlay = document.createElement("div");
    overlay.id = "cfg-modal-overlay";
    overlay.innerHTML = `
      <style>
        #cfg-modal-overlay {
          display: none; position: fixed; inset: 0; z-index: 9999;
          background: rgba(15,23,42,0.45); backdrop-filter: blur(2px);
          align-items: center; justify-content: center;
        }
        #cfg-modal-overlay.open { display: flex; animation: cfgFadeIn 0.18s ease; }
        @keyframes cfgFadeIn { from { opacity: 0; } to { opacity: 1; } }

        .cfg-modal {
          background: #fff; border-radius: 14px; box-shadow: 0 20px 60px rgba(0,0,0,0.18);
          width: 100%; max-width: 480px; margin: 16px;
          animation: cfgSlideUp 0.2s ease;
          overflow: hidden;
        }
        @keyframes cfgSlideUp { from { transform: translateY(24px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }

        .cfg-modal-header {
          display: flex; align-items: center; justify-content: space-between;
          padding: 18px 22px 14px; border-bottom: 1.5px solid #e2e8f0;
          background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
        }
        .cfg-modal-header h3 { font-size: 1rem; font-weight: 700; color: #0f172a; margin: 0; }
        .cfg-modal-close {
          background: none; border: none; cursor: pointer; color: #64748b;
          font-size: 1.25rem; line-height: 1; padding: 2px 6px; border-radius: 6px;
          transition: all 0.15s;
        }
        .cfg-modal-close:hover { background: #f1f5f9; color: #0f172a; }

        .cfg-modal-body { padding: 22px; max-height: 60vh; overflow-y: auto; }
        .cfg-modal-body .cfg-field { margin-bottom: 16px; }
        .cfg-modal-body .cfg-field:last-child { margin-bottom: 0; }
        .cfg-modal-body .cfg-field label {
          display: block; font-size: 0.875rem; font-weight: 600;
          color: #0f172a; margin-bottom: 7px;
        }
        .cfg-modal-body .cfg-field .req { color: #ef4444; font-weight: 700; margin-left: 3px; }
        .cfg-modal-body .cfg-field input,
        .cfg-modal-body .cfg-field select {
          width: 100%; border: 1.5px solid #e2e8f0; border-radius: 10px;
          padding: 10px 14px; font-size: 0.9375rem; color: #0f172a;
          background: #f8fafc; font-family: inherit; transition: all 0.2s;
          box-sizing: border-box;
        }
        .cfg-modal-body .cfg-field input:focus,
        .cfg-modal-body .cfg-field select:focus {
          outline: none; border-color: #2563eb; background: #fff;
          box-shadow: 0 0 0 4px rgba(37,99,235,0.1);
        }
        .cfg-modal-body .cfg-field input[type="checkbox"] {
          width: auto; margin-right: 8px;
        }
        .cfg-modal-body .cfg-field.checkbox-field {
          display: flex; align-items: center; margin-top: 4px;
        }
        .cfg-modal-body .cfg-field.checkbox-field label {
          margin-bottom: 0; margin-left: 6px;
        }

        .cfg-modal-footer {
          display: flex; justify-content: flex-end; gap: 10px;
          padding: 14px 22px 18px; border-top: 1.5px solid #e2e8f0;
          background: #f8fafc;
        }
        .cfg-modal-btn-cancel {
          background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0;
          border-radius: 8px; padding: 9px 18px; font-size: 0.875rem;
          font-weight: 600; cursor: pointer; transition: all 0.15s;
        }
        .cfg-modal-btn-cancel:hover { background: #e2e8f0; }
        .cfg-modal-btn-save {
          background: #2563eb; color: #fff; border: none;
          border-radius: 8px; padding: 9px 20px; font-size: 0.875rem;
          font-weight: 700; cursor: pointer; transition: all 0.15s;
          display: inline-flex; align-items: center; gap: 7px;
        }
        .cfg-modal-btn-save:hover { background: #1d4ed8; transform: translateY(-1px); }

        /* Delete confirmation modal */
        .cfg-modal-del-icon {
          width: 52px; height: 52px; border-radius: 50%;
          background: #fee2e2; display: flex; align-items: center; justify-content: center;
          margin: 0 auto 16px; font-size: 1.5rem;
        }
        .cfg-modal-del-msg { text-align: center; color: #475569; font-size: 0.9rem; line-height: 1.6; }
        .cfg-modal-del-msg strong { color: #0f172a; }
        .cfg-modal-btn-del {
          background: #ef4444; color: #fff; border: none;
          border-radius: 8px; padding: 9px 20px; font-size: 0.875rem;
          font-weight: 700; cursor: pointer; transition: all 0.15s;
          display: inline-flex; align-items: center; gap: 7px;
        }
        .cfg-modal-btn-del:hover { background: #dc2626; transform: translateY(-1px); }
      </style>

      <!-- Add / Edit Modal -->
      <div class="cfg-modal" id="cfg-edit-modal" style="display:none">
        <div class="cfg-modal-header">
          <h3 id="cfg-edit-modal-title">Edit</h3>
          <button class="cfg-modal-close" id="cfg-edit-modal-close" title="Close">&times;</button>
        </div>
        <form id="cfg-edit-form" method="POST">
          <input type="hidden" name="edit_id" id="cfg-edit-id" />
          <div class="cfg-modal-body" id="cfg-edit-modal-body"></div>
          <div class="cfg-modal-footer">
            <button type="button" class="cfg-modal-btn-cancel" id="cfg-edit-modal-cancel">Cancel</button>
            <button type="submit" class="cfg-modal-btn-save btn btn-primary">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg> <span id="cfg-edit-modal-save-lbl">Save Changes</span>
            </button>
          </div>
        </form>
      </div>

      <!-- Delete Confirmation Modal -->
      <div class="cfg-modal" id="cfg-del-modal" style="display:none">
        <div class="cfg-modal-header">
          <h3>Delete Item</h3>
          <button class="cfg-modal-close" id="cfg-del-modal-close" title="Close">&times;</button>
        </div>
        <form id="cfg-del-form" method="POST" style="display:flex;flex-direction:column">
          <input type="hidden" name="delete_id" id="cfg-del-id" />
          <div class="cfg-modal-body">
            <div class="cfg-modal-del-icon">⚠️</div>
            <div class="cfg-modal-del-msg" id="cfg-del-modal-msg"></div>
          </div>
          <div class="cfg-modal-footer">
            <button type="button" class="cfg-modal-btn-cancel" id="cfg-del-modal-cancel">Cancel</button>
            <button type="submit" class="cfg-modal-btn-del">
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg> Delete
            </button>
          </div>
        </form>
      </div>
    `;

    document.body.appendChild(overlay);

    // ── Close handlers ──────────────────────────────────────────────
    function closeAll() {
      overlay.classList.remove("open");
      document.getElementById("cfg-edit-modal").style.display = "none";
      document.getElementById("cfg-del-modal").style.display = "none";
    }

    document.getElementById("cfg-edit-modal-close").addEventListener("click", closeAll);
    document.getElementById("cfg-edit-modal-cancel").addEventListener("click", closeAll);
    document.getElementById("cfg-del-modal-close").addEventListener("click", closeAll);
    document.getElementById("cfg-del-modal-cancel").addEventListener("click", closeAll);

    overlay.addEventListener("click", function (e) {
      if (e.target === overlay) closeAll();
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") closeAll();
    });
  }

  // ── Open Add Modal ───────────────────────────────────────────────────
  function openAddModal(entityType) {
    const cfg = ENTITY_CONFIG[entityType];
    if (!cfg) return;

    const overlay = document.getElementById("cfg-modal-overlay");
    const editModal = document.getElementById("cfg-edit-modal");
    const delModal = document.getElementById("cfg-del-modal");
    const form = document.getElementById("cfg-edit-form");
    const body = document.getElementById("cfg-edit-modal-body");
    const title = document.getElementById("cfg-edit-modal-title");
    const saveLbl = document.getElementById("cfg-edit-modal-save-lbl");
    const idInput = document.getElementById("cfg-edit-id");

    title.textContent = "Add " + cfg.label;
    saveLbl.textContent = "Add " + cfg.label;
    form.action = cfg.addUrl;
    idInput.value = "";
    idInput.name = ""; // don't send id for new records

    body.innerHTML = cfg.fields.map(f => {
      if (f.type === "checkbox") {
        return `
          <div class="cfg-field checkbox-field">
            <input type="checkbox" id="${esc(f.name)}" name="${esc(f.name)}" />
            <label for="${esc(f.name)}">${esc(f.label)}</label>
          </div>
        `;
      } else if (f.type === "select") {
        return `
          <div class="cfg-field">
            <label>${esc(f.label)}${f.required ? '<span class="req">*</span>' : ''}</label>
            <select name="${esc(f.name)}" ${f.required ? "required" : ""}>
              <option value="">-- Select ${esc(f.label)} --</option>
              ${(f.options || []).map(opt => `<option value="${esc(opt)}">${esc(opt)}</option>`).join('')}
            </select>
          </div>
        `;
      } else {
        return `
          <div class="cfg-field">
            <label>${esc(f.label)}${f.required ? '<span class="req">*</span>' : ''}</label>
            <input type="${esc(f.type)}" name="${esc(f.name)}" placeholder="${esc(f.placeholder)}"
                   ${f.required ? "required" : ""} autocomplete="off" />
          </div>
        `;
      }
    }).join("");

    delModal.style.display = "none";
    editModal.style.display = "block";
    overlay.classList.add("open");

    // Focus first input
    const first = body.querySelector("input, select");
    if (first) setTimeout(() => first.focus(), 80);
  }

  // ── Open Edit Modal ──────────────────────────────────────────────────
  function openEditModal(entityType, id, currentData) {
    const cfg = ENTITY_CONFIG[entityType];
    if (!cfg) return;

    const overlay = document.getElementById("cfg-modal-overlay");
    const editModal = document.getElementById("cfg-edit-modal");
    const delModal = document.getElementById("cfg-del-modal");
    const form = document.getElementById("cfg-edit-form");
    const body = document.getElementById("cfg-edit-modal-body");
    const title = document.getElementById("cfg-edit-modal-title");
    const saveLbl = document.getElementById("cfg-edit-modal-save-lbl");
    const idInput = document.getElementById("cfg-edit-id");

    title.textContent = "Edit " + cfg.label;
    saveLbl.textContent = "Save Changes";
    form.action = cfg.editUrl;
    idInput.name = "edit_id";
    idInput.value = id;

    body.innerHTML = cfg.fields.map(f => {
      const value = currentData[f.name] || '';
      if (f.type === "checkbox") {
        const checked = value === '1' || value === 'true' || value === true ? "checked" : "";
        return `
          <div class="cfg-field checkbox-field">
            <input type="checkbox" id="${esc(f.name)}" name="${esc(f.name)}" ${checked} />
            <label for="${esc(f.name)}">${esc(f.label)}</label>
          </div>
        `;
      } else if (f.type === "select") {
        return `
          <div class="cfg-field">
            <label>${esc(f.label)}${f.required ? '<span class="req">*</span>' : ''}</label>
            <select name="${esc(f.name)}" ${f.required ? "required" : ""}>
              <option value="">-- Select ${esc(f.label)} --</option>
              ${(f.options || []).map(opt => `<option value="${esc(opt)}" ${opt === value ? 'selected' : ''}>${esc(opt)}</option>`).join('')}
            </select>
          </div>
        `;
      } else {
        return `
          <div class="cfg-field">
            <label>${esc(f.label)}${f.required ? '<span class="req">*</span>' : ''}</label>
            <input type="${esc(f.type)}" name="${esc(f.name)}" placeholder="${esc(f.placeholder)}"
                   value="${esc(value)}"
                   ${f.required ? "required" : ""} autocomplete="off" />
          </div>
        `;
      }
    }).join("");

    delModal.style.display = "none";
    editModal.style.display = "block";
    overlay.classList.add("open");

    const first = body.querySelector("input, select");
    if (first) setTimeout(() => first.focus(), 80);
  }

  // ── Open Delete Confirmation Modal ───────────────────────────────────
  function openDeleteModal(entityType, id, itemName) {
    const cfg = ENTITY_CONFIG[entityType];
    if (!cfg) return;

    const overlay = document.getElementById("cfg-modal-overlay");
    const editModal = document.getElementById("cfg-edit-modal");
    const delModal = document.getElementById("cfg-del-modal");
    const delForm = document.getElementById("cfg-del-form");
    const delIdInp = document.getElementById("cfg-del-id");
    const delMsg = document.getElementById("cfg-del-modal-msg");

    delForm.action = cfg.deleteUrl;
    delIdInp.value = id;
    delMsg.innerHTML = `Are you sure you want to delete<br><strong>${esc(itemName)}</strong>?<br><span style="font-size:0.82rem;color:#ef4444;margin-top:6px;display:inline-block;">This action cannot be undone.</span>`;

    editModal.style.display = "none";
    delModal.style.display = "block";
    overlay.classList.add("open");
  }

  // ── Wire up "Add" buttons on the page ───────────────────────────────
  function wireAddButtons() {
    document.querySelectorAll("[data-action='addMember']").forEach(btn => {
      btn.addEventListener("click", function () {
        const entity = this.dataset.entity || getEntityType();
        openAddModal(entity);
      });
    });
  }

  // ── Event Delegation for Edit / Delete ──────────────────────────────
  function wireTableActions() {
    document.addEventListener("click", function (e) {
      // Edit button
      const editBtn = e.target.closest("[data-action='editMember']");
      if (editBtn) {
        e.preventDefault();
        const entity = editBtn.dataset.entity || getEntityType();
        const id = editBtn.dataset.id;
        // Build currentData from sibling cells
        const row = editBtn.closest("tr");
        const data = {};
        if (row) {
          // Read data-* attributes set by the SQL on the button itself as the primary source
          Object.keys(editBtn.dataset).forEach(k => {
            if (k !== "action" && k !== "entity" && k !== "id") {
              data[k] = editBtn.dataset[k];
            }
          });
          // Fallback: read named cells from the row
          row.querySelectorAll("td[data-field]").forEach(td => {
            data[td.dataset.field] = td.dataset.value || td.textContent.trim();
          });
        }
        openEditModal(entity, id, data);
        return;
      }

      // Delete buttons are now plain <a> links pointing to each entity's
      // SQLPage confirmation page (delete_*.sql?id=X). No JS interception needed.
    });
  }

  // ── Table filter (programmatic attachment for CSP compliance) ────
  window.filterTable = function (input, tableId) {
    const q = input.value.toLowerCase();
    const rows = document.getElementById(tableId).querySelectorAll("tbody tr");
    rows.forEach(row => {
      row.style.display = row.textContent.toLowerCase().includes(q) ? "" : "none";
    });
  };

  // ── Attach search filter listeners programmatically ──────────────
  function attachSearchFilters() {
    document.querySelectorAll('.cfg-table-search').forEach(input => {
      input.addEventListener('input', function () {
        const tableId = this.closest('.cfg-table-wrap').querySelector('table').id;
        filterTable(this, tableId);
      });
    });
  }

  // ── Public API ────────────────────────────────────────────────────────
  window.CFGSettings = {
    openAddModal,
    openEditModal,
    openDeleteModal
  };

  // ── Boot ──────────────────────────────────────────────────────────────
  function init() {
    createModals();
    wireAddButtons();
    wireTableActions();
    attachSearchFilters();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();