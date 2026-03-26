// results.js - Logic for the Results Page

// Global state
var generatedTestCases = null;
// assigneeMaster is declared in main.js; guard for SQLPage context (no main.js)
if (typeof assigneeMaster === "undefined") {
  var assigneeMaster = [];
}
var currentUser = "Rahul Raj"; // Default fallback

// Elements cache
var elements = {
  totalTestCases: document.getElementById("totalTestCases"),
  generationTime: document.getElementById("generationTime"),
  testCasesPreview: document.getElementById("testCasesPreview"),
  treeViewContent: document.getElementById("treeViewContent"),
  markdownContent: document.getElementById("markdownContent"),
  jsonContent: document.getElementById("jsonContent"),
  downloadBtn: document.getElementById("downloadBtn"),
  saveDbBtn: document.getElementById("saveDbBtn"),
  // Bulk actions
  selectAllTcs: document.getElementById("selectAllTcs"),
  selectedCountText: document.getElementById("selectedCountText"),
  bulkAssignSelect: document.getElementById("bulkAssignSelect"),
  bulkPrioritySelect: document.getElementById("bulkPrioritySelect"),
  applyBulkActions: document.getElementById("applyBulkActions"),
  resetBulkActions: document.getElementById("resetBulkActions"),
  // Bulk Props
  bulkScenarioType: document.getElementById("bulkScenarioType"),
  bulkExecutionType: document.getElementById("bulkExecutionType"),
  bulkTags: document.getElementById("bulkTags"),
  applyBulkProps: document.getElementById("applyBulkProps"),
  // Cycle
  bulkCycleName: document.getElementById("bulkCycleName"),
  bulkCycleDate: document.getElementById("bulkCycleDate"),
  bulkCycleAssignee: document.getElementById("bulkCycleAssignee"),
  bulkCycleStatus: document.getElementById("bulkCycleStatus"),
  applyBulkCycle: document.getElementById("applyBulkCycle"),
  // Bulk Edit Modal
  bulkEditBtn: document.getElementById("bulkEditBtn"),
  bulkEditModal: document.getElementById("bulkEditModal"),
  closeBulkEdit: document.getElementById("closeBulkEdit"),
  cancelBulkEdit: document.getElementById("cancelBulkEdit"),
  saveBulkEdit: document.getElementById("saveBulkEdit"),
  bulkEditTagsSelect: document.getElementById("bulkEditTagsSelect"),
  bulkDeleteBtn: document.getElementById("bulkDeleteBtn"),
};

// Initialize
async function initResults() {
  loadSettings();
  loadResults();
  setupEventListeners();
  setupInputSync();
  setupDateInputSync();

  // Restore download folder handle
  if (window.QF && window.QF.loadHandleFromDB) {
    const handle = await window.QF.loadHandleFromDB();
    if (handle) {
      window.globalDirectoryHandle = handle;
      console.log("Restored download folder in Results:", handle.name);
    }
  }
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initResults);
} else {
  initResults();
}

function loadSettings() {
  // Master Data Sync
  const masters = [
    {
      win: "assigneeMaster",
      local: "qf_assignee_master",
      target: "assigneeMaster",
    },
    {
      win: "scenarioMaster",
      local: "qf_scenario_types_master",
      target: "scenarioMaster",
    },
    {
      win: "executionMaster",
      local: "qf_execution_types_master",
      target: "executionMaster",
    },
    { win: "statusMaster", local: "qf_status_master", target: "statusMaster" },
  ];

  masters.forEach((m) => {
    if (
      typeof window[m.win] !== "undefined" &&
      Array.isArray(window[m.win]) &&
      window[m.win].length > 0
    ) {
      window[m.target] = window[m.win];
      localStorage.setItem(m.local, JSON.stringify(window[m.win]));
    } else {
      const stored = localStorage.getItem(m.local);
      if (stored) {
        window[m.target] = JSON.parse(stored);
      } else if (
        typeof window[m.target] === "undefined" ||
        !Array.isArray(window[m.target])
      ) {
        window[m.target] = [];
      }
    }
  });

  // Global assignments for convenience if not already handled by window
  if (typeof assigneeMaster === "undefined")
    window.assigneeMaster = window.assigneeMaster || [];

  // Populate all dropdowns
  populateAssigneeDropdowns();
  populateMasterDropdowns();
  populateStatusDropdowns();

  // Default Cycle Settings
  const systemSettings = JSON.parse(localStorage.getItem("qf_system_settings"));
  if (systemSettings) {
    if (systemSettings.defaultCycle && elements.bulkCycleName) {
      elements.bulkCycleName.value = systemSettings.defaultCycle;
    }
  }
}

function populateAssigneeDropdowns() {
  const options = assigneeMaster
    .map((user) => {
      const name = typeof user === "string" ? user : user.name;
      // const desig = typeof user === 'string' ? '' : ` (${user.designation})`;
      return `<option value="${name}">${name}</option>`;
    })
    .join("");

  if (elements.bulkAssignSelect) {
    elements.bulkAssignSelect.innerHTML =
      '<option value="">-- Assignee --</option>' + options;
  }
  if (elements.bulkCycleAssignee) {
    elements.bulkCycleAssignee.innerHTML =
      '<option value="">-- Assignee --</option>' + options;
  }
  const bulkEditAssignee = document.getElementById("bulkEditAssignee");
  if (bulkEditAssignee) {
    bulkEditAssignee.innerHTML =
      '<option value="">-- No Change --</option>' + options;
  }
  // Also handle editPlanCreatedBy and editSuiteCreatedBy
  const planCreatedBy = document.getElementById("editPlanCreatedBy");
  if (planCreatedBy)
    planCreatedBy.innerHTML =
      '<option value="">-- Creator --</option>' + options;
  const suiteCreatedBy = document.getElementById("editSuiteCreatedBy");
  if (suiteCreatedBy)
    suiteCreatedBy.innerHTML =
      '<option value="">-- Creator --</option>' + options;
}

function populateStatusDropdowns() {
  const statuses = window.statusMaster || [
    "To-do",
    "In-progress",
    "Passed",
    "Failed",
    "Blocked",
  ];
  const options = statuses
    .map((s) => `<option value="${s}">${s}</option>`)
    .join("");

  if (elements.bulkCycleStatus) {
    elements.bulkCycleStatus.innerHTML =
      '<option value="">-- Choose Status --</option>' + options;
  }
}

function populateMasterDropdowns() {
  // Scenarios
  const scenarios = window.scenarioMaster || [
    "Happy Path",
    "Negative",
    "Boundary",
    "Security",
    "Performance",
  ];
  const scenarioOpts = scenarios
    .map((s) => `<option value="${s}">${s}</option>`)
    .join("");

  // Executions
  const executions = window.executionMaster || ["Manual", "Automated"];
  const executionOpts = executions
    .map((e) => `<option value="${e}">${e}</option>`)
    .join("");

  // Tags
  let tagsList = JSON.parse(localStorage.getItem("qf_tags_master"));
  if (!Array.isArray(tagsList))
    tagsList = ["Functional", "Regression", "Smoke", "UI", "API"];
  const tagsOpts = tagsList
    .map((t) => `<option value="${t}">${t}</option>`)
    .join("");

  // Update UI elements - Edit Modal
  const editScenario =
    document.getElementById("editTcScenarioTypeSelect") ||
    document.getElementById("editTcScenarioType");
  const editExec =
    document.getElementById("editTcExecutionTypeSelect") ||
    document.getElementById("editTcExecutionType");
  const editTagsSelect = document.getElementById("editTcTagsSelect");

  if (editScenario)
    editScenario.innerHTML = '<option value="">Select</option>' + scenarioOpts;
  if (editExec)
    editExec.innerHTML = '<option value="">Select</option>' + executionOpts;
  if (editTagsSelect)
    editTagsSelect.innerHTML = '<option value="">+ Add Tag</option>' + tagsOpts;

  // Update UI elements - Bulk Toolbar
  const bulkScenario =
    document.getElementById("bulkScenarioTypeSelect") ||
    document.getElementById("bulkScenarioType");
  const bulkExec =
    document.getElementById("bulkExecutionTypeSelect") ||
    document.getElementById("bulkExecutionType");
  const bulkTagsSelect = document.getElementById("bulkTagsSelect");

  if (bulkScenario)
    bulkScenario.innerHTML =
      '<option value="">-- Scenario Type --</option>' + scenarioOpts;
  if (bulkExec)
    bulkExec.innerHTML =
      '<option value="">-- Exec Type --</option>' + executionOpts;
  if (bulkTagsSelect)
    bulkTagsSelect.innerHTML = '<option value="">+</option>' + tagsOpts;

  // Bulk Edit Modal
  const beScenario =
    document.getElementById("bulkEditScenarioTypeSelect") ||
    document.getElementById("bulkEditScenarioType");
  const beExec =
    document.getElementById("bulkEditExecutionTypeSelect") ||
    document.getElementById("bulkEditExecutionType");
  const beTagsSelect = document.getElementById("bulkEditTagsSelect");

  if (beScenario)
    beScenario.innerHTML =
      '<option value="">-- No Change --</option>' + scenarioOpts;
  if (beExec)
    beExec.innerHTML =
      '<option value="">-- No Change --</option>' + executionOpts;
  if (beTagsSelect)
    beTagsSelect.innerHTML = '<option value="">+ Add Tag</option>' + tagsOpts;
}

function loadResults() {
  const storedData = localStorage.getItem("qf_generated_test_cases");

  // STRICT CHECK: Only auto-load from localStorage if we are effectively on the Results page.
  // On md-editor, we rely on the editor logic to populate generatedTestCases.
  if (!window.location.pathname.includes("/results")) {
    return;
  }

  if (!storedData) {
    // Redirect back to generator if no data
    alert("No generated results found. Redirecting to generator...");
    window.location.href = "/generator";
    return;
  }

  try {
    const rawData = JSON.parse(storedData);
    // Normalize data structure to support Vanilla formats
    generatedTestCases = normalizeData(rawData);

    console.log("Loaded & Normalized results:", generatedTestCases);

    // Enhance with "AI" Descriptions if missing
    ensureDescriptions(generatedTestCases);

    // Calculate total if missing
    calculateTotals();

    // Render
    updateStats();
    renderTestCasesList();
    renderTreeView();
    updateExports();
  } catch (e) {
    console.error("Error loading results:", e);
    // Alert removed as per user feedback - results load anyway
    // alert('Error loading results data');
  }
}

function normalizeData(data) {
  let normalized = data;

  // Level 6: Ensure strategies have evidence
  if (data.schemaLevel === "6" && data.strategies) {
    // No structural normalization needed if it's already Level 6
  } else if (data.schemaLevel === "3" && data.testCases) {
    // Normalize Level 3 to Plans -> Suites -> TCs
    normalized = {
      ...data,
      plans: [
        {
          planName: data.projectName,
          planId: "PROJ-001",
          suites: [
            {
              suiteName: "Main Suite",
              suiteId: "SUITE-001",
              testCases: data.testCases,
            },
          ],
        },
      ],
    };
  } else if (data.schemaLevel === "4" && data.suites) {
    // Normalize Level 4 to Plans -> Suites
    normalized = {
      ...data,
      plans: [
        {
          planName: data.projectName,
          planId: "PROJ-001",
          suites: data.suites,
        },
      ],
    };
  } else {
    // 5-level or fallback
    if (!normalized.plans) normalized.plans = [];
  }

  // Recursive helper to ensure every TC has default evidence
  const addDefaultEvidence = (item) => {
    if (item.testCases) {
      item.testCases.forEach((tc) => {
        if (!tc.evidenceHistory || tc.evidenceHistory.length === 0) {
          tc.evidenceHistory = [
            {
              cycle: "1.0",
              cycleDate: new Date().toISOString().split("T")[0],
              status: "To-do",
              assignee: tc.assignee || "Unassigned",
              attachments: getDefaultAttachments(tc.testCaseId || tc.id, "1.0"),
            },
          ];
        } else {
          // Ensure existing evidence has defaults if empty
          tc.evidenceHistory.forEach((ev) => {
            if (!ev.attachments) {
              ev.attachments = getDefaultAttachments(
                tc.testCaseId || tc.id,
                ev.cycle || "1.0",
              );
            }
          });
        }
      });
    }
    if (item.suites) {
      item.suites.forEach((s) => addDefaultEvidence(s));
    }
    if (item.plans) {
      item.plans.forEach((p) => addDefaultEvidence(p));
    }
    if (item.strategies) {
      item.strategies.forEach((st) => addDefaultEvidence(st));
    }
  };

  // Apply key based on level
  if (normalized.strategies) {
    normalized.strategies.forEach((st) => addDefaultEvidence(st));
  } else if (normalized.plans) {
    normalized.plans.forEach((p) => addDefaultEvidence(p));
  }

  return normalized;
}

// ===== AI Description Generator (Rule-Based Simulation) =====
function generateAiDescription(item, type) {
  const name = (item.planName || item.suiteName || "Untitled").replace(
    /-/g,
    " ",
  );

  if (type === "plan") {
    return `**Objectives**

- Validate UX and UI consistency for **${name}**.
- Ensure functionality, reliability, and performance.
- Capture evidence across defined cycles.

**Risks**

- Potential regression in **${name}** workflows.
- Integration issues with dependent modules.
- User experience inconsistencies.

**Cycle Goals**

- Confirm all high-priority scenarios are passed.
- Validate recent fixes and patches.
- Ensure consistent behavior across all environments.`;
  }

  // Fallback for non-plan types or error cases
  return `Standard description for ${name}.`;
}

// Advanced Scope Generator for Suites
function generateAiSuiteScope(suite) {
  const name = suite.suiteName || "Untitled Suite";
  let scope = `**Scope**\n\nThis suite covers **all validation areas for ${name}**, including:\n\n`;

  // Add generic bullet points based on context
  if (
    name.toLowerCase().includes("validation") ||
    name.toLowerCase().includes("suite")
  ) {
    scope += `- Functional validation of core components.\n`;
    scope += `- Error handling and edge case verification.\n`;
    scope += `- UI/UX consistency checks.\n`;
  } else {
    scope += `- Comprehensive verification of functionality.\n`;
    scope += `- Data integrity and interaction flows.\n`;
  }

  // Dynamic Test Case List
  if (suite.testCases && suite.testCases.length > 0) {
    scope += `\n**Test Cases**\n\n`;
    suite.testCases.forEach((tc) => {
      const id = tc.testCaseId || tc.id || "TC-XXX";
      scope += `- **${id}** – ${tc.title}\n`;
    });
  }

  return scope;
}

function ensureDescriptions(data) {
  if (!data) return;

  const processPlan = (plan) => {
    if (!plan.description || plan.description.trim() === "") {
      plan.description = generateAiDescription(plan, "plan");
    }
    if (plan.suites) {
      plan.suites.forEach((s) => {
        if (!s.description || s.description.trim() === "") {
          // Use advanced generator for Suites
          s.description = generateAiSuiteScope(s);
        }
      });
    }
  };

  // Strategies Level (Level 6)
  if (data.strategies) {
    data.strategies.forEach((st) => {
      if (st.plans) st.plans.forEach((p) => processPlan(p));
    });
  }
  // Plan Level (Level 5)
  else if (data.plans) {
    data.plans.forEach((p) => processPlan(p));
  }
}

// Helper to ensure tags are flat array of clean strings
function cleanTags(tags) {
  if (!tags) return ["Functional"];
  if (typeof tags === "string") {
    // Try parsing if it looks like JSON
    try {
      const parsed = JSON.parse(tags);
      if (Array.isArray(parsed)) tags = parsed;
      else return [tags];
    } catch (e) {
      return tags
        .split(",")
        .map((t) => t.trim())
        .filter((t) => t);
    }
  }

  if (!Array.isArray(tags)) return ["Functional"];

  // Flatten and clean
  const flat = [];
  tags.forEach((t) => {
    if (typeof t === "string") {
      // Check if string is actually stringified array
      if (t.startsWith("[") && t.endsWith("]")) {
        const inner = cleanTags(t);
        flat.push(...inner);
      } else {
        // Remove quotes if present
        flat.push(t.replace(/^"|"$/g, "").replace(/^'|'$/g, ""));
      }
    } else {
      flat.push(String(t));
    }
  });

  return [...new Set(flat.filter((t) => t && t.trim()))];
}

function getDefaultAttachments(tcId, cycle) {
  const safeId = tcId || "TC-XXX";
  const safeCycle = cycle || "1.0";
  return `- [Result JSON](./evidence/${safeId}/${safeCycle}/result.auto.json)
- [Dropdown visibility screenshot](./evidence/${safeId}/${safeCycle}/by-role-visibility.auto.png)
- [Run MD](./evidence/${safeId}/${safeCycle}/run.auto.md)`;
}

function calculateTotals() {
  if (!generatedTestCases) return 0;
  let total = 0;

  // Level 6
  if (generatedTestCases.strategies && generatedTestCases.schemaLevel === "6") {
    generatedTestCases.strategies.forEach((st) => {
      if (st.plans) {
        st.plans.forEach((p) => {
          if (p.suites) {
            p.suites.forEach((s) => {
              if (s.testCases) total += s.testCases.length;
            });
          }
        });
      }
    });
  }
  // Level 5, 4, 3 (normalized to plans)
  else if (generatedTestCases.plans) {
    generatedTestCases.plans.forEach((p) => {
      if (p.suites) {
        p.suites.forEach((s) => {
          if (s.testCases) total += s.testCases.length;
        });
      }
    });
  }
  // Level 3 (raw if not normalized)
  else if (generatedTestCases.testCases) {
    total = generatedTestCases.testCases.length;
  }

  generatedTestCases.totalTestCases = total;
  return total;
}

function updateStats() {
  const total = calculateTotals();
  const el = document.getElementById("totalTestCases");
  if (el) {
    el.innerHTML = `${total} Cases`;
  } else if (elements.totalTestCases) {
    elements.totalTestCases.textContent = `${total} Cases`;
  }
}

// ===== Rendering Logic (Styled like Vanilla App) =====

function renderTestCasesList() {
  if (!generatedTestCases || !elements.testCasesPreview) return;

  let html = "";
  let globalIndex = 0;

  // Generate Assignee Options for dropdowns
  const assignees =
    typeof assigneeMaster !== "undefined" && Array.isArray(assigneeMaster)
      ? assigneeMaster
      : [];
  const assigneeOptions = assignees
    .map((user) => {
      const name = typeof user === "string" ? user : user.name;
      return `<option value="${name}">${name}</option>`;
    })
    .join("");

  const isLevel6 = generatedTestCases.schemaLevel === "6";
  // Helper to get Plans array based on level
  const strategies = isLevel6
    ? generatedTestCases.strategies || []
    : [{ strategyName: "Default", plans: generatedTestCases.plans || [] }];

  // Display Project Info
  html += `
    <div class="project-header" style=" padding-bottom: 1rem;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <h1 style="color: #444;font-size: 0.9rem;margin: 0;">
                <i class="fas fa-project-diagram" style="margin-right: 0.5rem; color: #444;"></i>
                ${generatedTestCases.projectName}
            </h1>
            <button class="btn btn-primary btn-sm qfg-tc-btn" data-action="addPlan" data-stid="null">
                <i class="fas fa-plus"></i> Add ${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Project" : "Plan"}
            </button>
        </div>
        <div style="color: var(--text-muted); font-size: 0.8rem; margin-top: 0.5rem;">
            Schema Level: ${generatedTestCases.schemaLevel} | Generated: ${new Date().toLocaleDateString()}
        </div>
    </div>
    `;

  strategies.forEach((strategy, stIdx) => {
    const validStIdx = isLevel6 ? stIdx : null;

    if (isLevel6) {
      html += `
            <div class="strategy-preview-block" style="margin-bottom: 2.5rem; border-left: 5px solid #663399; padding-left: 1.5rem;">
                <div style="display: flex; align-items: center; justify-content: space-between;">
                    <h2 style="color: #663399; margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.5rem;">
                        <i class="fas fa-chess-knight"></i> ${strategy.strategyName}
                    </h2>
                     <!-- Add Plan Button for Strategy Level -->
                     <button class="btn btn-sm btn-outline" data-action="addPlan" data-stid="${stIdx}">
                         <i class="fas fa-plus"></i> Add ${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Project" : "Plan"}
                     </button>
                </div>
            `;
    }

    const plans = strategy.plans || [];
    plans.forEach((plan, pIdx) => {
      // Only show Plan header if it's really a multi-plan scenario or explicit 5/6-level
      const showPlanHeader =
        isLevel6 || generatedTestCases.schemaLevel === "5" || plans.length > 1;
      if (showPlanHeader) {
        html += `
                <div class="plan-preview-block" style="margin-bottom: 2rem; border-left: 4px solid var(--primary-color); padding-left: 1.5rem; ${isLevel6 ? "margin-left: 1rem;" : ""}">
                    <div style="display: flex; align-items: center; justify-content: space-between;">
                        <h3 style="color: var(--primary-color); margin-bottom: 0.5rem; display: flex; align-items: center; gap: 0.5rem;">
                            <i class="fas fa-folder-open"></i> ${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Project" : "Plan"}: ${plan.planName}
                        </h3>
                        <div>
                            <button class="btn btn-sm btn-outline" style="padding: 2px 8px; font-size: 0.75rem; margin-right: 0.5rem;" data-action="addSuite" data-stid="${validStIdx}" data-pid="${pIdx}">
                                <i class="fas fa-plus"></i> Add Suite
                            </button>
                            <button class="btn btn-sm btn-outline" style="padding: 2px 8px; font-size: 0.75rem; margin-right: 0.5rem;" data-action="editPlan" data-stid="${validStIdx}" data-pid="${pIdx}">
                                <i class="fas fa-edit"></i> Edit ${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Project" : "Plan"}
                            </button>
                            <button class="btn btn-sm btn-outline-danger qfg-tc-btn" style="padding: 2px 8px; font-size: 0.75rem;" data-action="deletePlan" data-stid="${validStIdx}" data-pid="${pIdx}">
                                <i class="fas fa-trash-can"></i> Delete ${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Project" : "Plan"}
                            </button>
                        </div>
                    </div>
                `;
      }

      plan.suites.forEach((suite, sIdx) => {
        const showSuiteHeader = generatedTestCases.schemaLevel !== "3";

        if (showSuiteHeader) {
          html += `
                    <div class="suite-preview-block" style="margin: 1.5rem 0 1rem ${showPlanHeader ? "1rem" : "0"}; border-left: 3px dashed var(--border-color); padding-left: 1rem;">
                        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem;">
                            <h4 style="color: var(--text-secondary); margin: 0; font-size: 1.1rem; display: flex; align-items: center; gap: 0.5rem;">
                                <i class="fas fa-list-check"></i> Suite: ${suite.suiteName}
                            </h4>
                            <div>
                                <button class="btn btn-sm btn-outline" style="padding: 2px 8px; font-size: 0.75rem; margin-right: 0.5rem;" data-action="addTestCase" data-stid="${validStIdx}" data-pid="${pIdx}" data-sid="${sIdx}">
                                    <i class="fas fa-plus"></i> Add Case
                                </button>
                                <button class="btn btn-sm btn-outline" style="padding: 2px 8px; font-size: 0.75rem; margin-right: 0.5rem;" data-action="editSuite" data-stid="${validStIdx}" data-pid="${pIdx}" data-sid="${sIdx}">
                                    <i class="fas fa-edit"></i> Edit Suite
                                </button>
                                <button class="btn btn-sm btn-outline-danger qfg-tc-btn" style="padding: 2px 8px; font-size: 0.75rem;" data-action="deleteSuite" data-stid="${validStIdx}" data-pid="${pIdx}" data-sid="${sIdx}">
                                    <i class="fas fa-trash-can"></i> Delete Suite
                                </button>
                            </div>
                        </div>
                    `;
        }


        html += `<div class="tc-list">`;

        suite.testCases.forEach((tc, tIdx) => {
          const tcId =
            tc.testCaseId ||
            tc.id ||
            (tc.requirementId ? tc.requirementId : "");

          // Robust Assignee lookup: check history first, then tc.assignee, then tc.createdBy
          const currentAssignee =
            tc.evidenceHistory && tc.evidenceHistory.length > 0
              ? tc.evidenceHistory[0].assignee ||
              tc.evidenceHistory[0].executedBy ||
              tc.assignee ||
              "Unassigned"
              : tc.assignee || tc.createdBy || "Unassigned";

          const priority = tc.priority || "Medium";

          // stIdx param handling: if null, pass special value or 'null' (but passed as arg)
          // We output explicit 'null' for JS if not Level 6
          const stIdxArg = isLevel6 ? stIdx : "null";

          html += `
                    <div class="tc-card">
                        <div>
                            <input type="checkbox" class="tc-checkbox" 
                                data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}"
                                style="accent-color: var(--primary-color); cursor: pointer;">
                        </div>
                        <div style="flex: 1; display: flex; flex-direction: column; gap: 0.5rem;">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <h5>${tc.title || "Untitled Test Case"}</h5>
                            </div>
                            
                            <div style="display: flex; gap: 1.5rem; align-items: center; background: #fafafa; padding: 8px 12px; border-radius: 8px; border: 1px solid #f1f5f9;">
                                <div style="display: flex; gap: 0.65rem; flex-shrink: 0;">
                                    <button class="btn btn-sm btn-edit-action" style="padding: 0.5rem !important;" data-action="editTestCase" data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                                    </button>
                                    <button class="btn btn-sm btn-delete-action" style="padding: 0.5rem !important;" data-action="deleteTestCase" data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}">
                                    <svg xmlns="http://www.w3.org/2000/svg" width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
                                    </button>
                                </div>
                                <div style="height: 20px; width: 1px; background: #e2e8f0;"></div>
                                <div> 
                                <span style="color: var(--text-muted); font-size: 0.8rem; font-family: monospace; background: #d8e2ec; padding: 2px 8px; border-radius: 4px;">${tcId && tcId !== "undefined" ? tcId : "NO-ID"}</span>
                                </div>
                                <div style="flex: 1;"></div> <!-- Spacer -->
                                <div style="display: flex; align-items: center; gap: 0.75rem;">

                                    <label style="font-size: 0.65rem; color: #64748b; text-transform: uppercase; font-weight: 800; letter-spacing: 0.05em;">Priority</label>
                                    <select class="form-input priority-selector priority-${priority.toLowerCase()}" 
                                        data-action="quickPriority" data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}">
                                        <option value="Critical" ${priority === "Critical" ? "selected" : ""}>Critical</option>
                                        <option value="High" ${priority === "High" ? "selected" : ""}>High</option>
                                        <option value="Medium" ${priority === "Medium" ? "selected" : ""}>Medium</option>
                                        <option value="Low" ${priority === "Low" ? "selected" : ""}>Low</option>
                                    </select>
                                </div>
                                
                                <div style="display: flex; align-items: center; gap: 0.75rem;">
                                    <label style="font-size: 0.65rem; color: #64748b; text-transform: uppercase; font-weight: 800; letter-spacing: 0.05em;">Assignee</label>
                                    <select class="form-input"
                                        data-action="quickAssign" data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}">
                                        <option value="Unassigned" ${currentAssignee === "Unassigned" || !currentAssignee ? "selected" : ""}>-- Unassigned --</option>
                                        ${assigneeOptions.includes(
            `value="${currentAssignee}"`,
          )
              ? assigneeOptions.replace(
                `value="${currentAssignee}"`,
                `value="${currentAssignee}" selected`,
              )
              : assigneeOptions +
              `<option value="${currentAssignee}" selected>${currentAssignee}</option>`
            }
                                    </select>
                                </div>
                            </div>
                        </div>
                    </div>`;

          globalIndex++;
        });

        html += `</div>`;

        if (showSuiteHeader) {
          html += `</div>`;
        }
      });

      if (showPlanHeader) {
        html += `</div>`;
      }
    });

    if (isLevel6) {
      html += `</div>`; // Close Strategy
    }
  });

  elements.testCasesPreview.innerHTML = html;

  // Re-attach listeners based on data attributes
  document.querySelectorAll(".tc-checkbox").forEach((cb) => {
    cb.addEventListener("change", updateSelectedCount);
  });
}

function renderTreeView() {
  if (!generatedTestCases || !elements.treeViewContent) return;

  let html = "";
  const isLevel3 = generatedTestCases.schemaLevel === "3";
  const isLevel6 = generatedTestCases.schemaLevel === "6";

  const strategies = isLevel6
    ? generatedTestCases.strategies
    : [{ strategyName: "Default", plans: generatedTestCases.plans }];

  strategies.forEach((strategy, stIdx) => {
    const validStIdx = isLevel6 ? stIdx : null;
    const stIdxArg = isLevel6 ? stIdx : "null";

    if (isLevel6) {
      html += `
            <div class="tree-node open">
                <div class="tree-header">
                     <span data-action="toggleTree" style="display:flex; align-items:center; flex:1; cursor:pointer;">
                        <i class="fas fa-chess-knight" style="color: #663399;"></i> ${strategy.strategyName}
                     </span>
                </div>
                <div class="tree-children">`;
    }

    (strategy.plans || []).forEach((plan, pIdx) => {
      html += `
            <div class="tree-node open">
                <div class="tree-header">
                     <span data-action="toggleTree" style="display:flex; align-items:center; flex:1; cursor:pointer;">
                        <i class="fas fa-folder"></i> ${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Project" : "Plan"}: ${plan.planName}
                     </span>
                     <div class="tree-actions" style="display: flex; gap: 0.5rem; flex-shrink: 0;">
                         <span style="font-size: 0.75rem; color: var(--primary-color); cursor: pointer;" data-action="editPlan" data-stid="${validStIdx}" data-pid="${pIdx}">${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Edit" : "Edit Plan"}</span>
                         <span style="font-size: 0.75rem; color: #ff6b6b; cursor: pointer;" data-action="deletePlan" data-stid="${validStIdx}" data-pid="${pIdx}"><i class="fas fa-trash-can"></i> Delete ${["3", "4"].includes(generatedTestCases.schemaLevel) ? "Project" : "Plan"}</span>
                     </div>
                </div>
                <div class="tree-children">`;

      plan.suites.forEach((suite, sIdx) => {
        // Hide Suite node for Level 3
        if (!isLevel3) {
          html += `
                    <div class="tree-node open">
                        <div class="tree-header">
                            <span data-action="toggleTree" style="display:flex; align-items:center; flex:1; cursor:pointer;">
                                <i class="fas fa-layer-group"></i> ${suite.suiteName}
                            </span>
                            <div class="tree-actions" style="display: flex; gap: 0.5rem; flex-shrink: 0;">
                                <span style="font-size: 0.75rem; color: var(--primary-color); cursor: pointer;" data-action="editSuite" data-stid="${validStIdx}" data-pid="${pIdx}" data-sid="${sIdx}">Edit</span>
                                <span style="font-size: 0.75rem; color: #ff6b6b; cursor: pointer;" data-action="deleteSuite" data-stid="${validStIdx}" data-pid="${pIdx}" data-sid="${sIdx}"><i class="fas fa-trash-can"></i> Delete Suite</span>
                            </div>
                        </div>
                        <div class="tree-children">`;
        }

        suite.testCases.forEach((tc, tIdx) => {
          const tcId = tc.testCaseId || tc.id;
          // Removed assignee from header line

          // TC is now a node with children (Evidence)
          html += `<div class="tree-node">
                        <div class="tree-header">
                              <span data-action="toggleTree" style="display:flex; align-items:center; flex:1; cursor:pointer;">
                                <i class="fas fa-file-alt" style="margin-right:8px;"></i> ${tcId || "No ID"}: ${tc.title || "Untitled Test Case"}
                             </span>
                             <div class="tree-actions" style="display: flex; gap: 0.5rem; flex-shrink: 0;">
                                 <span style="font-size: 0.75rem; color: var(--primary-color); cursor: pointer;" data-action="editTestCase" data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}"><i class="fas fa-edit"></i> Edit</span>
                                 <span style="font-size: 0.75rem; color: #ff6b6b; cursor: pointer;" data-action="deleteTestCase" data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}"><i class="fas fa-trash-can"></i> Delete</span>
                             </div>
                        </div>
                        <div class="tree-children">`;

          // Evidence Children
          if (tc.evidenceHistory && tc.evidenceHistory.length > 0) {
            tc.evidenceHistory.forEach((ev, evIdx) => {
              let color = "#ccc";
              let icon = "fa-clipboard";
              const s = (ev.status || "").toLowerCase();

              if (s === "passed") {
                color = "#4caf50";
                icon = "fa-check-circle";
              } else if (s === "failed") {
                color = "#f44336";
                icon = "fa-times-circle";
              } else if (s === "blocked") {
                color = "#ff9800";
                icon = "fa-ban";
              } else if (s === "skipped") {
                color = "#9e9e9e";
                icon = "fa-forward";
              } else if (s === "unexecuted" || s === "to-do") {
                color = "#2196f3";
                icon = "fa-clipboard-list";
              }

              // Determine assignee for this evidence (fallback to tc assignee)
              const currentAssignee =
                ev.assignee || ev.executedBy || tc.assignee;
              const assigneeDisplay = currentAssignee
                ? ` <span style="margin-left: 0.5rem; font-size: 0.75rem; color: var(--text-muted); font-weight: normal;"><i class="fas fa-user" style="margin-right: 0.25rem;"></i>${currentAssignee}</span>`
                : "";

              html += `<div class="tree-node leaf" style="padding-left: 2rem; color: ${color}; display: flex; justify-content: space-between; align-items: center;">
                                <span>
                                    <i class="fas ${icon}"></i> Cycle ${ev.cycle || "1.0"} - ${ev.status || "To-do"} (${ev.cycleDate || ev.date || "No Date"})${assigneeDisplay}
                                </span>
                                <span style="font-size: 0.75rem; color: #ff6b6b; cursor: pointer; margin-left: 1rem;" data-action="deleteEvidence" data-stid="${stIdxArg}" data-pid="${pIdx}" data-sid="${sIdx}" data-tid="${tIdx}" data-evid="${evIdx}" title="Delete Cycle Result">
                                    <i class="fas fa-trash-can"></i>
                                </span>
                             </div>`;
            });
          } else {
            html += `<div class="tree-node leaf" style="padding-left: 2rem; color: #666; font-style: italic;">No evidence</div>`;
          }

          html += `</div></div>`; // Close TC Children + TC Node
        });

        if (!isLevel3) {
          html += `</div></div>`; // Close Suite
        }
      });

      html += `</div></div>`; // Close Plan
    });

    if (isLevel6) {
      html += `</div></div>`; // Close Strategy
    }
  });

  elements.treeViewContent.innerHTML = html;
}

function calcStats() {
  updateStats();
}

// refreshAllUI is defined at the bottom of this file — do not duplicate it here.
// Single canonical definition ensures updateStats() is always called.

async function saveResults() {
  if (generatedTestCases) {
    localStorage.setItem(
      "qf_generated_test_cases",
      JSON.stringify(generatedTestCases),
    );

    // AUTO-SYNC to IndexedDB Session if refId exists
    const refId = generatedTestCases._refId;
    if (refId && window.QF && window.QF.initDB) {
      try {
        const db = await window.QF.initDB();
        const tx = db.transaction("sessions", "readwrite");
        const store = tx.objectStore("sessions");

        // Add metadata for sync tracking
        generatedTestCases._lastSynced = new Date().toISOString();

        store.put(generatedTestCases, refId);
        console.log("Auto-synced session to IndexedDB:", refId);
      } catch (e) {
        console.warn("Auto-sync failed:", e);
      }
    }
  }
}

function updateExports() {
  if (!generatedTestCases) return;

  // Generate Strict HFM Markdown
  const md = generateMarkdown(generatedTestCases);
  if (elements.markdownContent) elements.markdownContent.value = md;

  if (elements.jsonContent)
    elements.jsonContent.textContent = JSON.stringify(
      generatedTestCases,
      null,
      2,
    );
}

function cleanTags(tags) {
  if (!tags) return [];
  if (Array.isArray(tags)) {
    return tags
      .map((t) => (typeof t === "string" ? t.trim() : t))
      .filter((t) => t !== "");
  }
  if (typeof tags === "string") {
    return tags
      .split(",")
      .map((t) => t.trim())
      .filter((t) => t !== "");
  }
  return [];
}

// ===== Markdown Generation (Strict HFM Format) =====
function generateMarkdown(data) {
  const projectClean = data.projectName.toLowerCase().replace(/\s+/g, "-");
  const level = data.schemaLevel || "3";
  const reqPrefix = data.requirementPrefix || "REQ";
  const projPrefix = (data.projectName || "PROJ").toUpperCase().substring(0, 4);

  // 1. Dynamic doc-classify frontmatter
  let docClassify = `doc-classify:
  - select: heading[depth="1"]
    role: project`;

  if (level === "6") {
    docClassify += `
  - select: heading[depth="2"]
    role: strategy
  - select: heading[depth="3"]
    role: plan
  - select: heading[depth="4"]
    role: suite
  - select: heading[depth="5"]
    role: case
  - select: heading[depth="6"]
    role: evidence`;
  } else if (level === "5") {
    docClassify += `
  - select: heading[depth="2"]
    role: plan
  - select: heading[depth="3"]
    role: suite
  - select: heading[depth="4"]
    role: case
  - select: heading[depth="5"]
    role: evidence`;
  } else if (level === "4") {
    docClassify += `
  - select: heading[depth="2"]
    role: suite
  - select: heading[depth="3"]
    role: case
  - select: heading[depth="4"]
    role: evidence`;
  } else {
    // Level 3: Project -> Case -> Evidence
    docClassify += `
  - select: heading[depth="2"]
    role: case
  - select: heading[depth="3"]
    role: evidence`;
  }

  let md = `---\n${docClassify}\n---\n\n`;
  md += `# ${data.projectName}\n\n@id ${data.id || projectClean + "-project"}\n\n`;

  if (
    data.description &&
    !data.description.includes("This project provides a comprehensive")
  ) {
    md += `${data.description}\n\n`;
  } else {
    // AI Generated Project Details - Dynamic based on Project Name
    const area = data.projectName || "Application";
    md += `This project provides a comprehensive validation framework for **${area}**, focusing on functional integrity, user experience, and audit readiness.

**Objectives**

- Validate core functional flows and business logic.
- Ensure consistent UI/UX behavior across all relevant modules.
- Verify security, accessibility, and performance standards.
- Maintain a persistent audit trail with detailed evidence capture.

**Risks**

- Functional regressions in critical path workflows.
- User experience inconsistencies or navigation failures.
- Data integrity issues during state transitions.
- Compliance gaps due to missing or incomplete evidence.
- Integration failures with downstream systems.

`;
  }

  // 2. Global Requirement Block (only if text is provided OR for level 3)
  if (data.requirementText || level === "3") {
    const globalReqId = data.manualRequirementId
      ? data.manualRequirementId
      : `${projPrefix}-${reqPrefix}-001`;

    md += generateRequirementBlock(
      data.projectName,
      globalReqId,
      data.requirementText,
      reqPrefix,
      data.requirementTitle,
      data.requirementDescription,
    );
  }

  // Tracking requirement index globally for sequential mapping
  let globalReqIdx = 0;

  // 3. Render Content Hierarchy
  const strategies =
    level === "6"
      ? data.strategies || []
      : [{ strategyName: "Default", plans: data.plans || [] }];

  strategies.forEach((strat) => {
    if (level === "6") {
      md += `## ${strat.strategyName}\n\n@id ${strat.strategyId || strat.id || "STRAT-001"}\n\n`;
      if (strat.description) md += `${strat.description}\n\n`;
    }

    const plans = strat.plans || [];
    plans.forEach((plan) => {
      // PLAN HEADER: Only for 5 and 6
      if (level === "5" || level === "6") {
        const pDepth = level === "6" ? "###" : "##";
        md += `${pDepth} ${plan.planName}\n\n@id ${plan.planId || "PLAN-001"}\n\n`;
        md += `\`\`\`yaml HFM\n  plan-name: ${plan.planName}\n  plan-date: ${plan.planDate || new Date().toISOString().split("T")[0]}\n  created-by: ${plan.planCreatedBy || "User"}\n\`\`\`\n\n`;
        if (plan.description) md += `${plan.description}\n\n`;

        // Plan-level Requirements (Level 5 Only)
        if (plan.requirementText && level === "5") {
          const planReqId =
            plan.requirementId ||
            data.manualRequirementId ||
            `${projPrefix}-${reqPrefix}-PLAN`;
          md += generateRequirementBlock(
            plan.planName,
            planReqId,
            plan.requirementText,
            reqPrefix,
            plan.requirementTitle,
            plan.requirementDescription,
          );
        }
      }

      const suites = plan.suites || [];
      suites.forEach((suite) => {
        // SUITE HEADER: Only for 4, 5, 6
        if (level === "4" || level === "5" || level === "6") {
          let sDepth = "##"; // Level 4
          if (level === "5") sDepth = "###";
          if (level === "6") sDepth = "####";

          md += `${sDepth} ${suite.suiteName}\n\n@id ${suite.suiteId || "SUITE-001"}\n\n`;
          md += `\`\`\`yaml HFM\n  suite-name: ${suite.suiteName}\n  suite-date: ${suite.suiteDate || new Date().toISOString().split("T")[0]}\n  created-by: ${suite.suiteCreatedBy || "User"}\n\`\`\`\n\n`;
          if (suite.requirementText) {
            md += generateRequirementBlock(
              suite.suiteName,
              suite.requirementId || `${projPrefix}-${reqPrefix}-S`,
              suite.requirementText,
              reqPrefix,
              suite.requirementTitle,
              suite.requirementDescription,
            );
          }
        }

        const cases = suite.testCases || [];
        cases.forEach((tc) => {
          globalReqIdx++;
          // CASE HEADER
          let cDepth = "##"; // Level 3
          if (level === "4") cDepth = "###";
          if (level === "5") cDepth = "####";
          if (level === "6") cDepth = "#####";

          md += `${cDepth} ${tc.title}\n\n@id ${tc.testCaseId || tc.id}\n\n`;
          md += `\`\`\`yaml HFM\n`;

          // Requirement link logic
          let reqLink = tc.requirementId || tc.requirementID;
          if (!reqLink) {
            if (level === "5" || level === "6") {
              reqLink = plan.requirementId || plan.requirementID;
            } else if (level === "4") {
              reqLink = suite.requirementId || suite.requirementID;
            } else if (data.manualRequirementId) {
              reqLink = data.manualRequirementId;
            }
          }

          if (!reqLink) {
            reqLink = `${reqPrefix}-${String(globalReqIdx).padStart(4, "0")}`;
          }

          // Reconstruct YAML preserving original fields
          const baseYaml = tc.yamlMetadata ? { ...tc.yamlMetadata } : {};

          // Logic: "Tags" might be array or string in baseYaml
          // If it was parsed by us, it's in tc.tags as array.
          // We should ALWAYS output valid YAML.
          // If baseYaml has keys that duplicate the ones we manage, overwrite them.

          baseYaml.requirementID = reqLink || "REQ-0001";
          baseYaml.Priority = tc.priority || "Medium";
          baseYaml.Tags = JSON.stringify(cleanTags(tc.tags));
          baseYaml["Scenario Type"] =
            tc.scenarioType || tc.scenario_type || "Happy Path";
          baseYaml["Execution Type"] =
            tc.executionType || tc.execution_type || "Manual";

          for (const [k, v] of Object.entries(baseYaml)) {
            // Handle special case where v might be a complex object (though parser flattens it mostly)
            md += `  ${k}: ${v}\n`;
          }

          md += `\`\`\`\n\n`;

          md += `**Description**\n\n${tc.description || tc.title}\n\n`;

          if (tc.preconditions && tc.preconditions.length > 0) {
            md += `**Preconditions**\n\n`;
            const pre = Array.isArray(tc.preconditions)
              ? tc.preconditions
              : [tc.preconditions];
            pre.forEach((p) => (md += `- [x] ${p}\n`));
            md += `\n`;
          }

          if (tc.steps) {
            md += `**Steps**\n\n`;

            // Handle both string and array formats
            if (typeof tc.steps === "string") {
              // If it's a string, split by newlines or numbered items
              const stepLines = tc.steps
                .split(/\n|\\n/)
                .filter((s) => s.trim());
              stepLines.forEach((s) => {
                md += `- [x] ${s.trim()}\n`;
              });
            } else if (Array.isArray(tc.steps) && tc.steps.length > 0) {
              // If it's an array, iterate normally
              tc.steps.forEach((s) => {
                const txt = typeof s === "string" ? s : s.action;
                md += `- [x] ${txt}\n`;
              });
            }

            md += `\n`;
          }

          const expRes = tc.expectedResult || tc.expected_result;
          if (expRes) {
            md += `**Expected Results**\n\n`;
            const exp = Array.isArray(expRes)
              ? expRes
              : String(expRes).split("\n");
            exp.forEach((e) => {
              if (e && typeof e === "string" && e.trim())
                md += `- [x] ${e.trim()}\n`;
            });
            md += `\n`;
          }

          // EVIDENCE
          const history = tc.evidenceHistory || [];
          history.forEach((ev) => {
            let eDepth = "###"; // Level 3
            if (level === "4") eDepth = "####";
            if (level === "5") eDepth = "#####";
            if (level === "6") eDepth = "######";

            md += `${eDepth} Evidence\n\n@id ${tc.testCaseId || tc.id}\n\n`;
            md += `\`\`\`yaml META\n`;
            md += `  cycle: ${ev.cycle || "1.0"}\n`;
            md += `  cycle-date: ${ev.cycleDate || ev.date || ""}\n`;
            md += `  severity: ${tc.priority || "Medium"}\n`;
            md += `  assignee: ${ev.assignee || "User"}\n`;
            md += `  status: ${ev.status || "passed"}\n`;
            md += `\`\`\`\n\n`;

            const attachText =
              ev.attachments && ev.attachments.trim()
                ? ev.attachments.trim()
                : getDefaultAttachments(tc.testCaseId || tc.id, ev.cycle);

            md += `**Attachments**\n\n${attachText}\n\n`;
          });
          md += `---\n\n`;
        });
      });
    });
  });

  return md;
}

function generateRequirementBlock(
  name,
  id,
  text,
  reqPrefix,
  title,
  description,
) {
  const finalTitle = title || `${name} Functional and UX Validation`;
  const finalDesc =
    description ||
    `Defines the functional and user experience requirements for ${name}, ensuring consistency and correctness across all test flows`;

  let block = `--- \n\n**${name} Functional Requirements**\n\n@id ${id}\n\n`;
  block += `\`\`\`yaml HFM\ndoc-classify:\n  role: requirement\n  requirementID: ${id}\n  title: ${finalTitle}\n  description: ${finalDesc}\n\`\`\`\n\n`;

  block += `**Requirement Scope**\n\nThese requirements define the **expected behavior and user experience** of **${name}**.\n\n---\n\n`;

  const prefix = reqPrefix || "REQ";

  if (text) {
    const lines = text.split("\n").filter((l) => l.trim().length > 0);
    block += `**Functional Requirements** \n\n`;
    block += lines
      .map((l, idx) => {
        // Strip @id and REQ-style prefixes
        let cleaned = l
          .trim()
          .replace(/^[•\-\*]\s*/, "") // Remove bullets
          .replace(/@id\s+[^\s]+\s*/i, "") // Remove @id tags
          .replace(/[A-Z]+-\d+:\s*/i, "") // Remove REQ-001: style prefixes
          .trim();
        return `* [ ] ${cleaned}`;
      })
      .join("\n");
    block += `\n\n---\n\n**Acceptance Criteria**\n\n`;
    block += lines
      .map((l, idx) => {
        let cleaned = l
          .trim()
          .replace(/^[•\-\*]\s*/, "")
          .replace(/@id\s+[^\s]+\s*/i, "")
          .replace(/[A-Z]+-\d+:\s*/i, "")
          .trim();
        return `* [ ] Verify: ${cleaned}`;
      })
      .join("\n");
    block += `\n\n`;
  } else {
    block += `**Functional Requirements** \n\n* [ ] The system shall perform its core functions as expected.\n* [ ] The user interface shall be responsive and intuitive.\n\n---\n\n**Acceptance Criteria**\n\n* [ ] Verify: system stability.\n* [ ] Verify: correct output for primary workflows.\n\n`;
  }
  return block + `--- \n\n`;
}

function getAiGeneratedRequirements(projectName) {
  const settings = JSON.parse(localStorage.getItem("qf_system_settings")) || {};
  const reqPrefix = settings.requirementPrefix || "REQ";
  const projPrefix = (projectName || "PROJ").toUpperCase().substring(0, 4);
  const genId = `${projPrefix}-${reqPrefix}-001`;
  return generateRequirementBlock(projectName, genId, null, reqPrefix);
}

// ===== Edit Modal Logic (Enabled) =====

// Cache modal elements dynamically
var editModalElements = {
  overlay: document.getElementById("editModal"),
  title: document.getElementById("editTcTitle"),
  steps: document.getElementById("editTcSteps"),
  expected: document.getElementById("editTcExpected"),
  // New Fields
  scenarioType: document.getElementById("editTcScenarioType"),
  executionType: document.getElementById("editTcExecutionType"),
  tags: document.getElementById("editTcTags"),

  evidenceContainer: document.getElementById("evidenceListContainer"),
  saveBtn: document.getElementById("saveEdit"),
  // Hidden inputs created dynamically
  stIdx: null,
  planIdx: null,
  suiteIdx: null,
  tcIdx: null,
};

// Create hidden inputs if not existent
if (!document.getElementById("editPlanIdx")) {
  const stInput = document.createElement("input");
  stInput.type = "hidden";
  stInput.id = "editStIdx";
  const pInput = document.createElement("input");
  pInput.type = "hidden";
  pInput.id = "editPlanIdx";
  const sInput = document.createElement("input");
  sInput.type = "hidden";
  sInput.id = "editSuiteIdx";
  const tInput = document.createElement("input");
  tInput.type = "hidden";
  tInput.id = "editTcIdx";
  document.body.appendChild(stInput);
  document.body.appendChild(pInput);
  document.body.appendChild(sInput);
  document.body.appendChild(tInput);
  editModalElements.stIdx = stInput;
  editModalElements.planIdx = pInput;
  editModalElements.suiteIdx = sInput;
  editModalElements.tcIdx = tInput;
} else {
  editModalElements.stIdx = document.getElementById("editStIdx");
  editModalElements.planIdx = document.getElementById("editPlanIdx");
  editModalElements.suiteIdx = document.getElementById("editSuiteIdx");
  editModalElements.tcIdx = document.getElementById("editTcIdx");
}

window.openEditModal = function (stIdx, pIdx, sIdx, tIdx) {
  // If not level 6, stIdx might be 'null' or null.
  // If we have strategies, drill down. Else use plans directly.

  let tc;
  const isLevel6 = generatedTestCases.schemaLevel === "6";

  if (isLevel6) {
    if (
      !generatedTestCases.strategies[stIdx] ||
      !generatedTestCases.strategies[stIdx].plans[pIdx] ||
      !generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx]
    )
      return;
    tc =
      generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx].testCases[
      tIdx
      ];
    if (editModalElements.stIdx) editModalElements.stIdx.value = stIdx;
  } else {
    if (
      !generatedTestCases.plans[pIdx] ||
      !generatedTestCases.plans[pIdx].suites[sIdx]
    )
      return;
    tc = generatedTestCases.plans[pIdx].suites[sIdx].testCases[tIdx];
    if (editModalElements.stIdx) editModalElements.stIdx.value = "";
  }

  if (!tc) return;

  // Populate fields
  editModalElements.title.value = tc.title || "";

  // Robust Steps Mapping - FIXED: ensuring objects are stringified for human reading
  if (Array.isArray(tc.steps)) {
    editModalElements.steps.value = tc.steps
      .map((s) => {
        if (typeof s === "string") return s;
        // If it's an object with action/expected, format it
        if (s.action) return s.action;
        if (s.step && typeof s.step === "object") return JSON.stringify(s.step);
        return s.text || s.description || JSON.stringify(s);
      })
      .join("\n");
  } else {
    editModalElements.steps.value = tc.steps || "";
  }

  // Resolve Expected Result (either array or string)
  let expVal = tc.expectedResult || tc.expected_result || "";
  if (Array.isArray(expVal)) {
    expVal = expVal
      .map((e) => (typeof e === "string" ? e : JSON.stringify(e)))
      .join("\\n");
  }
  editModalElements.expected.value = expVal;

  // New Fields
  const visibleId = tc.testCaseId || tc.id || "";
  if (document.getElementById("editTcId")) {
    document.getElementById("editTcId").value = visibleId;
  }

  if (document.getElementById("editTcReqId")) {
    document.getElementById("editTcReqId").value =
      tc.requirementId || tc.reqId || "";
  }

  // New Fields Population
  const sType = Array.isArray(tc.scenarioType)
    ? tc.scenarioType.join(", ")
    : (tc.scenarioType || tc.scenario_type || "Happy Path").toString().trim() ||
    "Happy Path";
  if (editModalElements.scenarioType)
    editModalElements.scenarioType.value = sType;
  const sSel = document.getElementById("editTcScenarioTypeSelect");
  if (sSel) sSel.value = sType;

  const eType = Array.isArray(tc.executionType)
    ? tc.executionType.join(", ")
    : (tc.executionType || tc.execution_type || "Manual").toString().trim() ||
    "Manual";
  if (editModalElements.executionType)
    editModalElements.executionType.value = eType;
  const eSel = document.getElementById("editTcExecutionTypeSelect");
  if (eSel) eSel.value = eType;

  if (editModalElements.tags) {
    editModalElements.tags.value = Array.isArray(tc.tags)
      ? tc.tags.join(", ")
      : tc.tags || "";
  }

  // Set indices
  editModalElements.planIdx.value = pIdx;
  editModalElements.suiteIdx.value = sIdx;
  editModalElements.tcIdx.value = tIdx;

  // Populate Evidence
  editModalElements.evidenceContainer.innerHTML = "";
  const history = tc.evidenceHistory || [];

  if (history.length === 0) {
    editModalElements.evidenceContainer.innerHTML =
      '<div id="noEvidencePlaceholder" style="font-style:italic; color:var(--text-muted); padding:0.5rem;">No evidence recorded yet.</div>';
  } else {
    history.forEach((ev) => addEvidenceRowToModal(ev));
  }

  // Show - FIXED: use classList
  editModalElements.overlay.classList.add("active");
};

// Moved Event Listeners to setupEventListeners to ensure DOM readiness

function addEvidenceRowToModal(ev) {
  const row = document.createElement("div");
  row.className = "evidence-row";
  row.style =
    "background: #f8fafc; padding: 1.25rem; border-radius: 10px; border: 1px solid #e2e8f0; position: relative; margin-bottom: 1rem; box-shadow: 0 1px 2px rgba(0,0,0,0.02);";

  // Ensure all assignees (including current one if custom) are in options
  let assignees =
    typeof assigneeMaster !== "undefined" && Array.isArray(assigneeMaster)
      ? assigneeMaster
      : [];
  let assigneeNames = assignees.map((u) =>
    typeof u === "string" ? u : u.name,
  );

  if (
    ev.assignee &&
    ev.assignee !== "Unassigned" &&
    !assigneeNames.includes(ev.assignee)
  ) {
    assigneeNames.push(ev.assignee);
  }

  // Date Logic: Calculate ISO (for picker) and Display (for text input)
  let isoDate = "";
  let displayDate = "";
  let rawDate = ev.cycleDate || ev.date || "";

  if (rawDate) {
    // Check if YYYY-MM-DD
    if (/^\d{4}-\d{2}-\d{2}$/.test(rawDate)) {
      isoDate = rawDate;
      const [y, m, d] = rawDate.split("-");
      displayDate = `${m}-${d}-${y}`;
    }
    // Check if MM/DD/YYYY or MM-DD-YYYY
    else if (/^\d{1,2}[-/]\d{1,2}[-/]\d{4}$/.test(rawDate)) {
      const parts = rawDate.split(/[-/]/);
      // Assuming MM-DD-YYYY
      const m = parts[0].padStart(2, "0");
      const d = parts[1].padStart(2, "0");
      const y = parts[2];
      displayDate = `${m}-${d}-${y}`;
      isoDate = `${y}-${m}-${d}`;
    }
  }

  // Default to Today if invalid/empty
  if (!isoDate || !displayDate) {
    const d = new Date();
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    isoDate = `${y}-${m}-${day}`;
    displayDate = `${m}-${day}-${y}`;
  }

  const options = assigneeNames
    .map(
      (name) =>
        `<option value="${name}" ${ev.assignee === name ? "selected" : ""}>${name}</option>`,
    )
    .join("");

  row.innerHTML = `
        <button type="button" class="remove-evidence" style="position: absolute; top: -10px; right: -10px; background: #fff; border: 1px solid #fee2e2; color: #ef4444; cursor: pointer; font-size: 0.9rem; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 4px rgba(0,0,0,0.05); transition: all 0.2s;">&times;</button>
        <div style="display: grid; grid-template-columns: 1fr 1.2fr; gap: 0.75rem; margin-bottom: 0.75rem;">
            <div class="qfg-field">
                <label style="font-size: 0.75rem; color: #64748b; font-weight: 600; margin-bottom: 4px; display: block;">Run</label>
                <input type="text" class="form-input ev-cycle" value="${ev.cycle || ""}" placeholder="e.g. 1.0" style="padding: 0.5rem 0.75rem; font-size: 0.88rem;">
            </div>
            <div class="qfg-field">
                <label style="font-size: 0.75rem; color: #64748b; font-weight: 600; margin-bottom: 4px; display: block;">Status</label>
                <select class="form-input ev-status" style="padding: 0.5rem 0.75rem; font-size: 0.88rem;">
                    ${["To-do", "In Progress", "Passed", "Failed", "Blocked", "Skipped", "Pending"].map((s) => `<option value="${s}" ${ev.status === s ? "selected" : ""}>${s}</option>`).join("")}
                </select>
            </div>
        </div>
        <div style="display: grid; grid-template-columns: 1fr 1.2fr; gap: 0.75rem;">
            <div class="qfg-field" style="position: relative;">
                <label style="font-size: 0.75rem; color: #64748b; font-weight: 600; margin-bottom: 4px; display: block;">Date</label>
                <div style="display: flex; align-items: center; position: relative;">
                    <input type="text" class="form-input ev-date" value="${displayDate}" placeholder="MM-DD-YYYY" style="width: 100%; background: #fff; cursor: pointer; padding: 0.5rem 0.75rem; font-size: 0.88rem;">
                    <input type="hidden" class="ev-date-iso" value="${isoDate}">
                    <i class="fas fa-calendar-alt" style="position: absolute; right: 10px; pointer-events: none; color: #94a3b8; font-size: 0.85rem;"></i>
                </div>
            </div>
            <div class="qfg-field">
                <label style="font-size: 0.75rem; color: #64748b; font-weight: 600; margin-bottom: 4px; display: block;">Executed By</label>
                <select class="form-input ev-assignee" style="padding: 0.5rem 0.75rem; font-size: 0.88rem;">
                    <option value="Unassigned">-- Assignee --</option>
                    ${options}
                </select>
            </div>
        </div>
    `;

  row
    .querySelector(".remove-evidence")
    .addEventListener("click", () => row.remove());
  editModalElements.evidenceContainer.appendChild(row);

  // Attach Pikaday to the new evidence date row
  if (typeof window.qfAttachDatePicker === "function") {
    window.qfAttachDatePicker(
      row.querySelector(".ev-date"),
      row.querySelector(".ev-date-iso"),
      isoDate || undefined,
    );
  }
}

// Consolidated save listener function
function handleSaveTestCaseEdit() {
  const stIdxVal = editModalElements.stIdx.value;
  const pIdx = editModalElements.planIdx.value;
  const sIdx = editModalElements.suiteIdx.value;
  const tIdx = editModalElements.tcIdx.value;

  let tc;
  if (generatedTestCases.schemaLevel === "6" && stIdxVal !== "") {
    if (
      !generatedTestCases.strategies[stIdxVal] ||
      !generatedTestCases.strategies[stIdxVal].plans[pIdx] ||
      !generatedTestCases.strategies[stIdxVal].plans[pIdx].suites[sIdx]
    )
      return;
    tc =
      generatedTestCases.strategies[stIdxVal].plans[pIdx].suites[sIdx]
        .testCases[tIdx];
  } else {
    if (
      !generatedTestCases.plans[pIdx] ||
      !generatedTestCases.plans[pIdx].suites[sIdx]
    )
      return;
    tc = generatedTestCases.plans[pIdx].suites[sIdx].testCases[tIdx];
  }

  if (!tc) return;

  tc.title = editModalElements.title.value;
  tc.steps = editModalElements.steps.value.split("\n").filter((s) => s.trim());
  tc.expectedResult = editModalElements.expected.value;

  // Save New Fields
  if (document.getElementById("editTcId")) {
    const newId = document.getElementById("editTcId").value.trim();
    if (newId) {
      tc.testCaseId = newId;
      tc.id = newId;
    }
  }
  if (document.getElementById("editTcReqId")) {
    tc.requirementId = document.getElementById("editTcReqId").value.trim();
  }

  try {
    if (editModalElements.scenarioType)
      tc.scenarioType = editModalElements.scenarioType.value;
    if (editModalElements.executionType)
      tc.executionType = editModalElements.executionType.value;

    if (editModalElements.tags) {
      const tagsVal = editModalElements.tags.value;
      tc.tags = tagsVal
        ? tagsVal
          .split(",")
          .map((t) => t.trim())
          .filter((t) => {
            if (!t) return false;
            if (t.toLowerCase() === "null") return false;
            if (/^[^a-zA-Z0-9]+$/.test(t)) return false;
            return true;
          })
        : [];
    }

    if (editModalElements.evidenceContainer) {
      const rows =
        editModalElements.evidenceContainer.querySelectorAll(".evidence-row");
      const newHistory = Array.from(rows).map((row) => {
        const isoDateEl = row.querySelector(".ev-date-iso");
        const displayDateEl = row.querySelector(".ev-date");
        let cycleDate = "";
        if (isoDateEl && isoDateEl.value) {
          cycleDate = isoDateEl.value;
        } else if (displayDateEl && displayDateEl.value) {
          const parts = displayDateEl.value.split("-");
          if (parts.length === 3 && parts[2].length === 4) {
            cycleDate = `${parts[2]}-${parts[0]}-${parts[1]}`;
          } else {
            cycleDate = displayDateEl.value;
          }
        }
        return {
          cycle: row.querySelector(".ev-cycle")
            ? row.querySelector(".ev-cycle").value.trim()
            : "1.0",
          status: row.querySelector(".ev-status")
            ? row.querySelector(".ev-status").value
            : "To-do",
          cycleDate: cycleDate,
          assignee: row.querySelector(".ev-assignee")
            ? row.querySelector(".ev-assignee").value
            : "Unassigned",
          attachments: row.querySelector(".ev-attachments")
            ? row.querySelector(".ev-attachments").value
            : "",
        };
      });

      const cycleNames = newHistory.map((h) => h.cycle);
      const uniqueCycles = new Set(cycleNames);
      if (uniqueCycles.size !== cycleNames.length) {
        if (editModalElements.overlay)
          editModalElements.overlay.dataset.saveBlocked = "true";
        return alert(
          "Duplicate Run entries found. Each Run must be unique for a test case.",
        );
      }

      tc.evidenceHistory = newHistory;
    }
  } catch (err) {
    console.error("[md-editor] Error saving form fields:", err);
  }

  // ALWAYS call refreshAllUI at the end!
  try {
    refreshAllUI();
  } catch (err) {
    console.error("[md-editor] Error refreshing UI:", err);
  }
  if (editModalElements.overlay) {
    editModalElements.overlay.classList.remove("active");
  }
}

// ===== Interactive Functions (Global) =====

window.handleQuickAssign = function (stIdx, pIdx, sIdx, tIdx, value) {
  let tc;
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null" &&
    stIdx !== null
  ) {
    if (!generatedTestCases.strategies[stIdx]) return;
    tc =
      generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx].testCases[
      tIdx
      ];
  } else {
    if (!generatedTestCases.plans[pIdx]) return;
    tc = generatedTestCases.plans[pIdx].suites[sIdx].testCases[tIdx];
  }

  if (!tc) return;

  tc.assignee = value;

  // Update evidence history if present
  if (!tc.evidenceHistory) tc.evidenceHistory = [];
  if (tc.evidenceHistory.length > 0) {
    tc.evidenceHistory[0].assignee = value;
  } else {
    tc.evidenceHistory.push({
      cycle: "1.0",
      cycleDate: new Date().toISOString().split("T")[0],
      status: "To-do",
      assignee: value,
      attachments: getDefaultAttachments(tc.testCaseId || tc.id, "1.0"),
    });
  }

  refreshAllUI();
  console.log(`Updated assignee to ${value}`);
};

window.handleQuickPriority = function (stIdx, pIdx, sIdx, tIdx, value) {
  let tc;
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null" &&
    stIdx !== null
  ) {
    if (!generatedTestCases.strategies[stIdx]) return;
    tc =
      generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx].testCases[
      tIdx
      ];
  } else {
    if (!generatedTestCases.plans[pIdx]) return;
    tc = generatedTestCases.plans[pIdx].suites[sIdx].testCases[tIdx];
  }

  if (!tc) return;

  tc.priority = value;
  refreshAllUI();
  console.log(`Updated priority to ${value}`);
};

// ===== Event Listeners =====

function setupEventListeners() {
  // Tabs
  document.querySelectorAll(".tab-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      document
        .querySelectorAll(".tab-btn")
        .forEach((b) => b.classList.remove("active"));
      document
        .querySelectorAll(".tab-content")
        .forEach((c) => c.classList.remove("active"));

      btn.classList.add("active");
      document.getElementById(btn.dataset.tab).classList.add("active");
    });
  });

  // Download
  if (elements.downloadBtn) {
    elements.downloadBtn.addEventListener("click", async () => {
      let fileName = `${generatedTestCases.projectName}_TestCases.md`;
      const fileNameInput = document.getElementById("downloadFileName");
      if (fileNameInput && fileNameInput.value.trim()) {
        fileName = fileNameInput.value.trim();
        if (!fileName.toLowerCase().endsWith(".md")) {
          fileName += ".md";
        }
      }
      const content = elements.markdownContent.value;

      // Try File System Access API if handle available
      if (window.globalDirectoryHandle) {
        try {
          // Check permissions
          const options = { mode: "readwrite" };
          if (
            (await window.globalDirectoryHandle.queryPermission(options)) !==
            "granted"
          ) {
            if (
              (await window.globalDirectoryHandle.requestPermission(
                options,
              )) !== "granted"
            ) {
              throw new Error("Permission denied");
            }
          }

          const fileHandle = await window.globalDirectoryHandle.getFileHandle(
            fileName,
            { create: true },
          );
          const writable = await fileHandle.createWritable();
          await writable.write(content);
          await writable.close();

          // Visual feedback
          const originalHtml = elements.downloadBtn.innerHTML;
          elements.downloadBtn.innerHTML =
            '<i class="fas fa-check"></i> Overwritten!';
          elements.downloadBtn.classList.add("text-success");
          setTimeout(() => {
            elements.downloadBtn.innerHTML = originalHtml;
            elements.downloadBtn.classList.remove("text-success");
          }, 2000);

          return; // Success, skip standard download
        } catch (err) {
          console.warn(
            "File System Access failed, falling back to standard download:",
            err,
          );
        }
      }

      // Fallback: Standard <a> tag download
      const blob = new Blob([content], { type: "text/markdown" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = fileName;
      a.click();
      URL.revokeObjectURL(url);
    });
  }

  // Select All
  if (elements.selectAllTcs) {
    elements.selectAllTcs.addEventListener("change", (e) => {
      document
        .querySelectorAll(".tc-checkbox")
        .forEach((cb) => (cb.checked = e.target.checked));
      updateSelectedCount();
    });
  }

  // Bulk Actions (Assign & Priority)
  if (elements.applyBulkActions) {
    elements.applyBulkActions.addEventListener("click", () => {
      const assignee = elements.bulkAssignSelect.value;
      const priority = elements.bulkPrioritySelect.value;

      if (!assignee && !priority) {
        return alert("Please select an Assignee or Priority to apply.");
      }

      const checked = document.querySelectorAll(".tc-checkbox:checked");
      if (checked.length === 0) return alert("Select test cases first");

      let updatedCount = 0;
      checked.forEach((cb) => {
        const { stid, pid, sid, tid } = cb.dataset;

        let tc;
        if (
          generatedTestCases.schemaLevel === "6" &&
          stid != null &&
          stid !== "null" &&
          generatedTestCases.strategies[stid]
        ) {
          tc =
            generatedTestCases.strategies[stid].plans[pid].suites[sid]
              .testCases[tid];
        } else if (generatedTestCases.plans[pid]) {
          tc = generatedTestCases.plans[pid].suites[sid].testCases[tid];
        }

        if (tc) {
          if (assignee) {
            tc.assignee = assignee;
            // Update history if present/needed similar to handleQuickAssign
            if (!tc.evidenceHistory) tc.evidenceHistory = [];
            if (tc.evidenceHistory.length > 0) {
              tc.evidenceHistory[0].assignee = assignee;
            } else {
              tc.evidenceHistory.push({
                cycle: "1.0",
                cycleDate: new Date().toISOString().split("T")[0],
                status: "To-do",
                assignee: assignee,
              });
            }
          }
          if (priority) {
            tc.priority = priority;
          }
          updatedCount++;
        }
      });

      refreshAllUI();
      if (window.mdEditorBridge) window.mdEditorBridge.syncCurrentFile();
      // Reset Select All checkbox
      if (elements.selectAllTcs) elements.selectAllTcs.checked = false;
      updateSelectedCount();

      // Clear dropdowns after apply
      elements.bulkAssignSelect.value = "";
      elements.bulkPrioritySelect.value = "";

      let msg = `Updated ${updatedCount} test cases.`;
      if (assignee) msg += `\n- Assignee: ${assignee}`;
      if (priority) msg += `\n- Priority: ${priority}`;
      alert(msg);
    });
  }

  // Bulk Actions Reset
  if (elements.resetBulkActions) {
    elements.resetBulkActions.addEventListener("click", () => {
      // Clear Assign/Priority
      if (elements.bulkAssignSelect) elements.bulkAssignSelect.value = "";
      if (elements.bulkPrioritySelect) elements.bulkPrioritySelect.value = "";

      // Clear Properties
      if (elements.bulkScenarioType) elements.bulkScenarioType.value = "";
      if (elements.bulkExecutionType) elements.bulkExecutionType.value = "";
      if (elements.bulkTags) elements.bulkTags.value = "";
      if (document.getElementById("bulkTagsSelect"))
        document.getElementById("bulkTagsSelect").value = "";

      // Clear Cycle
      if (elements.bulkCycleName) elements.bulkCycleName.value = "";
      if (elements.bulkCycleDate) elements.bulkCycleDate.value = "";
      if (elements.bulkCycleAssignee) elements.bulkCycleAssignee.value = "";
      if (elements.bulkCycleStatus) elements.bulkCycleStatus.value = "";

      // Update tooltip to reflect cleared state
      if (typeof updateBulkPropsTooltip === "function") {
        updateBulkPropsTooltip();
      }

      alert(
        "Reset successful: All bulk properties and cycle fields have been cleared.",
      );
    });
  }

  // Bulk Properties (New)
  if (elements.applyBulkProps) {
    elements.applyBulkProps.addEventListener("click", () => {
      const scenario = elements.bulkScenarioType.value;
      const execution = elements.bulkExecutionType.value;
      const tagsTxt = elements.bulkTags.value.trim();

      if (!scenario && !execution && !tagsTxt) {
        return alert(
          "Please select at least one property to set (Scenario, Execution, or Tags)",
        );
      }

      // Pre-validate tags if provided
      let validTags = [];
      if (tagsTxt) {
        validTags = tagsTxt
          .split(",")
          .map((t) => t.trim())
          .filter((t) => {
            if (!t) return false;
            if (t.toLowerCase() === "null") return false;
            // Reject if only special characters (no alphanumeric)
            if (/^[^a-zA-Z0-9]+$/.test(t)) return false;
            return true;
          });

        if (validTags.length === 0) {
          return alert(
            "Invalid tags detected. Tags must contain alphanumeric characters and cannot be empty or 'null'.",
          );
        }
      }

      const checked = document.querySelectorAll(".tc-checkbox:checked");
      if (checked.length === 0) return alert("Select test cases first");

      let updateCount = 0;
      checked.forEach((cb) => {
        const { stid, pid, sid, tid } = cb.dataset;

        let tc;
        if (
          generatedTestCases.schemaLevel === "6" &&
          stid != null &&
          stid !== "null"
        ) {
          tc =
            generatedTestCases.strategies[stid].plans[pid].suites[sid]
              .testCases[tid];
        } else {
          tc = generatedTestCases.plans[pid].suites[sid].testCases[tid];
        }

        if (scenario) tc.scenarioType = scenario;
        if (execution) tc.executionType = execution;

        if (validTags.length > 0) {
          const currentTags = cleanTags(tc.tags);
          validTags.forEach((nt) => {
            if (!currentTags.includes(nt)) currentTags.push(nt);
          });
          tc.tags = currentTags;
        }
        updateCount++;
      });

      refreshAllUI();
      if (window.mdEditorBridge) window.mdEditorBridge.syncCurrentFile();
      // Reset Select All checkbox
      if (elements.selectAllTcs) elements.selectAllTcs.checked = false;
      updateSelectedCount();
      alert(`Updated properties for ${updateCount} test cases.`);
    });
  }

  // Helper logic for Tag Dropdowns (Multi-select simulation)
  const bulkTagsSelect = document.getElementById("bulkTagsSelect");
  if (bulkTagsSelect) {
    bulkTagsSelect.addEventListener("change", (e) => {
      const val = e.target.value;
      if (!val) return;

      const input = document.getElementById("bulkTags");
      if (input) {
        const current = input.value.trim();
        if (current) {
          // Avoid duplicates in input if possible, but allow appending
          if (!current.includes(val)) {
            input.value = current + ", " + val;
          }
        } else {
          input.value = val;
        }
      }
      // Reset select
      e.target.value = "";
    });
  }

  const editTagsSelect = document.getElementById("editTcTagsSelect");
  if (editTagsSelect) {
    editTagsSelect.addEventListener("change", (e) => {
      const val = e.target.value;
      if (!val) return;

      const input = document.getElementById("editTcTags");
      if (input) {
        const current = input.value.trim();
        if (current) {
          if (!current.includes(val)) {
            input.value = current + ", " + val;
          }
        } else {
          input.value = val;
        }
      }
      e.target.value = "";
    });
  }

  // Edit Modal Select Sync (Scenario, Execution)
  const editScenarioSelect = document.getElementById(
    "editTcScenarioTypeSelect",
  );
  if (editScenarioSelect) {
    editScenarioSelect.addEventListener("change", (e) => {
      const input = document.getElementById("editTcScenarioType");
      if (input) input.value = e.target.value;
    });
  }
  const editExecutionSelect = document.getElementById(
    "editTcExecutionTypeSelect",
  );
  if (editExecutionSelect) {
    editExecutionSelect.addEventListener("change", (e) => {
      const input = document.getElementById("editTcExecutionType");
      if (input) input.value = e.target.value;
    });
  }

  // Bulk Properties Tooltip Functionality
  const bulkPropsTooltipIcon = document.getElementById("bulkPropsTooltipIcon");
  const bulkPropsTooltip = document.getElementById("bulkPropsTooltip");

  if (bulkPropsTooltipIcon && bulkPropsTooltip) {
    // Show tooltip on hover
    bulkPropsTooltipIcon.addEventListener("mouseenter", () => {
      updateBulkPropsTooltip();
      bulkPropsTooltip.style.display = "block";
    });

    // Hide tooltip when mouse leaves
    bulkPropsTooltipIcon.addEventListener("mouseleave", () => {
      bulkPropsTooltip.style.display = "none";
    });

    // Keep tooltip visible when hovering over it
    bulkPropsTooltip.addEventListener("mouseenter", () => {
      bulkPropsTooltip.style.display = "block";
    });

    bulkPropsTooltip.addEventListener("mouseleave", () => {
      bulkPropsTooltip.style.display = "none";
    });
  }

  // Function to update tooltip content
  function updateBulkPropsTooltip() {
    const scenarioValue = elements.bulkScenarioType?.value || "";
    const executionValue = elements.bulkExecutionType?.value || "";
    const tagsValue = elements.bulkTags?.value.trim() || "";

    const tooltipScenario = document.getElementById("tooltipScenario");
    const tooltipExecution = document.getElementById("tooltipExecution");
    const tooltipTags = document.getElementById("tooltipTags");

    if (tooltipScenario) {
      tooltipScenario.textContent = scenarioValue || "Not set";
      tooltipScenario.style.color = scenarioValue ? "#60a5fa" : "#94a3b8";
    }

    if (tooltipExecution) {
      tooltipExecution.textContent = executionValue || "Not set";
      tooltipExecution.style.color = executionValue ? "#60a5fa" : "#94a3b8";
    }

    if (tooltipTags) {
      tooltipTags.textContent = tagsValue || "Not set";
      tooltipTags.style.color = tagsValue ? "#60a5fa" : "#94a3b8";
    }
  }

  // Update tooltip when fields change
  if (elements.bulkScenarioType) {
    elements.bulkScenarioType.addEventListener(
      "change",
      updateBulkPropsTooltip,
    );
  }

  if (elements.bulkExecutionType) {
    elements.bulkExecutionType.addEventListener(
      "change",
      updateBulkPropsTooltip,
    );
  }

  if (elements.bulkTags) {
    elements.bulkTags.addEventListener("input", updateBulkPropsTooltip);
  }

  // Bulk Cycle Run
  if (elements.applyBulkCycle) {
    elements.applyBulkCycle.addEventListener("click", () => {
      const cycleName = elements.bulkCycleName.value;
      const cycleDate = elements.bulkCycleDate.value;
      const assignee = elements.bulkCycleAssignee.value;
      const status = elements.bulkCycleStatus.value;

      if (!cycleName || !cycleDate)
        return alert("Please enter Cycle Number or Date");

      const checked = document.querySelectorAll(".tc-checkbox:checked");
      if (checked.length === 0) return alert("Select test cases first");

      let updateCount = 0;
      let skipCount = 0;

      checked.forEach((cb) => {
        const { stid, pid, sid, tid } = cb.dataset;

        let tc;
        if (
          generatedTestCases.schemaLevel === "6" &&
          stid != null &&
          stid !== "null"
        ) {
          tc =
            generatedTestCases.strategies[stid].plans[pid].suites[sid]
              .testCases[tid];
        } else {
          tc = generatedTestCases.plans[pid].suites[sid].testCases[tid];
        }

        if (!tc.evidenceHistory) tc.evidenceHistory = [];

        // Check for duplicate Run before inserting
        const runExists = tc.evidenceHistory.some(
          (h) => String(h.cycle).trim() === String(cycleName).trim(),
        );

        if (runExists) {
          skipCount++;
          return; // Skip adding this run to this specific test case
        }

        // Add new run to TOP of history (Current)
        tc.evidenceHistory.unshift({
          cycle: cycleName,
          cycleDate: cycleDate,
          assignee: assignee || "Unassigned",
          status: status,
        });

        // Also update generic fields to match current run
        if (assignee) tc.assignee = assignee;
        updateCount++;
      });

      refreshAllUI();
      if (window.mdEditorBridge) window.mdEditorBridge.syncCurrentFile();
      // Reset Select All checkbox
      if (elements.selectAllTcs) elements.selectAllTcs.checked = false;
      updateSelectedCount();

      if (skipCount > 0) {
        alert(
          `Successfully added Run to ${updateCount} test cases. Skipped ${skipCount} cases because they already had this Run.`,
        );
      }

      // Visual Success Message on Button
      const btn = elements.applyBulkCycle;
      const originalHtml = btn.innerHTML;
      const originalBg = btn.style.backgroundColor;
      const originalBorder = btn.style.borderColor;

      btn.innerHTML = '<i class="fas fa-check-circle"></i> Success!';
      btn.style.backgroundColor = "#10b981"; // Green
      btn.style.borderColor = "#10b981";
      btn.style.color = "white";

      setTimeout(() => {
        btn.innerHTML = originalHtml;
        btn.style.backgroundColor = originalBg;
        btn.style.borderColor = originalBorder;
        btn.style.color = "";
      }, 2000);
    });
  }

  // Bulk Edit Modal Opening
  if (elements.bulkEditBtn && elements.bulkEditModal) {
    elements.bulkEditBtn.addEventListener("click", () => {
      const checked = document.querySelectorAll(".tc-checkbox:checked");
      if (checked.length === 0) return alert("Select test cases first");

      // Reset form
      const fields = [
        "bulkEditAssignee",
        "bulkEditPriority",
        "bulkEditScenarioType",
        "bulkEditExecutionType",
        "bulkEditTags",
      ];
      fields.forEach((id) => {
        const el = document.getElementById(id);
        if (el) el.value = "";
      });

      elements.bulkEditModal.classList.add("active");
    });
  }

  // Bulk Edit Modal Closing
  if (elements.closeBulkEdit)
    elements.closeBulkEdit.addEventListener("click", () =>
      elements.bulkEditModal.classList.remove("active"),
    );
  if (elements.cancelBulkEdit)
    elements.cancelBulkEdit.addEventListener("click", () =>
      elements.bulkEditModal.classList.remove("active"),
    );

  // Bulk Edit Tag Helper
  if (elements.bulkEditTagsSelect) {
    elements.bulkEditTagsSelect.addEventListener("change", (e) => {
      const val = e.target.value;
      if (!val) return;
      const input = document.getElementById("bulkEditTags");
      if (input) {
        const current = input.value.trim();
        if (current) {
          if (!current.includes(val)) input.value = current + ", " + val;
        } else {
          input.value = val;
        }
      }
      e.target.value = "";
    });
  }

  // Save Bulk Edit
  if (elements.saveBulkEdit) {
    elements.saveBulkEdit.addEventListener("click", () => {
      const assignee = document.getElementById("bulkEditAssignee").value;
      const priority = document.getElementById("bulkEditPriority").value;
      const scenario = document.getElementById("bulkEditScenarioType").value;
      const execution = document.getElementById("bulkEditExecutionType").value;
      const tagsTxt = document.getElementById("bulkEditTags").value;

      if (!assignee && !priority && !scenario && !execution && !tagsTxt) {
        return alert("Please change at least one value");
      }

      const checked = document.querySelectorAll(".tc-checkbox:checked");
      checked.forEach((cb) => {
        const { stid, pid, sid, tid } = cb.dataset;

        let tc;
        if (
          generatedTestCases.schemaLevel === "6" &&
          stid != null &&
          stid !== "null"
        ) {
          tc =
            generatedTestCases.strategies[stid].plans[pid].suites[sid]
              .testCases[tid];
        } else {
          tc = generatedTestCases.plans[pid].suites[sid].testCases[tid];
        }

        if (assignee) {
          tc.assignee = assignee;
          // Sync with Evidence History (current active cycle)
          if (!tc.evidenceHistory) tc.evidenceHistory = [];
          if (tc.evidenceHistory.length > 0) {
            tc.evidenceHistory[0].assignee = assignee;
          } else {
            // Create default if missing
            tc.evidenceHistory.push({
              cycle: "1.0", // Default or grab global
              cycleDate: new Date().toISOString().split("T")[0],
              status: "To-do",
              assignee: assignee,
            });
          }
        }
        if (priority) tc.priority = priority;
        if (scenario) tc.scenarioType = scenario;
        if (execution) tc.executionType = execution;

        if (tagsTxt) {
          const newTags = tagsTxt
            .split(",")
            .map((t) => t.trim())
            .filter((t) => {
              if (!t) return false;
              if (t.toLowerCase() === "null") return false;
              // Reject if only special characters (no alphanumeric)
              if (/^[^a-zA-Z0-9]+$/.test(t)) return false;
              return true;
            });
          const currentTags = cleanTags(tc.tags);
          newTags.forEach((nt) => {
            if (!currentTags.includes(nt)) currentTags.push(nt);
          });
          tc.tags = currentTags;
        }
      });

      refreshAllUI();
      // Reset Select All checkbox
      if (elements.selectAllTcs) elements.selectAllTcs.checked = false;
      updateSelectedCount();

      // Show message first, then close
      alert(`Updated ${checked.length} test cases.`);
      elements.bulkEditModal.classList.remove("active");
    });
  }

  // Bulk Delete
  if (elements.bulkDeleteBtn) {
    elements.bulkDeleteBtn.addEventListener("click", window.handleBulkDelete);
  }

  // Select All Checkbox
  if (elements.selectAllTcs) {
    elements.selectAllTcs.addEventListener("change", (e) => {
      const checkboxes = document.querySelectorAll(".tc-checkbox");
      checkboxes.forEach((cb) => {
        cb.checked = e.target.checked;
      });
      updateSelectedCount();
    });
  }

  // ===== Edit Modal Listeners (Moved here) =====
  if (document.getElementById("closeModal")) {
    document.getElementById("closeModal").addEventListener("click", () => {
      document.getElementById("editModal").classList.remove("active");
    });
  }
  if (document.getElementById("cancelEdit")) {
    document.getElementById("cancelEdit").addEventListener("click", () => {
      document.getElementById("editModal").classList.remove("active");
    });
  }

  if (document.getElementById("saveEdit")) {
    document
      .getElementById("saveEdit")
      .addEventListener("click", handleSaveTestCaseEdit);
  }

  // ===== Centralized Event Delegation for Dynamic Content (CSP Fix) =====
  document.addEventListener("click", (e) => {
    const target = e.target.closest("[data-action]");
    if (!target) return;

    const action = target.dataset.action;
    const stIdx =
      target.dataset.stid === "null" ? null : parseInt(target.dataset.stid);
    const pIdx = parseInt(target.dataset.pid);
    const sIdx = parseInt(target.dataset.sid);
    const tIdx = parseInt(target.dataset.tid);
    const evid = parseInt(target.dataset.evid);

    switch (action) {
      case "closeSmartCaseModal":
        const scm = document.getElementById("smartTestCaseModal");
        if (scm) scm.style.display = "none";
        break;
      case "closeSmartSuiteModal":
        const ssm = document.getElementById("smartSuiteModal");
        if (ssm) ssm.style.display = "none";
        break;
      case "closeSmartPlanModal":
        const spm = document.getElementById("smartPlanModal");
        if (spm) spm.style.display = "none";
        break;
      case "toggleTree":
        target.parentElement.parentElement.classList.toggle("open");
        break;
      case "addPlan":
        window.handleAddPlan(stIdx);
        break;
      case "editPlan":
        window.openPlanEditModal(stIdx, pIdx);
        break;
      case "deletePlan":
        window.handleDeletePlan(stIdx, pIdx);
        break;
      case "addSuite":
        window.handleAddSuite(stIdx, pIdx);
        break;
      case "editSuite":
        window.openSuiteEditModal(stIdx, pIdx, sIdx);
        break;
      case "deleteSuite":
        window.handleDeleteSuite(stIdx, pIdx, sIdx);
        break;
      case "addTestCase":
        window.handleAddTestCase(stIdx, pIdx, sIdx);
        break;
      case "editTestCase":
        window.openEditModal(stIdx, pIdx, sIdx, tIdx);
        break;
      case "deleteTestCase":
        window.handleDeleteTestCase(stIdx, pIdx, sIdx, tIdx);
        break;
      case "deleteEvidence":
        window.handleDeleteEvidence(stIdx, pIdx, sIdx, tIdx, evid);
        break;
    }
  });

  // Handle onchange for delegated selectors
  document.addEventListener("change", (e) => {
    const target = e.target.closest("[data-action]");
    if (!target) return;

    const action = target.dataset.action;
    const stIdx =
      target.dataset.stid === "null" ? null : parseInt(target.dataset.stid);
    const pIdx = parseInt(target.dataset.pid);
    const sIdx = parseInt(target.dataset.sid);
    const tIdx = parseInt(target.dataset.tid);

    if (action === "quickPriority") {
      window.handleQuickPriority(stIdx, pIdx, sIdx, tIdx, target.value);
    } else if (action === "quickAssign") {
      window.handleQuickAssign(stIdx, pIdx, sIdx, tIdx, target.value);
    }
  });
}

function updateSelectedCount() {
  const count = document.querySelectorAll(".tc-checkbox:checked").length;
  if (elements.selectedCountText) {
    elements.selectedCountText.textContent = `${count} selected`;
  }
}

// ===== Plan/Suite Editing Logic =====
let currentEditingStrategyIndex = -1;
let currentEditingPlanIndex = -1;
let currentEditingSuiteIndex = -1;

// Modals
const planEditModal = document.getElementById("planEditModal");
const suiteEditModal = document.getElementById("suiteEditModal");

// Inputs
const editPlanName = document.getElementById("editPlanName");
const editPlanId = document.getElementById("editPlanId");
const editPlanDate = document.getElementById("editPlanDate");
const editPlanCreatedBy = document.getElementById("editPlanCreatedBy");
const editPlanDescription = document.getElementById("editPlanDescription");
const editPlanYaml = document.getElementById("editPlanYaml");

const editSuiteName = document.getElementById("editSuiteName");
const editSuiteId = document.getElementById("editSuiteId");
const editSuiteDate = document.getElementById("editSuiteDate");
const editSuiteCreatedBy = document.getElementById("editSuiteCreatedBy");
const editSuiteDescription = document.getElementById("editSuiteDescription");
const editSuiteYaml = document.getElementById("editSuiteYaml");

// Event Listeners for new modals
if (planEditModal) {
  document
    .getElementById("closePlanEdit")
    .addEventListener("click", () => closeAnyModal(planEditModal));
  document
    .getElementById("cancelPlanEdit")
    .addEventListener("click", () => closeAnyModal(planEditModal));
  document
    .getElementById("savePlanEdit")
    .addEventListener("click", savePlanChanges);

  // Live YAML Update Listeners
  if (editPlanName) {
    editPlanName.addEventListener("input", updatePlanYamlFromInputs);
  }
  if (editPlanDate) {
    editPlanDate.addEventListener("change", updatePlanYamlFromInputs);
  }
  if (editPlanCreatedBy) {
    editPlanCreatedBy.addEventListener("change", updatePlanYamlFromInputs);
  }
}

if (suiteEditModal) {
  document
    .getElementById("closeSuiteEdit")
    .addEventListener("click", () => closeAnyModal(suiteEditModal));
  document
    .getElementById("cancelSuiteEdit")
    .addEventListener("click", () => closeAnyModal(suiteEditModal));
  document
    .getElementById("saveSuiteEdit")
    .addEventListener("click", saveSuiteChanges);

  // Live YAML Update Listeners
  if (editSuiteName) {
    editSuiteName.addEventListener("input", updateSuiteYamlFromInputs);
  }
  if (editSuiteDate) {
    editSuiteDate.addEventListener("change", updateSuiteYamlFromInputs);
  }
  if (editSuiteCreatedBy) {
    editSuiteCreatedBy.addEventListener("change", updateSuiteYamlFromInputs);
  }
}

function updateSuiteYamlFromInputs() {
  if (!editSuiteYaml) return;

  // 1. Parse current YAML to preserve extra keys
  const currentYaml = editSuiteYaml.value;
  const metaObj = {};
  if (currentYaml) {
    currentYaml.split("\n").forEach((line) => {
      const parts = line.split(":");
      if (parts.length >= 2) {
        const k = parts[0].trim();
        const v = parts.slice(1).join(":").trim();
        if (k && v) metaObj[k] = v;
      }
    });
  }

  // 2. Override with new input values
  if (editSuiteName) metaObj["suite-name"] = editSuiteName.value.trim();
  if (editSuiteDate) metaObj["suite-date"] = editSuiteDate.value;
  if (editSuiteCreatedBy) metaObj["created-by"] = editSuiteCreatedBy.value;

  // 3. Reconstruct YAML string (Core keys first)
  const lines = [];
  if (metaObj["suite-name"])
    lines.push(`  suite-name: ${metaObj["suite-name"]}`);
  if (metaObj["suite-date"])
    lines.push(`  suite-date: ${metaObj["suite-date"]}`);
  if (metaObj["created-by"])
    lines.push(`  created-by: ${metaObj["created-by"]}`);

  const coreKeys = ["suite-name", "suite-date", "created-by"];
  for (const k in metaObj) {
    if (!coreKeys.includes(k)) {
      lines.push(`  ${k}: ${metaObj[k]}`);
    }
  }

  editSuiteYaml.value = lines.join("\n");
}

// Helper to open/close
function closeAnyModal(modal) {
  if (modal) modal.classList.remove("active");
}

// Window functions for Inline OnClick
window.openPlanEditModal = function (stIdx, pIdx) {
  currentEditingStrategyIndex = stIdx;
  currentEditingPlanIndex = pIdx;

  let plan;
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null"
  ) {
    plan = generatedTestCases.strategies[stIdx].plans[pIdx];
  } else {
    if (!generatedTestCases || !generatedTestCases.plans[pIdx]) return;
    plan = generatedTestCases.plans[pIdx];
  }

  // Dynamic Modal Title / Labels
  const isProject = ["3", "4"].includes(generatedTestCases.schemaLevel);
  const modalHeader = planEditModal.querySelector(".modal-header h3");
  if (modalHeader) {
    modalHeader.innerText = isProject
      ? "Edit Project Details"
      : "Edit Plan Details";
  }
  const nameLabel =
    planEditModal.querySelector("label[for='editPlanName']") ||
    planEditModal.querySelector(".form-group label");
  if (nameLabel) {
    nameLabel.innerText = isProject ? "Project Name" : "Plan Name";
  }
  const idLabel =
    planEditModal.querySelector("label[for='editPlanId']") ||
    planEditModal.querySelectorAll(".form-group label")[1];
  if (idLabel) {
    idLabel.innerText = isProject ? "Project ID (@id)" : "Plan ID (@id)";
  }
  const dateLabel =
    planEditModal.querySelector("label[for='editPlanDate']") ||
    planEditModal.querySelectorAll(".form-group label")[2];
  if (dateLabel) {
    dateLabel.innerText = isProject ? "Project Date" : "Plan Date";
  }

  // Fill Data
  editPlanName.value = plan.planName;
  if (editPlanId) editPlanId.value = plan.planId || plan.id || "";
  editPlanDescription.value = plan.description || "";

  // Parse Metadata for Date/Creator
  let meta = plan.yamlMetadata || {};
  if (typeof meta === "string") {
    const temp = {};
    meta.split("\n").forEach((line) => {
      const [k, v] = line.split(":");
      if (k && v) temp[k.trim()] = v.trim();
    });
    meta = temp;
  }

  if (editPlanDate) {
    const isoDate =
      meta.createdDate ||
      plan.planDate ||
      new Date().toISOString().split("T")[0];
    setDualDateInput(editPlanDate, isoDate);
  }

  // Populate Creator & Select
  if (editPlanCreatedBy) {
    let assigneeMaster = JSON.parse(localStorage.getItem("qf_assignee_master"));
    if (!Array.isArray(assigneeMaster)) {
      assigneeMaster = [
        { name: "Mahesh Prabhu", designation: "Lead QA" },
        { name: "Arun K R", designation: "Senior QA" },
        { name: "Dencymol Puthiyaparambil", designation: "QA Engineer" },
        { name: "Rahul Raj", designation: "QA Engineer" },
        { name: "User", designation: "QA" },
      ];
    }
    editPlanCreatedBy.innerHTML = assigneeMaster
      .map((u) => `<option value="${u.name}">${u.name}</option>`)
      .join("");

    if (meta.createdBy) {
      editPlanCreatedBy.value = meta.createdBy;
    } else if (plan.planCreatedBy) {
      editPlanCreatedBy.value = plan.planCreatedBy;
    }
  }

  // Convert metadata object to YAML string if exists, or use raw string if stored
  if (editPlanYaml) {
    const pName = plan.planName || "";
    const pDate = plan.planDate || new Date().toISOString().split("T")[0];
    const pCreatedBy = plan.planCreatedBy || "User";

    let yamlStr = `  plan-name: ${pName}\n  plan-date: ${pDate}\n  created-by: ${pCreatedBy}`;

    // Append extra metadata if it exists
    if (plan.yamlMetadata && typeof plan.yamlMetadata === "object") {
      for (let k in plan.yamlMetadata) {
        if (
          ![
            "plan-name",
            "plan-date",
            "created-by",
            "createdDate",
            "createdBy",
          ].includes(k)
        ) {
          yamlStr += `\n  ${k}: ${plan.yamlMetadata[k]}`;
        }
      }
    }
    editPlanYaml.value = yamlStr;
  }

  // Show Modal
  planEditModal.classList.add("active");
};

function updatePlanYamlFromInputs() {
  if (!editPlanYaml) return;

  // 1. Parse current YAML to preserve extra keys
  const currentYaml = editPlanYaml.value;
  const metaObj = {};
  if (currentYaml) {
    currentYaml.split("\n").forEach((line) => {
      const parts = line.split(":");
      if (parts.length >= 2) {
        const k = parts[0].trim();
        const v = parts.slice(1).join(":").trim();
        if (k && v) metaObj[k] = v;
      }
    });
  }

  // 2. Override with new input values
  if (editPlanName) metaObj["plan-name"] = editPlanName.value.trim();
  if (editPlanDate) metaObj["plan-date"] = editPlanDate.value;
  if (editPlanCreatedBy) metaObj["created-by"] = editPlanCreatedBy.value;

  // 3. Reconstruct YAML string (Core keys first)
  const lines = [];
  if (metaObj["plan-name"]) lines.push(`  plan-name: ${metaObj["plan-name"]}`);
  if (metaObj["plan-date"]) lines.push(`  plan-date: ${metaObj["plan-date"]}`);
  if (metaObj["created-by"])
    lines.push(`  created-by: ${metaObj["created-by"]}`);

  const coreKeys = ["plan-name", "plan-date", "created-by"];
  for (const k in metaObj) {
    if (!coreKeys.includes(k)) {
      lines.push(`  ${k}: ${metaObj[k]}`);
    }
  }

  editPlanYaml.value = lines.join("\n");
}

window.openSuiteEditModal = function (stIdx, pIdx, sIdx) {
  currentEditingStrategyIndex = stIdx;
  currentEditingPlanIndex = pIdx;
  currentEditingSuiteIndex = sIdx;

  let suite;
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null"
  ) {
    if (!generatedTestCases.strategies[stIdx].plans[pIdx]) return;
    suite = generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx];
  } else {
    if (
      !generatedTestCases ||
      !generatedTestCases.plans[pIdx] ||
      !generatedTestCases.plans[pIdx].suites[sIdx]
    )
      return;
    suite = generatedTestCases.plans[pIdx].suites[sIdx];
  }

  if (!suite) return;

  // Fill Data
  editSuiteName.value = suite.suiteName;
  if (editSuiteId) editSuiteId.value = suite.suiteId || suite.id || "";
  editSuiteDescription.value = suite.description || "";

  // Parse Metadata for Date/Creator
  let meta = suite.yamlMetadata || {};
  if (typeof meta === "string") {
    const temp = {};
    meta.split("\n").forEach((line) => {
      const [k, v] = line.split(":");
      if (k && v) temp[k.trim()] = v.trim();
    });
    meta = temp;
  }

  if (editSuiteDate) {
    const isoDate = meta.createdDate || new Date().toISOString().split("T")[0];
    setDualDateInput(editSuiteDate, isoDate);
  }

  // Populate Creator & Select
  if (editSuiteCreatedBy) {
    let assigneeMaster = JSON.parse(localStorage.getItem("qf_assignee_master"));
    if (!Array.isArray(assigneeMaster)) {
      assigneeMaster = [
        { name: "Mahesh Prabhu", designation: "Lead QA" },
        { name: "Arun K R", designation: "Senior QA" },
        { name: "Dencymol Puthiyaparambil", designation: "QA Engineer" },
        { name: "Rahul Raj", designation: "QA Engineer" },
        { name: "User", designation: "QA" },
      ];
    }
    editSuiteCreatedBy.innerHTML = assigneeMaster
      .map((u) => `<option value="${u.name}">${u.name}</option>`)
      .join("");

    if (meta.createdBy) {
      editSuiteCreatedBy.value = meta.createdBy;
    } else {
      // Try fallback to local storage default? Or just first option.
      // Maybe plan creator?
    }
  }

  if (editSuiteYaml) {
    const sName = suite.suiteName || "";
    const sDate = suite.suiteDate || new Date().toISOString().split("T")[0];
    const sCreatedBy = suite.suiteCreatedBy || "User";

    let yamlStr = `  suite-name: ${sName}\n  suite-date: ${sDate}\n  created-by: ${sCreatedBy}`;

    // Append extra metadata if it exists
    if (suite.yamlMetadata && typeof suite.yamlMetadata === "object") {
      for (let k in suite.yamlMetadata) {
        if (
          ![
            "suite-name",
            "suite-date",
            "created-by",
            "createdDate",
            "createdBy",
          ].includes(k)
        ) {
          yamlStr += `\n  ${k}: ${suite.yamlMetadata[k]}`;
        }
      }
    }
    editSuiteYaml.value = yamlStr;
  }

  // Show Modal
  suiteEditModal.classList.add("active");
};

// Handle Delete Evidence (Cycle) from TreeView
window.handleDeleteEvidence = function (stIdx, pIdx, sIdx, tIdx, evIdx) {
  if (!confirm("Are you sure you want to delete this result/cycle?")) return;

  let tc;
  // stIdx might be 'null' (string) or actual null. Check strictly.
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null"
  ) {
    if (
      !generatedTestCases.strategies[stIdx] ||
      !generatedTestCases.strategies[stIdx].plans[pIdx]
    )
      return;
    tc =
      generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx].testCases[
      tIdx
      ];
  } else {
    // 3, 4, 5 levels: plans -> suites -> testCases
    if (
      !generatedTestCases ||
      !generatedTestCases.plans[pIdx] ||
      !generatedTestCases.plans[pIdx].suites[sIdx]
    )
      return;
    tc = generatedTestCases.plans[pIdx].suites[sIdx].testCases[tIdx];
  }

  if (tc && tc.evidenceHistory) {
    tc.evidenceHistory.splice(evIdx, 1);
    refreshAllUI();
  }
};

// Save handlers
function savePlanChanges() {
  if (currentEditingPlanIndex === -1) return;

  // 1. Parse YAML first (Source of Truth for "Advanced" edits)
  let currentYamlText = editPlanYaml ? editPlanYaml.value : "";
  let metaObj = {};
  if (currentYamlText) {
    currentYamlText.split("\n").forEach((line) => {
      const parts = line.split(":");
      if (parts.length >= 2) {
        const k = parts[0].trim();
        const v = parts.slice(1).join(":").trim();
        if (k && v) metaObj[k] = v;
      }
    });
  }

  // 2. Identify Core Props (Prefer YAML, fallback to Input)
  const nameFromYaml = metaObj["plan-name"];
  const dateFromYaml = metaObj["plan-date"];
  const creatorFromYaml = metaObj["created-by"];

  const newName = nameFromYaml || editPlanName.value.trim();
  const newDate = dateFromYaml || editPlanDate.value;
  const newCreator = creatorFromYaml || editPlanCreatedBy.value;

  if (!newName) {
    alert("Plan name cannot be empty");
    return;
  }

  // Update Data
  let plan;
  if (
    generatedTestCases.schemaLevel === "6" &&
    currentEditingStrategyIndex != null &&
    currentEditingStrategyIndex !== -1 &&
    currentEditingStrategyIndex !== "null"
  ) {
    plan =
      generatedTestCases.strategies[currentEditingStrategyIndex].plans[
      currentEditingPlanIndex
      ];
  } else {
    plan = generatedTestCases.plans[currentEditingPlanIndex];
  }

  plan.planName = newName;
  plan.planDate = newDate;
  plan.planCreatedBy = newCreator;

  if (editPlanId) plan.planId = editPlanId.value.trim();
  plan.description = editPlanDescription.value;

  // 3. Save Remaining Metadata (Exclude core keys)
  const coreKeys = [
    "plan-name",
    "plan-date",
    "created-by",
    "createdDate",
    "createdBy",
  ];
  let finalMeta = {};
  for (let k in metaObj) {
    if (!coreKeys.includes(k)) {
      finalMeta[k] = metaObj[k];
    }
  }

  plan.yamlMetadata = finalMeta;

  refreshAllUI();
  closeAnyModal(planEditModal);
}

function saveSuiteChanges() {
  if (currentEditingPlanIndex === -1 || currentEditingSuiteIndex === -1) return;

  // 1. Parse YAML first (Source of Truth for "Advanced" edits)
  let currentYamlText = editSuiteYaml ? editSuiteYaml.value : "";
  let metaObj = {};
  if (currentYamlText) {
    currentYamlText.split("\n").forEach((line) => {
      const parts = line.split(":");
      if (parts.length >= 2) {
        const k = parts[0].trim();
        const v = parts.slice(1).join(":").trim(); // Handle values with colons
        if (k && v) metaObj[k] = v;
      }
    });
  }

  // 2. Identify Core Props (Prefer YAML, fallback to Input)
  // Note: We use the input value if the key is MISSING in YAML for some reason.
  // But if it IS in YAML, we use that.
  const nameFromYaml = metaObj["suite-name"];
  const dateFromYaml = metaObj["suite-date"];
  const creatorFromYaml = metaObj["created-by"];

  const newName = nameFromYaml || editSuiteName.value.trim();
  const newDate = dateFromYaml || editSuiteDate.value;
  const newCreator = creatorFromYaml || editSuiteCreatedBy.value;

  if (!newName) {
    alert("Suite name cannot be empty");
    return;
  }

  // Update Data
  let suite;
  if (
    generatedTestCases.schemaLevel === "6" &&
    currentEditingStrategyIndex != null &&
    currentEditingStrategyIndex !== -1 &&
    currentEditingStrategyIndex !== "null"
  ) {
    suite =
      generatedTestCases.strategies[currentEditingStrategyIndex].plans[
        currentEditingPlanIndex
      ].suites[currentEditingSuiteIndex];
  } else {
    suite =
      generatedTestCases.plans[currentEditingPlanIndex].suites[
      currentEditingSuiteIndex
      ];
  }

  suite.suiteName = newName;
  suite.suiteDate = newDate;
  suite.suiteCreatedBy = newCreator;

  if (editSuiteId) suite.suiteId = editSuiteId.value.trim();
  suite.description = editSuiteDescription.value;

  // 3. Save Remaining Metadata (Exclude core keys)
  const coreKeys = [
    "suite-name",
    "suite-date",
    "created-by",
    "createdDate",
    "createdBy",
  ];
  let finalMeta = {};
  for (let k in metaObj) {
    if (!coreKeys.includes(k)) {
      finalMeta[k] = metaObj[k];
    }
  }
  suite.yamlMetadata = finalMeta;

  // Refresh UI
  refreshAllUI();
  closeAnyModal(suiteEditModal);
}

// ===== Adding New Entities Logic =====

window.handleAddSuite = function (stIdx, pIdx) {
  if (!confirm("Are you sure you want to add a new Suite?")) return;

  let plan;
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null" &&
    stIdx !== null
  ) {
    plan = generatedTestCases.strategies[stIdx].plans[pIdx];
  } else {
    plan = generatedTestCases.plans[pIdx];
  }

  if (!plan) return;

  let newSuite = {
    suiteName: "New Suite",
    suiteId: "",
    description: "",
    testCases: [],
  };

  // CLONE LOGIC: If there is a previous suite, copy its details
  if (plan.suites.length > 0) {
    const prevSuite = plan.suites[plan.suites.length - 1];
    newSuite = {
      ...JSON.parse(JSON.stringify(prevSuite)), // Deep clone to avoid ref issues
      suiteName: prevSuite.suiteName + " (Copy)",
      suiteId: prevSuite.suiteId ? prevSuite.suiteId + "-COPY" : "",
      // We generally want to start with empty test cases for a new suite, or clone them?
      // User request: "create it with the previous suite info".
      // Usually this implies metadata, but maybe not 100% of test cases.
      // Let's keep test cases empty to avoid massive duplication unless requested.
      testCases: [],
    };
  }

  plan.suites.push(newSuite);
  renderTestCasesList();
  renderTreeView();
  updateExports();
  alert("New Suite added successfully (cloned from previous).");
};

// ==========================================
// SMART ADD TEST CASE LOGIC
// ==========================================

// AI Refine Requirements (Match Generator Logic)
function runAiRefine(textarea, btnId, countInputId) {
  if (!textarea.value.trim()) {
    alert("Please enter some text to refine.");
    return;
  }

  let text = textarea.value;

  // 1. Split into lines (handle various bullet formats and sentence breaks)
  let lines = text
    .split(/[\n•\-\*]+|(?<=\.)\s+/)
    .map((l) => l.trim())
    .filter((l) => l.length > 3);

  // 2. Remove duplicates (case-insensitive)
  const uniqueMap = new Map();
  lines.forEach((l) => uniqueMap.set(l.toLowerCase(), l));
  lines = Array.from(uniqueMap.values());

  // 3. AI Expansion Logic - Context-aware suggestions
  if (lines.length < 10) {
    const combinedText = lines.join(" ").toLowerCase();

    if (
      combinedText.includes("login") ||
      combinedText.includes("auth") ||
      combinedText.includes("sign in") ||
      combinedText.includes("forgot")
    ) {
      lines.push("Verify proper validation messages for invalid credentials");
      lines.push('Check password masking and "forgot password" functionality');
      lines.push("Ensure session timeout works as expected");
      lines.push('Test "remember me" functionality if applicable');
      lines.push("Verify account lockout after multiple failed attempts");
    } else if (
      combinedText.includes("search") ||
      combinedText.includes("find")
    ) {
      lines.push("Verify search results relevance and accuracy");
      lines.push("Check search functionality with special characters");
      lines.push('Validate "no results found" state');
      lines.push("Test search filters and sorting options");
    } else if (
      combinedText.includes("form") ||
      combinedText.includes("input") ||
      combinedText.includes("submit")
    ) {
      lines.push("Validate all required field validations");
      lines.push("Verify proper error messages for invalid inputs");
      lines.push("Check form submission with valid and invalid data");
      lines.push("Test form reset and cancel functionality");
    } else if (
      combinedText.includes("payment") ||
      combinedText.includes("checkout")
    ) {
      lines.push("Verify payment gateway integration");
      lines.push("Test transaction success and failure scenarios");
      lines.push("Validate confirmation receipt generation");
      lines.push("Verify secure handling of payment information");
    } else if (
      combinedText.includes("upload") ||
      combinedText.includes("download") ||
      combinedText.includes("file")
    ) {
      lines.push("Verify supported file formats and size limits");
      lines.push("Test upload progress indication");
      lines.push("Check file validation and virus scanning");
      lines.push("Validate download functionality");
    } else if (
      combinedText.includes("api") ||
      combinedText.includes("endpoint")
    ) {
      lines.push("Verify API response codes (200, 400, 401, 500)");
      lines.push("Test API authentication mechanisms");
      lines.push("Validate request/response payload structure");
    } else if (lines.length < 3) {
      lines.push("Verify UI responsiveness across different screen sizes");
      lines.push("Ensure proper error handling for network interruptions");
      lines.push("Validate input field boundary values");
      lines.push("Check browser compatibility");
      lines.push("Verify proper loading states");
    }
  }

  // 4. Capitalize and format with bullet points
  lines = lines.map((l) => {
    let clean = l.charAt(0).toUpperCase() + l.slice(1);
    if (!clean.endsWith(".")) clean += ".";
    return `• ${clean}`;
  });

  // Update textarea
  textarea.value = lines.join("\n");

  // Update count if exists
  const countInputRef = document.getElementById(countInputId);
  if (countInputRef) countInputRef.value = lines.length;

  // Visual Feedback
  const btn = document.getElementById(btnId);
  if (btn) {
    const originalHtml = btn.innerHTML;
    btn.innerHTML = '<i class="fas fa-check"></i> Refined!';
    btn.classList.add("text-success");
    setTimeout(() => {
      btn.innerHTML = originalHtml;
      btn.classList.remove("text-success");
    }, 2000);
  }
}

// ===== Global Helper: Get Project Max ID =====
window.getProjectMaxId = function () {
  let maxId = 0;
  const prefix =
    generatedTestCases && generatedTestCases.testCasePrefix
      ? generatedTestCases.testCasePrefix
      : "TC";

  function scan(items) {
    if (!items) return;
    items.forEach((item) => {
      if (item.testCases) {
        item.testCases.forEach((tc) => {
          const idStr = tc.testCaseId || tc.id || "";
          if (idStr.startsWith(prefix)) {
            const numPart = parseInt(idStr.replace(prefix + "-", ""), 10);
            if (!isNaN(numPart) && numPart > maxId) {
              maxId = numPart;
            }
          }
        });
      }
      if (item.plans) scan(item.plans);
      if (item.suites) scan(item.suites);
      if (item.strategies) scan(item.strategies);
    });
  }

  if (generatedTestCases) {
    if (
      generatedTestCases.schemaLevel === "6" &&
      generatedTestCases.strategies
    ) {
      scan(generatedTestCases.strategies);
    } else if (generatedTestCases.plans) {
      scan(generatedTestCases.plans);
    }
  }
  return { maxId, prefix };
};

window.handleAddTestCase = function (stIdx, pIdx, sIdx) {
  if (!document.getElementById("smartTestCaseModal")) {
    const modalHtml = `
        <div id="smartTestCaseModal" class="modal-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); z-index:1000; justify-content:center; align-items:center;">
            <div class="modal-content" style="background:var(--bg-card); padding:2rem; border-radius:8px; width:95%; max-width:800px; color:var(--text-primary); max-height:90vh; overflow-y:auto;">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1.5rem; border-bottom:1px solid var(--border-color); padding-bottom:1rem;">
                    <h2 style="margin:0;">Add / Generate Test Cases</h2>
                    <button data-action="closeSmartCaseModal" style="background:none; border:none; color:var(--text-primary); font-size:1.5rem; cursor:pointer;">&times;</button>
                </div>
                
                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1.5rem; margin-bottom:1.5rem;">
                     <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">Default Creator</label>
                        <select id="smartTCCreator" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                             <!-- Populated via JS -->
                        </select>
                    </div>
                     <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">Test Type</label>
                        <select id="smartTCType" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                             <option value="Functional">Functional</option>
                             <option value="Regression">Regression</option>
                             <option value="Smoke">Smoke</option>
                             <option value="Performance">Performance</option>
                             <option value="Security">Security</option>
                        </select>
                    </div>
                     <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">Cycle</label>
                        <input type="text" id="smartTCCycle" value="1.0" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                    </div>
                     <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">Cycle Date</label>
                        <div style="display:flex; align-items:center; position:relative;">
                            <input type="text" id="smartTCCycleDateText" class="form-input" placeholder="MM-DD-YYYY" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px; cursor:pointer;">
                            <input type="hidden" id="smartTCCycleDate">
                            <i class="fas fa-calendar-alt" style="position:absolute; right:8px; pointer-events:none; color:#94a3b8; font-size:0.85rem;"></i>
                        </div>
                    </div>
                </div>

                <div class="form-group" style="margin-bottom:1.5rem;">
                    <div style="display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:0.5rem;">
                        <label style="font-weight:bold;">Requirements</label>
                        <button id="btnAiTCReqs" class="btn btn-sm" style="background:#e8f0f5; color:#1e293b; font-size:0.8rem; padding:0.2rem 0.6rem;"><i class="fas fa-wand-magic-sparkles"></i> AI Refine</button>
                    </div>
                    <textarea id="smartTCReqs" rows="5" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;" placeholder='Enter topic (e.g. "Login") and click Auto-fill, or paste full requirements...'></textarea>
                    
                    <div style="display:flex; justify-content:flex-end; align-items:center; margin-top:0.5rem; gap:10px;">
                         <label style="font-size:0.9rem;">Count:</label>
                         <input type="number" id="smartTCCount" value="1" min="1" max="20" style="width:60px; padding:0.25rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                    </div>
                </div>
                
                <div style="display:flex; justify-content:space-between; gap:1rem; margin-top:1rem; padding-top:1rem; border-top:1px solid var(--border-color);">
                    <button id="btnAddBlankTC" class="btn btn-outline" style="border:1px solid var(--text-primary);">+ Add 1 Blank Case</button>
                    <div style="display:flex; gap:1rem;">
                        <button data-action="closeSmartCaseModal" class="btn" style="opacity:0.7;">Cancel</button>
                        <button id="btnGenerateTC" class="btn btn-primary">Generate Test Cases</button>
                    </div>
                </div>
            </div>
        </div>`;
    document.body.insertAdjacentHTML("beforeend", modalHtml);
  }

  // Element Refs
  const modal = document.getElementById("smartTestCaseModal");
  const creatorSelect = document.getElementById("smartTCCreator");
  const reqInput = document.getElementById("smartTCReqs");
  const countInput = document.getElementById("smartTCCount");

  // Populate Creator
  let assigneeMaster = JSON.parse(localStorage.getItem("qf_assignee_master"));
  if (!Array.isArray(assigneeMaster)) {
    assigneeMaster = [
      { name: "Mahesh Prabhu", designation: "Lead QA" },
      { name: "Arun K R", designation: "Senior QA" },
      { name: "Dencymol Puthiyaparambil", designation: "QA Engineer" },
      { name: "Rahul Raj", designation: "QA Engineer" },
      { name: "User", designation: "QA" },
    ];
  }
  creatorSelect.innerHTML = assigneeMaster
    .map(
      (u) => `<option value="${u.name}">${u.name} (${u.designation})</option>`,
    )
    .join("");

  // Restore last selected creator
  const lastCreator = localStorage.getItem("qf_last_smart_tc_creator");
  if (
    lastCreator &&
    Array.from(creatorSelect.options).some((opt) => opt.value === lastCreator)
  ) {
    creatorSelect.value = lastCreator;
  }

  // Reset inputs
  reqInput.value = "";
  countInput.value = "1";
  document.getElementById("smartTCCycle").value = "1.0";
  const today = new Date().toISOString().split("T")[0];
  document.getElementById("smartTCCycleDate").value = today;
  if (window.qfIsoToDisplay) {
    document.getElementById("smartTCCycleDateText").value =
      window.qfIsoToDisplay(today);
  }

  // Show Modal
  modal.style.display = "flex";

  // Attach Pikaday
  if (typeof window.qfAttachDatePicker === "function") {
    window.qfAttachDatePicker(
      document.getElementById("smartTCCycleDateText"),
      document.getElementById("smartTCCycleDate"),
      today,
    );
  }

  // Identify Suite
  let suite;
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null" &&
    stIdx !== null
  ) {
    suite = generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx];
  } else {
    suite = generatedTestCases.plans[pIdx].suites[sIdx];
  }

  // AI Refine for Test Case Requirements
  document.getElementById("btnAiTCReqs").onclick = () =>
    runAiRefine(reqInput, "btnAiTCReqs", "smartTCCount");

  // Helper to get next ID and Prefix
  function getNextIdInfo(suite) {
    if (!suite.testCases || suite.testCases.length === 0) {
      return { nextNum: 1, prefix: generatedTestCases.testCasePrefix || "TC" };
    }

    let maxId = 0;
    let lastPrefix = generatedTestCases.testCasePrefix || "TC";

    suite.testCases.forEach((tc) => {
      // Match pattern like PREFIX-0001
      // We assume the number is always at the end.
      const match = tc.testCaseId.match(/^(.*)-(\d+)$/);
      if (match) {
        lastPrefix = match[1]; // Capture everything before the last dash
        const num = parseInt(match[2]);
        if (!isNaN(num) && num > maxId) maxId = num;
      }
    });
    return { nextNum: maxId + 1, prefix: lastPrefix };
  }

  // 1. Add Blank
  document.getElementById("btnAddBlankTC").onclick = function () {
    if (!suite) return;

    const { maxId, prefix } = window.getProjectMaxId();
    const nextNum = maxId + 1;
    const paddedNum = nextNum.toString().padStart(4, "0");

    const newTC = {
      testCaseId: `${prefix}-${paddedNum}`,
      title: `New Test Case - ${paddedNum}`,
      steps: [{ step: 1, action: "Perform action", expected: "Expect result" }], // Structure fix for consistency
      expectedResult: "Expected Result",
      priority: "Medium",
      evidenceHistory: [
        {
          cycle: document.getElementById("smartTCCycle").value,
          status: "Unexecuted",
          date: document.getElementById("smartTCCycleDate").value,
          assignee: creatorSelect.value.split("(")[0].trim(),
        },
      ],
      cycle: document.getElementById("smartTCCycle").value,
      cycleDate: document.getElementById("smartTCCycleDate").value,
      assignee: creatorSelect.value.split("(")[0].trim(),
      testType: document.getElementById("smartTCType").value,
    };
    localStorage.setItem("qf_last_smart_tc_creator", creatorSelect.value);
    suite.testCases.push(newTC);
    refreshUI();
    modal.style.display = "none";
    alert("Added 1 blank test case.");
  };

  // 2. Generate
  document.getElementById("btnGenerateTC").onclick = function () {
    if (!suite) return;

    const reqsText = reqInput.value.trim();
    const count = parseInt(countInput.value) || 1;

    if (!reqsText) {
      alert("Please enter requirements to generate test cases.");
      return;
    }

    // Parse Requirements
    let requirements = reqsText
      .split(/[\n•\-\*]+|(?<=\.)\s+/)
      .map((l) => l.trim())
      .filter((l) => l.length > 5);
    if (requirements.length === 0) requirements = [reqsText];

    // Expand if needed
    while (requirements.length < count) {
      requirements.push(requirements[0] + " (Variant)");
    }

    // Start counting from next ID
    const { maxId, prefix } = window.getProjectMaxId();
    const nextNum = maxId + 1;

    // Track existing titles to avoid duplicates against suite
    const usedTitles = new Set();
    (suite.testCases || []).forEach((tc) => usedTitles.add(tc.title));

    // Generate
    const generatedCases = generateSmartTestCases(
      requirements,
      count,
      nextNum,
      {
        testCasePrefix: prefix,
        requirementPrefix: generatedTestCases.requirementPrefix || "REQ",
        cycle: document.getElementById("smartTCCycle").value,
        cycleDate: document.getElementById("smartTCCycleDate").value,
        createdBy: creatorSelect.value.split("(")[0].trim(),
        testType: document.getElementById("smartTCType").value,
      },
      usedTitles,
    );

    localStorage.setItem("qf_last_smart_tc_creator", creatorSelect.value);
    generatedCases.forEach((tc) => suite.testCases.push(tc));

    refreshUI();
    modal.style.display = "none";
    alert(`Generated ${generatedCases.length} test cases.`);
  };

  function refreshUI() {
    refreshAllUI();
  }
};

// ==========================================
// HELPER: EXPAND REQUIREMENTS (Context Aware - Matches Generator Page)
// ==========================================

function expandRequirementsForPlan(lines) {
  let expanded = [...lines];
  const combinedText = lines.join(" ").toLowerCase();
  const newItems = [];

  // Login/Authentication context
  if (
    combinedText.includes("login") ||
    combinedText.includes("auth") ||
    combinedText.includes("sign in")
  ) {
    newItems.push("Verify proper validation messages for invalid credentials");
    newItems.push('Check password masking and "forgot password" functionality');
    newItems.push("Ensure session timeout works as expected");
    newItems.push('Test "remember me" functionality if applicable');
    newItems.push("Verify account lockout after multiple failed attempts");
  }
  // Search functionality
  else if (combinedText.includes("search") || combinedText.includes("find")) {
    newItems.push("Verify search results relevance and accuracy");
    newItems.push("Check search functionality with special characters");
    newItems.push('Validate "no results found" state');
    newItems.push("Test search filters and sorting options");
    newItems.push("Verify search performance with large datasets");
  }
  // Form/Input validation
  else if (
    combinedText.includes("form") ||
    combinedText.includes("input") ||
    combinedText.includes("submit")
  ) {
    newItems.push("Validate all required field validations");
    newItems.push("Test input field boundary values and data types");
    newItems.push("Verify proper error messages for invalid inputs");
    newItems.push("Check form submission with valid and invalid data");
    newItems.push("Test form reset and cancel functionality");
  }
  // Payment/Transaction
  else if (
    combinedText.includes("payment") ||
    combinedText.includes("checkout") ||
    combinedText.includes("transaction")
  ) {
    newItems.push("Verify payment gateway integration");
    newItems.push("Test transaction success and failure scenarios");
    newItems.push("Validate payment confirmation and receipt generation");
    newItems.push("Check refund and cancellation workflows");
    newItems.push("Verify secure handling of payment information");
  }
  // Registration/Signup
  else if (
    combinedText.includes("register") ||
    combinedText.includes("signup") ||
    combinedText.includes("sign up")
  ) {
    newItems.push("Verify email/username uniqueness validation");
    newItems.push("Test password strength requirements");
    newItems.push("Check email verification workflow");
    newItems.push("Validate terms and conditions acceptance");
    newItems.push("Test duplicate registration prevention");
  }
  // Dashboard/Analytics
  else if (
    combinedText.includes("dashboard") ||
    combinedText.includes("report") ||
    combinedText.includes("analytics")
  ) {
    newItems.push("Verify data accuracy in charts and graphs");
    newItems.push("Test date range filters and data refresh");
    newItems.push("Check export functionality (PDF, Excel, CSV)");
    newItems.push("Validate real-time data updates if applicable");
    newItems.push("Test dashboard performance with large datasets");
  }
  // File Upload/Download
  else if (
    combinedText.includes("upload") ||
    combinedText.includes("download") ||
    combinedText.includes("file")
  ) {
    newItems.push("Verify supported file formats and size limits");
    newItems.push("Test upload progress indication");
    newItems.push("Check file validation and virus scanning");
    newItems.push("Validate download functionality and file integrity");
    newItems.push("Test bulk upload/download operations");
  }
  // Navigation/Menu
  else if (
    combinedText.includes("navigation") ||
    combinedText.includes("menu") ||
    combinedText.includes("nav")
  ) {
    newItems.push("Verify all menu items are accessible and functional");
    newItems.push("Test navigation breadcrumbs and back button");
    newItems.push("Check mobile menu responsiveness");
    newItems.push("Validate active menu state highlighting");
    newItems.push("Test keyboard navigation accessibility");
  }
  // API/Integration
  else if (
    combinedText.includes("api") ||
    combinedText.includes("integration") ||
    combinedText.includes("endpoint")
  ) {
    newItems.push("Verify API response codes and error handling");
    newItems.push("Test API authentication and authorization");
    newItems.push("Check API rate limiting and throttling");
    newItems.push("Validate request/response payload structure");
    newItems.push("Test API performance and timeout handling");
  }

  // Add unique new items only (deduplicate against existing)
  newItems.forEach((item) => {
    // Simple fuzzy check
    const isDuplicate = expanded.some(
      (ex) =>
        ex.toLowerCase().includes(item.toLowerCase()) ||
        item.toLowerCase().includes(ex.toLowerCase()),
    );
    if (!isDuplicate) {
      expanded.push(item);
    }
  });

  return expanded;
}

// ==========================================
// SMART ADD PLAN LOGIC
// ==========================================

window.handleAddPlan = function (stIdx) {
  // Inject Modal if not exists
  if (!document.getElementById("smartPlanModal")) {
    const isProject = ["3", "4"].includes(generatedTestCases.schemaLevel);
    const label = isProject ? "Project" : "Plan";
    const modalHtml = `
        <div id="smartPlanModal" class="modal-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); z-index:1000; justify-content:center; align-items:center;">
            <div class="modal-content" style="background:var(--bg-card); padding:2rem; border-radius:8px; width:95%; max-width:900px; color:var(--text-primary); max-height:90vh; overflow-y:auto;">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1.5rem; border-bottom:1px solid var(--border-color); padding-bottom:1rem;">
                    <h2 style="margin:0;">Add New ${label}</h2>
                    <button data-action="closeSmartPlanModal" style="background:none; border:none; color:var(--text-primary); font-size:1.5rem; cursor:pointer;">&times;</button>
                </div>
                
                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1.5rem; margin-bottom:1.5rem;">
                    <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">${label} Name *</label>
                        <input type="text" id="smartPlanName" class="form-input" style="width:100%; padding:0.75rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                    </div>
                    <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">${label} ID</label>
                        <input type="text" id="smartPlanId" class="form-input" style="width:100%; padding:0.75rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                    </div>
                     <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">Plan Date</label>
                        <div style="display:flex;align-items:center;position:relative;">
                            <input type="text" id="smartPlanDateText" class="form-input" placeholder="MM-DD-YYYY" style="width:100%;padding:0.75rem;background:var(--bg-primary);border:1px solid var(--border-color);color:var(--text-primary);border-radius:4px;cursor:pointer;">
                            <input type="hidden" id="smartPlanDate">
                            <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:0.85rem;"></i>
                        </div>
                    </div>
                     <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-weight:bold;">Created By</label>
                        <select id="smartPlanCreatedBy" class="form-input" style="width:100%; padding:0.75rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                             <!-- Populated via JS -->
                        </select>
                    </div>
                </div>
                
                <div class="form-group" style="margin-bottom:1.5rem;">
                    <div style="display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:0.5rem;">
                        <label style="font-weight:bold;">Requirements</label>
                        <div style="display:flex; gap:0.5rem;">
                            <button id="btnAiPlanReqs" class="btn btn-sm" style="background:#e8f0f5; color:#1e293b; font-size:0.8rem; padding:0.2rem 0.6rem;"><i class="fas fa-wand-magic-sparkles"></i> AI Refine</button>
                        </div>
                    </div>
                    <textarea id="smartPlanReqs" rows="6" class="form-input" style="width:100%; padding:0.75rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px; font-family:monospace;" placeholder="Paste requirements for this specific plan to auto-generate suites and test cases..."></textarea>
                </div>

                <div style="background:var(--bg-primary); padding:1rem; border-radius:4px; border:1px dashed var(--border-color); margin-bottom:1.5rem;">
                    <h3 style="margin-top:0; font-size:1rem; margin-bottom:1rem;">Suites for this Plan</h3>
                     <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1rem; margin-bottom:1rem;">
                        <div class="form-group">
                            <label style="display:block; margin-bottom:0.5rem; font-size:0.9rem;">Suite Name</label>
                            <input type="text" id="smartPlanSuiteName" value="Functional Suite" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-card); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                        </div>
                         <div class="form-group">
                            <label style="display:block; margin-bottom:0.5rem; font-size:0.9rem;">Suite ID</label>
                            <input type="text" id="smartPlanSuiteId" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-card); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                        </div>
                    </div>
                     <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1rem; margin-bottom:1rem;">
                        <div class="form-group">
                            <label style="display:block; margin-bottom:0.5rem; font-size:0.9rem;">Suite Date</label>
                            <div style="display:flex;align-items:center;position:relative;">
                                <input type="text" id="smartPlanSuiteDateText" class="form-input" placeholder="MM-DD-YYYY" style="width:100%;padding:0.5rem;background:var(--bg-card);border:1px solid var(--border-color);color:var(--text-primary);border-radius:4px;cursor:pointer;">
                                <input type="hidden" id="smartPlanSuiteDate">
                                <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:0.85rem;"></i>
                            </div>
                        </div>
                         <div class="form-group">
                            <label style="display:block; margin-bottom:0.5rem; font-size:0.9rem;">Suite Created By</label>
                            <select id="smartPlanSuiteCreatedBy" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-card); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                                <!-- Populated via JS -->
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem; font-size:0.9rem;">Test Cases</label>
                        <input type="number" id="smartPlanCount" value="5" min="1" max="50" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-card); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                    </div>
                </div>
                
                <div style="display:flex; justify-content:flex-end; gap:1rem; padding-top:1rem; border-top:1px solid var(--border-color);">
                    <button data-action="closeSmartPlanModal" class="btn btn-outline">Cancel</button>
                    <button id="btnCreatePlan" class="btn btn-primary" style="padding:0.75rem 2rem; display: flex; align-items: center; gap: 0.5rem;"><i class="fas fa-wand-magic-sparkles"></i> Generate with AI</button>
                </div>
            </div>
        </div>`;
    document.body.insertAdjacentHTML("beforeend", modalHtml);
  }

  // Element Refs
  const modal = document.getElementById("smartPlanModal");
  const nameInput = document.getElementById("smartPlanName");
  const idInput = document.getElementById("smartPlanId");
  const dateInput = document.getElementById("smartPlanDate");
  const creatorSelect = document.getElementById("smartPlanCreatedBy");
  const reqInput = document.getElementById("smartPlanReqs");

  // Suite Inputs
  const suiteNameInput = document.getElementById("smartPlanSuiteName");
  const suiteIdInput = document.getElementById("smartPlanSuiteId");
  const suiteDateInput = document.getElementById("smartPlanSuiteDate");
  const suiteCreatorSelect = document.getElementById("smartPlanSuiteCreatedBy");
  const countInput = document.getElementById("smartPlanCount");

  const createBtn = document.getElementById("btnCreatePlan");

  // Populate Creator Dropdown (mimic generator)
  let assigneeMaster = JSON.parse(localStorage.getItem("qf_assignee_master"));
  if (!Array.isArray(assigneeMaster)) {
    assigneeMaster = [
      { name: "Mahesh Prabhu", designation: "Lead QA" },
      { name: "Arun K R", designation: "Senior QA" },
      { name: "Dencymol Puthiyaparambil", designation: "QA Engineer" },
      { name: "Rahul Raj", designation: "QA Engineer" },
      { name: "User", designation: "QA" },
    ];
  }
  const creatorOptions = assigneeMaster
    .map((u) => `<option value="${u.name}">${u.name}</option>`)
    .join("");
  creatorSelect.innerHTML = creatorOptions;
  suiteCreatorSelect.innerHTML = creatorOptions;

  // Restore last selected creator
  const lastPlanCreator = localStorage.getItem("qf_last_smart_plan_creator");
  if (
    lastPlanCreator &&
    Array.from(creatorSelect.options).some(
      (opt) => opt.value === lastPlanCreator,
    )
  ) {
    creatorSelect.value = lastPlanCreator;
    suiteCreatorSelect.value = lastPlanCreator;
  }

  // Set Defaults
  const today = new Date().toISOString().split("T")[0];
  nameInput.value = "New Plan";
  idInput.value = "PLAN-" + Date.now().toString().slice(-4);
  dateInput.value = today;
  if (window.qfIsoToDisplay) {
    document.getElementById("smartPlanDateText").value =
      window.qfIsoToDisplay(today);
  }

  suiteNameInput.value = "Functional Suite";
  suiteIdInput.value = "SUITE-" + Date.now().toString().slice(-4);
  suiteDateInput.value = today;
  if (window.qfIsoToDisplay) {
    document.getElementById("smartPlanSuiteDateText").value =
      window.qfIsoToDisplay(today);
  }

  reqInput.value = "";
  countInput.value = "5";

  // AI Refine for Plan Requirements
  document.getElementById("btnAiPlanReqs").onclick = () =>
    runAiRefine(reqInput, "btnAiPlanReqs", "smartPlanCount");

  // Show Modal
  modal.style.display = "flex";

  // Attach Pikaday
  if (typeof window.qfAttachDatePicker === "function") {
    window.qfAttachDatePicker(
      document.getElementById("smartPlanDateText"),
      document.getElementById("smartPlanDate"),
      today,
    );
    window.qfAttachDatePicker(
      document.getElementById("smartPlanSuiteDateText"),
      document.getElementById("smartPlanSuiteDate"),
      today,
    );
  }

  // Handle Create
  createBtn.onclick = function () {
    const pName = nameInput.value.trim() || "New Plan";
    const pId = idInput.value.trim();
    const pDate = dateInput.value;
    const pCreator = creatorSelect.value;
    const pReqs = reqInput.value.trim();

    // Suite Data
    const sName = suiteNameInput.value.trim() || "Functional Suite";
    const sId =
      suiteIdInput.value.trim() || "SUITE-" + Date.now().toString().slice(-4);
    const sDate = suiteDateInput.value;
    const sCreator = suiteCreatorSelect.value;
    const pCount = parseInt(countInput.value) || 5;

    let newPlan = {
      planName: pName,
      planId: pId,
      planDate: pDate,
      planCreatedBy: pCreator,
      description: "",
      suites: [],
    };

    // Always use AI Generation - Fallback to Plan Name if requirements are empty
    let inputReqs = pReqs;
    if (!inputReqs) {
      inputReqs = `Verify functionality of ${pName}`;
      if (sName !== "Functional Suite") {
        inputReqs += `. Verify ${sName}.`;
      }
    }

    // Parse requirements
    let requirements = inputReqs
      .split(/[\n•\-\*]+|(?<=\.)\s+/)
      .map((l) => l.trim())
      .filter((l) => l.length > 5);
    if (requirements.length === 0) requirements = [inputReqs];

    // Auto-expand requirements if needed
    const totalTestsNeeded = pCount;
    if (requirements.length < totalTestsNeeded) {
      // console.log('Expanding requirements to meet demand...');
      requirements = expandRequirementsForPlan(requirements);

      // If still short, add generics
      if (requirements.length < totalTestsNeeded) {
        const generics = [
          "Verify UI responsiveness across different screen sizes",
          "Ensure proper error handling for network interruptions",
          "Validate input field boundary values and data types",
          "Test accessibility compliance (WCAG standards)",
          "Check browser compatibility (Chrome, Firefox, Safari, Edge)",
          "Verify proper loading states and user feedback",
          "Verify application behavior under low battery",
          "Check strict security headers and cookies",
          "Validate localization and special character support",
          "Test behavior when resuming from background",
        ];
        let gIndex = 0;
        while (requirements.length < totalTestsNeeded) {
          requirements.push(generics[gIndex % generics.length]);
          gIndex++;
        }
      }
    }

    const continuationState = { currentIndex: 0 };
    const allUsedTitles = new Set();

    // Calculate Global Max ID for sequential numbering
    const { maxId, prefix } = window.getProjectMaxId();
    const startCount = maxId + 1;

    // Create default suite with generated cases
    const generatedCases = generateSmartTestCases(
      requirements,
      pCount,
      startCount,
      {
        testCasePrefix: prefix,
        requirementPrefix: generatedTestCases.requirementPrefix || "REQ",
        cycle: "1.0",
        cycleDate: sDate || pDate,
        createdBy: sCreator || pCreator,
        testType: "Functional",
      },
      allUsedTitles,
      continuationState,
    );

    newPlan.suites.push({
      suiteName: sName,
      suiteId: sId,
      testCases: generatedCases,
      yamlMetadata: {
        createdDate: sDate,
        createdBy: sCreator,
      },
    });

    localStorage.setItem("qf_last_smart_plan_creator", pCreator);

    if (pReqs) {
      alert(
        `Plan created with ${generatedCases.length} generated test cases based on requirements.`,
      );
    } else {
      alert(
        `Plan generated with ${generatedCases.length} AI test cases (auto-generated from plan name).`,
      );
    }

    // Add to global data
    if (
      generatedTestCases.schemaLevel === "6" &&
      stIdx != null &&
      stIdx !== "null"
    ) {
      generatedTestCases.strategies[stIdx].plans.push(newPlan);
    } else {
      generatedTestCases.plans.push(newPlan);
    }

    refreshAllUI();
    modal.style.display = "none";
  };
};

// ==========================================
// SMART ADD SUITE LOGIC
// ==========================================

window.handleAddSuite = function (stIdx, pIdx) {
  // Inject Modal if not exists
  if (!document.getElementById("smartSuiteModal")) {
    const modalHtml = `
        <div id="smartSuiteModal" class="modal-overlay" style="display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.7); z-index:1000; justify-content:center; align-items:center;">
            <div class="modal-content" style="background:var(--bg-card); padding:2rem; border-radius:8px; width:90%; max-width:600px; color:var(--text-primary); max-height: 90vh; overflow-y: auto;">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1.5rem;">
                    <h2 style="margin:0;">Add New Suite</h2>
                    <button data-action="closeSmartSuiteModal" style="background:none; border:none; color:var(--text-primary); font-size:1.5rem; cursor:pointer;">&times;</button>
                </div>
                
                <div class="form-group" style="margin-bottom:1rem;">
                    <label style="display:block; margin-bottom:0.5rem;">Suite Name</label>
                    <input type="text" id="smartSuiteName" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                </div>
                
                <div class="form-group" style="margin-bottom:1rem;">
                    <label style="display:block; margin-bottom:0.5rem;">Suite ID</label>
                    <input type="text" id="smartSuiteId" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1rem; margin-bottom:1rem;">
                    <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem;">Suite Date</label>
                        <div style="display:flex;align-items:center;position:relative;">
                            <input type="text" id="smartSuiteDateText" class="form-input" placeholder="MM-DD-YYYY" style="width:100%;padding:0.5rem;background:var(--bg-primary);border:1px solid var(--border-color);color:var(--text-primary);border-radius:4px;cursor:pointer;">
                            <input type="hidden" id="smartSuiteDate">
                            <i class="fas fa-calendar-alt" style="position:absolute;right:8px;pointer-events:none;color:#94a3b8;font-size:0.85rem;"></i>
                        </div>
                    </div>
                     <div class="form-group">
                        <label style="display:block; margin-bottom:0.5rem;">Suite Created By</label>
                        <select id="smartSuiteCreatedBy" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                             <!-- Populated via JS -->
                        </select>
                    </div>
                </div>

                <div class="form-group" style="margin-bottom:1rem;">
                    <label style="display:block; margin-bottom:0.5rem;">Test Cases</label>
                    <input type="number" id="smartSuiteCount" value="5" min="1" max="50" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px;">
                </div>
                
                <div class="form-group" style="margin-bottom:1rem;">
                    <div style="display:flex; justify-content:space-between; align-items:flex-end; margin-bottom:0.5rem;">
                        <label style="font-weight:bold; color:var(--text-danger);">Requirement Details *</label>
                        <button id="btnAiSuiteReqs" class="btn btn-sm" style="background:#e8f0f5; color:#1e293b; font-size:0.8rem; padding:0.2rem 0.6rem;"><i class="fas fa-wand-magic-sparkles"></i> AI Refine</button>
                    </div>
                    <textarea id="smartSuiteReqs" rows="4" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px; font-family: inherit;" placeholder="Enter your requirements here (one per line or separated by bullets)..."></textarea>
                    <small style="display:block; margin-top:0.25rem; color:var(--text-secondary);"><i class="fas fa-lightbulb"></i> Enter requirements that will be used to generate test cases</small>
                </div>

                <div class="form-group" style="margin-bottom:1rem;">
                    <label style="display:block; margin-bottom:0.5rem;">Description</label>
                    <textarea id="smartSuiteDesc" rows="3" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px; font-family: inherit;"></textarea>
                </div>

                <div class="form-group" style="margin-bottom:1rem;">
                    <label style="display:block; margin-bottom:0.5rem;">Metadata (YAML)</label>
                    <textarea id="smartSuiteYaml" rows="3" class="form-input" style="width:100%; padding:0.5rem; background:var(--bg-primary); border:1px solid var(--border-color); color:var(--text-primary); border-radius:4px; font-family: monospace;"></textarea>
                </div>
                
                <div style="display:flex; justify-content:flex-end; gap:1rem; margin-top:2rem;">
                    <button data-action="closeSmartSuiteModal" class="btn btn-outline">Cancel</button>
                    <button id="btnCreateSuite" class="btn btn-primary">Create & Generate</button>
                </div>
            </div>
        </div>`;
    document.body.insertAdjacentHTML("beforeend", modalHtml);
  }

  // Set State
  const modal = document.getElementById("smartSuiteModal");
  const nameInput = document.getElementById("smartSuiteName");
  const idInput = document.getElementById("smartSuiteId");
  const dateInput = document.getElementById("smartSuiteDate");
  const creatorSelect = document.getElementById("smartSuiteCreatedBy");
  const countInput = document.getElementById("smartSuiteCount");
  const reqInput = document.getElementById("smartSuiteReqs");
  const descInput = document.getElementById("smartSuiteDesc");
  const yamlInput = document.getElementById("smartSuiteYaml");
  const btnCreate = document.getElementById("btnCreateSuite");

  // Populate Creator Dropdown
  let assigneeMaster = JSON.parse(localStorage.getItem("qf_assignee_master"));
  if (!Array.isArray(assigneeMaster)) {
    assigneeMaster = [
      { name: "Mahesh Prabhu", designation: "Lead QA" },
      { name: "Arun K R", designation: "Senior QA" },
      { name: "Dencymol Puthiyaparambil", designation: "QA Engineer" },
      { name: "Rahul Raj", designation: "QA Engineer" },
      { name: "User", designation: "QA" },
    ];
  }
  const creatorOptions = assigneeMaster
    .map((u) => `<option value="${u.name}">${u.name}</option>`)
    .join("");
  creatorSelect.innerHTML = creatorOptions;

  // Restore last selected creator
  const lastPlanCreator = localStorage.getItem("qf_last_smart_plan_creator");
  if (
    lastPlanCreator &&
    Array.from(creatorSelect.options).some(
      (opt) => opt.value === lastPlanCreator,
    )
  ) {
    creatorSelect.value = lastPlanCreator;
  }

  // Default Values
  const today = new Date().toISOString().split("T")[0];
  nameInput.value = "New Functional Suite";
  idInput.value =
    (generatedTestCases.testCasePrefix || "SUITE") +
    "-" +
    Date.now().toString().slice(-4);
  dateInput.value = today;
  if (window.qfIsoToDisplay) {
    document.getElementById("smartSuiteDateText").value =
      window.qfIsoToDisplay(today);
  }
  countInput.value = "5";
  reqInput.value = "";
  descInput.value = "Functional verification suite";
  yamlInput.value = "";

  // AI Refine Hook
  document.getElementById("btnAiSuiteReqs").onclick = () =>
    runAiRefine(reqInput, "btnAiSuiteReqs", "smartSuiteCount");

  // Show Modal
  modal.style.display = "flex";

  // Attach Pikaday
  if (typeof window.qfAttachDatePicker === "function") {
    window.qfAttachDatePicker(
      document.getElementById("smartSuiteDateText"),
      document.getElementById("smartSuiteDate"),
      today,
    );
  }

  // Logic to pre-fill from previous (Clone logic)
  let plan;
  if (
    generatedTestCases.schemaLevel === "6" &&
    stIdx != null &&
    stIdx !== "null" &&
    stIdx !== null
  ) {
    plan = generatedTestCases.strategies[stIdx].plans[pIdx];
  } else {
    plan = generatedTestCases.plans[pIdx];
  }

  let clonedMetadata = {};

  if (plan && plan.suites.length > 0) {
    const prev = plan.suites[plan.suites.length - 1];
    nameInput.value = prev.suiteName + " (Copy)";
    idInput.value = prev.suiteId ? prev.suiteId + "-COPY" : "";
    descInput.value = prev.description || "";
    clonedMetadata = prev.yamlMetadata || {};
  }

  // Convert Metadata to YAML string for display
  let yamlStr = "";
  if (typeof clonedMetadata === "string") {
    yamlStr = clonedMetadata;
  } else if (typeof clonedMetadata === "object" && clonedMetadata !== null) {
    for (const [key, val] of Object.entries(clonedMetadata)) {
      yamlStr += `${key}: ${val}\n`;
    }
  }
  yamlInput.value = yamlStr;

  modal.style.display = "flex";

  btnCreate.onclick = function () {
    if (!plan) return;

    const sName = nameInput.value.trim();
    const sId = idInput.value.trim();
    const sDate = dateInput.value;
    const sCreator = creatorSelect.value;
    const sCount = parseInt(countInput.value) || 5;
    const sReqs = reqInput.value.trim();
    const sDesc = descInput.value.trim();
    const sYaml = yamlInput.value.trim();

    if (!sName) {
      alert("Suite Name is required.");
      return;
    }

    // Parse Metadata
    let metadataObj = {};
    if (sYaml) {
      sYaml.split("\n").forEach((line) => {
        const [k, v] = line.split(":");
        if (k && v) metadataObj[k.trim()] = v.trim();
      });
    }

    let newSuite = {
      suiteName: sName,
      suiteId: sId,
      description: sDesc,
      yamlMetadata: metadataObj,
      testCases: [],
    };

    // Add specific metadata for tracking
    if (!newSuite.yamlMetadata.createdDate)
      newSuite.yamlMetadata.createdDate = sDate;
    if (!newSuite.yamlMetadata.createdBy)
      newSuite.yamlMetadata.createdBy = sCreator;

    // Generate Test Cases if Requirements Present
    if (sReqs) {
      // Parse requirements
      let requirements = sReqs
        .split(/[\n•\-\*]+|(?<=\.)\s+/)
        .map((l) => l.trim())
        .filter((l) => l.length > 5);
      if (requirements.length === 0) requirements = [sReqs];

      const { maxId, prefix } = window.getProjectMaxId();
      const startCount = maxId + 1;
      const count = sCount;

      // Expand if needed
      if (requirements.length < count) {
        requirements = expandRequirementsForPlan(requirements);

        // If still short, add default generics to meet count
        if (requirements.length < count) {
          const generics = [
            "Verify happy path flow",
            "Verify error handling logic",
            "Validate input constraints",
            "Check UI responsiveness",
            "Verify data persistence",
          ];
          let gInd = 0;
          while (requirements.length < count) {
            requirements.push(generics[gInd % generics.length]);
            gInd++;
          }
        }
      }

      const generatedCases = generateSmartTestCases(
        requirements,
        count,
        startCount,
        {
          testCasePrefix: prefix,
          requirementPrefix: generatedTestCases.requirementPrefix || "REQ",
          cycle: "1.0",
          cycleDate: sDate,
          createdBy: sCreator,
          testType: "Functional",
        },
        new Set(),
      );

      newSuite.testCases = generatedCases;
    }

    plan.suites.push(newSuite);

    // Save creator for next time
    localStorage.setItem("qf_last_smart_plan_creator", sCreator);

    refreshAllUI();
    modal.style.display = "none";

    if (newSuite.testCases.length > 0) {
      alert(
        `Suite created with ${newSuite.testCases.length} AI-generated test cases.`,
      );
    } else {
      alert("Empty Suite created successfully.");
    }
  };
};

// ... existing code ...

// ==========================================
// DELETE HANDLERS
// ==========================================

window.handleDeletePlan = function (stIdx, pIdx) {
  if (
    !confirm(
      "WARNING: Deleting this PLAN will permanently remove ALL its Suites and Test Cases!\n\nAre you sure you want to proceed?",
    )
  ) {
    return;
  }

  if (generatedTestCases.schemaLevel === "6" && stIdx != null) {
    generatedTestCases.strategies[stIdx].plans.splice(pIdx, 1);
  } else {
    generatedTestCases.plans.splice(pIdx, 1);
  }

  refreshAllUI();
  alert("Plan deleted successfully.");
  location.reload();
};

window.handleDeleteSuite = function (stIdx, pIdx, sIdx) {
  if (
    !confirm(
      "WARNING: Deleting this SUITE will permanently remove ALL its Test Cases!\n\nAre you sure you want to proceed?",
    )
  ) {
    return;
  }

  let plan;
  if (generatedTestCases.schemaLevel === "6" && stIdx != null) {
    plan = generatedTestCases.strategies[stIdx].plans[pIdx];
  } else {
    plan = generatedTestCases.plans[pIdx];
  }

  if (plan) {
    plan.suites.splice(sIdx, 1);
    refreshAllUI();
    alert("Suite deleted successfully.");
    location.reload();
  }
};

window.handleDeleteTestCase = function (stIdx, pIdx, sIdx, tIdx) {
  if (
    !confirm(
      "Are you sure you want to delete this Test Case?\n\nThis will also remove its entire evidence history.",
    )
  ) {
    return;
  }

  let suite;
  if (generatedTestCases.schemaLevel === "6" && stIdx != null) {
    suite = generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx];
  } else {
    suite = generatedTestCases.plans[pIdx].suites[sIdx];
  }

  if (suite) {
    suite.testCases.splice(tIdx, 1);
    refreshAllUI();
    alert("Test Case deleted successfully.");
    location.reload();
  }
};

function refreshAllUI() {
  updateStats(); // ← always update "Total Test Cases" badge
  renderTestCasesList();
  renderTreeView();
  updateExports();
  saveResults();
}

function saveResults() {
  if (generatedTestCases) {
    localStorage.setItem(
      "qf_generated_test_cases",
      JSON.stringify(generatedTestCases),
    );
  }
}

window.handleBulkDelete = function () {
  const selected = document.querySelectorAll(".tc-checkbox:checked");
  if (selected.length === 0) {
    alert("Please select at least one test case to delete.");
    return;
  }

  if (
    !confirm(
      `Are you sure you want to delete ${selected.length} selected test cases?`,
    )
  ) {
    return;
  }

  // Sort selected in reverse order to avoid index shifting problems
  const itemsToDelete = Array.from(selected)
    .map((cb) => ({
      st: cb.dataset.stid === "null" ? null : parseInt(cb.dataset.stid),
      p: parseInt(cb.dataset.pid),
      s: parseInt(cb.dataset.sid),
      t: parseInt(cb.dataset.tid),
    }))
    .sort((a, b) => b.t - a.t);

  itemsToDelete.forEach((item) => {
    let suite;
    if (generatedTestCases.schemaLevel === "6" && item.st !== null) {
      suite =
        generatedTestCases.strategies[item.st].plans[item.p].suites[item.s];
    } else {
      suite = generatedTestCases.plans[item.p].suites[item.s];
    }

    if (suite) {
      suite.testCases.splice(item.t, 1);
    }
  });

  refreshAllUI();
  elements.selectAllTcs.checked = false;
  updateSelectedCount();
  alert(`${selected.length} test cases deleted successfully.`);
  location.reload();
};

// ==========================================
// AI GENERATION LOGIC
// ==========================================

const actionMap = {
  login: {
    context: "Authentication",
    steps: [
      "Navigate to the application login page.",
      "Enter valid user credentials.",
      "Click the Login button.",
    ],
    expected: [
      "The user is successfully authenticated.",
      "The Dashboard page is loaded.",
    ],
  },
  logout: {
    context: "Authentication",
    steps: [
      "Ensure the user is currently logged in.",
      "Click on Profile and select Logout.",
    ],
    expected: [
      "The user is redirected to the login page.",
      "The session is successfully terminated.",
    ],
  },
  search: {
    context: "Search Utility",
    steps: [
      "Navigate to the search section.",
      "Enter the search keyword in the input field.",
      "Press the Enter key or click the search icon.",
    ],
    expected: [
      "Relevant results are displayed to the user.",
      "The search query is retained in the input field.",
    ],
  },
  upload: {
    context: "File Management",
    steps: [
      "Click the Upload button.",
      "Select a valid file from the local system.",
      "Confirm and start the upload process.",
    ],
    expected: [
      "The file is uploaded successfully.",
      "A success message is displayed to the user.",
    ],
  },
  payment: {
    context: "Transactions",
    steps: [
      "Select the desired item for purchase.",
      "Proceed to the checkout page.",
      "Enter the payment details correctly.",
      "Click the Pay button to complete the transaction.",
    ],
    expected: [
      "The payment is processed successfully.",
      "The order confirmation is displayed.",
    ],
  },
  dashboard: {
    context: "UI Validation",
    steps: [
      "Log in to the system with valid credentials.",
      "Access the Dashboard section from the navigation.",
    ],
    expected: [
      "All dashboard widgets are loaded correctly.",
      "The displayed data matches the database records.",
    ],
  },
};

const scenarioTypes = [
  {
    type: "Happy Path",
    prefix: "Verify successful operation for",
    intent: "successful operation",
  },
  {
    type: "Negative",
    prefix: "Verify error handling for",
    intent: "invalid input",
  },
  {
    type: "Boundary",
    prefix: "Check boundary limits for",
    intent: "edge cases",
  },
  {
    type: "Security",
    prefix: "Ensure security for",
    intent: "unauthorized access",
  },
  {
    type: "Performance",
    prefix: "Measure load time for",
    intent: "performance benchmarks",
  },
];

window.generateSmartTestCases = function (
  requirements,
  maxTests,
  startCount,
  globalData,
  usedTitles = new Set(),
  continuationState = { currentIndex: 0 },
) {
  const testCases = [];

  // Attempt to extract a target URL (from first req usually, or general text)
  // Since we only have array here, we check the first string if it looks like URL
  const combinedText = requirements.join(" ");
  const urlMatch = combinedText.match(/https?:\/\/[^\s'"\(\)]+/);
  const targetUrl = urlMatch ? urlMatch[0] : "the application";

  let count = startCount;

  for (let i = 0; i < maxTests; i++) {
    // Use Global Continuous Index
    const absIndex = continuationState.currentIndex;

    // Cycle through requirements and scenario types
    const reqRaw = requirements[absIndex % requirements.length];

    // Cycle scenarios:
    // To distribute properly, we might want scenarios to rotate faster or slower.
    // Let's pair them 1-to-1 for now, but if Req count > Scenario count, it wraps.
    const scenario = scenarioTypes[absIndex % scenarioTypes.length];

    // Advance state
    continuationState.currentIndex++;

    // Clean subject but KEEP FULL LENGTH
    let coreSubject = reqRaw
      .replace(/^[:\-\*•]+/, "")
      .trim()
      .replace(/[.,;]+$/, "");

    // Generate Title
    let title = `${scenario.prefix} ${coreSubject}`;

    // Ensure uniqueness
    let finalTitle = title;
    let suffix = 2;
    while (usedTitles.has(finalTitle)) {
      finalTitle = `${title} (${suffix++})`;
    }
    usedTitles.add(finalTitle);

    // Determine steps based on keywords
    let steps = [];
    let expected = [];
    let tags = [globalData.testType || "Functional", scenario.type];

    const lowerReq = coreSubject.toLowerCase();
    let match = false;

    for (const [key, val] of Object.entries(actionMap)) {
      if (lowerReq.includes(key)) {
        steps = [...val.steps];
        expected = [...val.expected];
        if (val.context) tags.push(val.context);
        match = true;
        break;
      }
    }

    if (!match) {
      steps = [
        `Navigate to the relevant section to validate "${coreSubject}".`,
        `Perform the necessary actions to verify the ${scenario.intent}.`,
        `Validate that the system response matches the expected behavior.`,
      ];
      expected = [
        `The system handles the ${scenario.intent} correctly.`,
        `The outcome matches the ${scenario.type} requirements.`,
      ];
    }

    // Adjust for scenario type
    if (scenario.type === "Negative") {
      steps.push("Enter invalid data/simulated failure");
      expected = [
        "System shows appropriate error message",
        "No crash or data corruption",
      ];
    }

    // Create Test Case Object
    const prefix = globalData.testCasePrefix || "TC";
    const paddedNum = count.toString().padStart(4, "0");
    const reqId = globalData.requirementPrefix
      ? `${globalData.requirementPrefix}-${paddedNum}`
      : `REQ-${paddedNum}`;

    testCases.push({
      testCaseId: `${prefix}-${paddedNum}`,
      title: finalTitle,
      description: `Verify ${scenario.intent} for: ${coreSubject}`,
      requirementId: reqId,
      priority: i % 3 === 0 ? "High" : "Medium",
      status: "To-do",
      preconditions: ["System is initialized", "User logged in"],
      steps: steps.map((s, idx) => ({
        step: idx + 1,
        action: s,
        expected: expected[0] || "Success",
      })),
      expectedResult: expected.join(". "),
      tags: tags,
      cycle: globalData.cycle || "1.0",
      cycleDate: globalData.cycleDate || new Date().toISOString().split("T")[0],
      createdBy: globalData.createdBy || "User",
      assignee: globalData.createdBy || "User",
      evidenceHistory: [
        {
          cycle: globalData.cycle || "1.0",
          status: "Unexecuted",
          cycleDate:
            globalData.cycleDate || new Date().toISOString().split("T")[0],
          assignee: globalData.createdBy || "User",
        },
      ],
    });
    count++;
  }

  return testCases;
};

// Helper for syncing Select -> Input
function setupInputSync() {
  const pairs = [
    { sel: "bulkScenarioTypeSelect", inp: "bulkScenarioType" },
    { sel: "bulkExecutionTypeSelect", inp: "bulkExecutionType" },
    { sel: "editTcScenarioTypeSelect", inp: "editTcScenarioType" },
    { sel: "editTcExecutionTypeSelect", inp: "editTcExecutionType" },
    { sel: "bulkEditScenarioTypeSelect", inp: "bulkEditScenarioType" },
    { sel: "bulkEditExecutionTypeSelect", inp: "bulkEditExecutionType" },
  ];

  pairs.forEach((pair) => {
    const select = document.getElementById(pair.sel);
    const input = document.getElementById(pair.inp);
    if (select && input) {
      select.addEventListener("change", (e) => {
        const val = e.target.value;
        if (val) {
          input.value = val;
          input.dispatchEvent(new Event("input", { bubbles: true }));
          input.dispatchEvent(new Event("change", { bubbles: true }));
          e.target.value = ""; // Reset to default "Select" state
        }
      });
    }
  });
}

// Helper to set both Text Display and Hidden Date Picker
function setDualDateInput(textInput, isoDate) {
  if (!textInput || !isoDate) return;

  // 1. Set Hidden Picker Value (Sibling)
  const picker = textInput.nextElementSibling;
  if (picker && (picker.type === "date" || picker.type === "hidden")) {
    picker.value = isoDate;
  }

  // 2. Set Display Text Value (MM-DD-YYYY)
  if (isoDate.match(/^\d{4}-\d{2}-\d{2}$/)) {
    const [y, m, d] = isoDate.split("-");
    textInput.value = `${m}-${d}-${y}`;
  } else {
    textInput.value = isoDate; // Fallback
  }

  // 3. Update Pikaday if attached
  if (textInput._pk && isoDate) {
    const p = isoDate.split("-");
    if (p.length === 3) {
      textInput._pk.setDate(new Date(p[0], p[1] - 1, p[2]), true);
    }
  }
}

// Helper for syncing Text Input <-> Date Picker
function setupDateInputSync(container = document) {
  // Find all date pickers that are next to text inputs
  const datePickers = container.querySelectorAll('input[type="date"]');

  datePickers.forEach((picker) => {
    const textInput = picker.previousElementSibling;
    // Check if previous sibling is a valid text input target
    if (
      textInput &&
      textInput.tagName === "INPUT" &&
      (textInput.type === "text" || textInput.className.includes("ev-date"))
    ) {
      // 1. Sync Picker -> Text (when user picks from calendar)
      const syncPickerToText = () => {
        if (picker.value) {
          const [y, m, d] = picker.value.split("-");
          if (y && m && d) {
            textInput.value = `${m}-${d}-${y}`; // Format as MM-DD-YYYY
            // Trigger change on text input
            textInput.dispatchEvent(new Event("change", { bubbles: true }));
          }
        }
      };

      // 2. Sync Text -> Picker (when user types) - NOTE: Text is Readonly usually, but good to have
      const syncTextToPicker = () => {
        let val = textInput.value.trim();
        if (!val) {
          picker.value = "";
          return;
        }

        // Expected format MM-DD-YYYY or MM/DD/YYYY
        if (/^\d{2}[-/]\d{2}[-/]\d{4}$/.test(val)) {
          const parts = val.split(/[-/]/);
          const m = parts[0];
          const d = parts[1];
          const y = parts[2];
          const iso = `${y}-${m}-${d}`;
          picker.value = iso;
        }
      };

      // Attach listeners
      picker.removeEventListener("change", syncPickerToText);
      picker.addEventListener("change", syncPickerToText);
      picker.addEventListener("input", syncPickerToText);

      textInput.removeEventListener("change", syncTextToPicker);
      textInput.addEventListener("change", syncTextToPicker);

      // Initialize if empty
      if (!textInput.value && picker.value) {
        syncPickerToText();
      } else if (textInput.value && !picker.value) {
        syncTextToPicker();
      }
    }
  });
}

// Initialize Default Dates if present
document.addEventListener("DOMContentLoaded", () => {
  // Initializer for Results/Editor pages using results.js
  const dateInputs = document.querySelectorAll(
    "#bulkCycleDate, #editPlanDate, #editSuiteDate",
  );
  if (dateInputs.length > 0) {
    const d = new Date();
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const day = String(d.getDate()).padStart(2, "0");
    const todayFormatted = `${month}/${day}/${year}`;

    dateInputs.forEach((input) => {
      if (input.type === "text" && !input.value) {
        input.value = todayFormatted;
      }
    });
  }

  if (typeof setupDateInputSync === "function") {
    setupDateInputSync();
  }
});
// End of results.js
