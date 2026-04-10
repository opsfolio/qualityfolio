/**
 * md-editor-init.js
 * -----------------------------------------------------------------
 * CSP-safe initialization for the MD Editor page.
 * Reads master data from the hidden #qfme-config element (data-*)
 * instead of inline <script> tags (matches the entries.sql pattern).
 *
 * Also handles action-dock visibility sync.
 * Must be loaded LAST — after results.js and md-editor-bridge.js.
 */

(function () {
  "use strict";

  // ── Read master data from hidden config element and set window globals ──
  function readConfig() {
    const cfg = document.getElementById("qfme-config");
    if (!cfg) return;
    try {
      window.assigneeMaster = JSON.parse(cfg.dataset.members || "[]");
      window.scenarioMaster = JSON.parse(cfg.dataset.scenarios || "[]");
      window.executionMaster = JSON.parse(cfg.dataset.execs || "[]");
      window.statusMaster = JSON.parse(cfg.dataset.statuses || "[]");
      console.log(
        "[Init] Loaded", window.assigneeMaster.length, "assignees,",
        window.scenarioMaster.length, "scenarios,",
        window.executionMaster.length, "exec types,",
        window.statusMaster.length, "statuses"
      );
    } catch (e) {
      console.warn("[Init] Failed to parse config data:", e);
    }
  }

  // ── Sync locals to localStorage so results.js loadSettings() picks them up ──
  function syncMastersToStorage() {
    const sync = (key, arr) => {
      if (Array.isArray(arr) && arr.length > 0)
        localStorage.setItem(key, JSON.stringify(arr));
    };
    sync("qf_assignee_master", window.assigneeMaster);
    sync("qf_scenario_types_master", window.scenarioMaster);
    sync("qf_execution_types_master", window.executionMaster);
    sync("qf_status_master", window.statusMaster);
  }

  // ── Re-populate dropdowns (called once after bridge's 500ms patch runs) ──
  function repopulateDropdowns() {
    // loadSettings() reads window.assigneeMaster/scenarioMaster etc. and
    // populates all select elements. Call it once — it chains to populate fns.
    if (typeof window.loadSettings === "function") {
      window.loadSettings();
    } else {
      // Fallback: call individual populate functions directly
      if (typeof window.populateAssigneeDropdowns === "function")
        window.populateAssigneeDropdowns();
      if (typeof window.populateMasterDropdowns === "function")
        window.populateMasterDropdowns();
      if (typeof window.populateStatusDropdowns === "function")
        window.populateStatusDropdowns();
    }
  }

  // ── Action dock: show only on Preview tab ─────────────────────────────────
  function initActionDock() {
    const dock = document.querySelector(".action-dock-container");
    if (!dock) return;

    const syncDock = () => {
      const active = document.querySelector(".tab-btn.active");
      const isPreview = active && active.dataset.tab === "preview";
      dock.style.display = isPreview ? "flex" : "none";
      dock.classList.toggle("visible", isPreview);
    };

    document.querySelectorAll(".tab-btn").forEach((btn) =>
      btn.addEventListener("click", () => setTimeout(syncDock, 30))
    );

    // Initial sync — wait for results.js render to complete
    setTimeout(syncDock, 700);
  }

  // ── Auto-fill today's date ─────────────────────────────────────────────────
  function initDateDefaults() {
    const today = new Date().toISOString().split("T")[0];
    const [y, m, d] = today.split("-");
    const fmtToday = `${m}-${d}-${y}`;

    const fields = [
      { hidden: "bulkCycleDate", display: "bulkCycleDateText" },
      { hidden: "editPlanDateIso", display: "editPlanDate" },
      { hidden: "editSuiteDateIso", display: "editSuiteDate" }
    ];

    fields.forEach(f => {
      const h = document.getElementById(f.hidden);
      const d = document.getElementById(f.display);
      if (h && !h.value) h.value = today;
      if (d && !d.value) d.value = fmtToday;

      // Manually trigger Pikaday attachment if md-date-picker is loaded
      if (d && typeof window.qfAttachDatePicker === "function" && !d._pk) {
        window.qfAttachDatePicker(d, h, h ? h.value : today);
      }
    });
  }

  // ── Main init ──────────────────────────────────────────────────────────────
  function init() {
    readConfig();           // 1. Read from #qfme-config data-* attributes
    syncMastersToStorage(); // 2. Persist to localStorage

    // 3. Re-populate dropdowns AFTER bridge's 500ms patch timeout has fired
    //    Bridge patches window.openEditModal etc. at ~500ms after DOMContentLoaded
    setTimeout(repopulateDropdowns, 550);

    initActionDock();       // 4. Dock tab visibility
    initDateDefaults();     // 5. Default date field

    console.log("[Init] md-editor-init.js done.");
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
// Handles Folder Tree, Editor Interaction, and Zipping

// Persistence Keys
const STORAGE_KEY = "md_editor_session";

let fileTree = {};
let fileMap = new Map(); // path -> File object
let virtualFileMap = new Map(); // path -> content string (Persisted)
let modifiedFiles = new Map(); // path -> string content (Unsaved changes)
let fileHandleMap = new Map(); // path -> FileSystemFileHandle (For writing)
let currentFilePath = null;
let currentDirHandle = null; // The root directory handle for write access

// ── IndexedDB helpers to persist the directory handle across reloads ──────────
const IDB_NAME = "md_editor_fs";
const IDB_STORE = "handles";
const IDB_DIR_KEY = "lastDirHandle";

function openHandleDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(IDB_NAME, 1);
    req.onupgradeneeded = () => req.result.createObjectStore(IDB_STORE);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

async function storeDirHandleIDB(handle) {
  try {
    const db = await openHandleDB();
    const tx = db.transaction(IDB_STORE, "readwrite");
    tx.objectStore(IDB_STORE).put(handle, IDB_DIR_KEY);
    await new Promise((res, rej) => {
      tx.oncomplete = res;
      tx.onerror = rej;
    });
  } catch (e) {
    console.warn("IDB store failed:", e);
  }
}

async function loadDirHandleIDB() {
  try {
    const db = await openHandleDB();
    const tx = db.transaction(IDB_STORE, "readonly");
    const req = tx.objectStore(IDB_STORE).get(IDB_DIR_KEY);
    return await new Promise((res, rej) => {
      req.onsuccess = () => res(req.result);
      req.onerror = rej;
    });
  } catch (e) {
    return null;
  }
}

// Re-acquire write permission on a stored dir handle (shows browser permission bar once)
async function requestDirWritePermission(dirHandle) {
  if (!dirHandle) return false;
  try {
    const perm = await dirHandle.requestPermission({ mode: "readwrite" });
    return perm === "granted";
  } catch (e) {
    return false;
  }
}

// Get a writable FileSystemFileHandle from currentDirHandle by path
async function getHandleFromDir(filePath) {
  if (!currentDirHandle) return null;
  try {
    const parts = filePath.split("/");
    let dir = currentDirHandle;
    for (let i = 0; i < parts.length - 1; i++) {
      dir = await dir.getDirectoryHandle(parts[i]);
    }
    return await dir.getFileHandle(parts[parts.length - 1]);
  } catch (e) {
    console.warn("Could not get file handle from dir:", filePath, e);
    return null;
  }
}
// ─────────────────────────────────────────────────────────────────────────────

// Import JSZip (assuming it's available via module or global if installed)
// Since we are adding it to package.json, we might need a bundler or import map.
// For simplicity in this vanilla/Astro setup, we can dynamic import or assume global if script loaded.
// Actually, let's dynamic import it or use a CDN fallback if not bundled.
// Ideally Astro handles 'import' if this file is treated as a module.
// But this is in public/scripts, so it's not processed by Vite.
// We will look for window.JSZip or load it.

document.addEventListener("DOMContentLoaded", () => {
  // folderInput stays as the fallback for browsers that don't support showDirectoryPicker
  const folderInput = document.getElementById("folderInput");
  if (folderInput) {
    folderInput.addEventListener("change", handleFolderSelection);
  }

  const fileInput = document.getElementById("fileInput");
  if (fileInput) {
    fileInput.addEventListener("change", handleFolderSelection);
  }

  // 'Open Folder' card → use modern API so file handles are writable
  const openFolderCard = document.getElementById("openFolderCard");
  if (openFolderCard) {
    openFolderCard.addEventListener("click", () => window.selectFolder());
  }

  // Save Button Listener - Attach securely
  const saveBtn = document.getElementById("btnSaveFileAction");
  if (saveBtn && !saveBtn.dataset.listenerAttached) {
    saveBtn.addEventListener("click", saveCurrentFile);
    saveBtn.dataset.listenerAttached = "true";
  }

  // Ensure results.js doesn't try to redirect
  window.isMdEditorMode = true;

  // Tab Logic
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

  // Try restore
  restoreSession();
});

async function handleFolderSelection(event) {
  const files = Array.from(event.target.files);
  fileTree = {};
  fileMap.clear();
  virtualFileMap.clear();
  modifiedFiles.clear();
  currentFilePath = null;

  const treeRoot = document.getElementById("folderTree");
  treeRoot.innerHTML =
    '<div style="padding:1rem; color:var(--text-muted);"><i class="fas fa-spinner fa-spin"></i> Loading...</div>';

  if (files.length === 0) return;

  // Show tree section, hide upload prompt
  document.getElementById("uploadPrompt").style.display = "none";
  document.getElementById("mainEditorArea").style.display = "flex";

  const textEnc = new TextDecoder("utf-8");

  // Process files
  const promises = files.map((file) => {
    const name = file.name;
    // Only process text files we care about for persistence
    if (name.endsWith(".md") || name.endsWith(".markdown")) {
      const path = file.webkitRelativePath || file.name;
      fileMap.set(path, file); // Keep physical ref for duration of session

      return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = (e) => {
          virtualFileMap.set(path, e.target.result);
          resolve({ path, file });
        };
        reader.onerror = () => resolve({ path, file }); // Skip on error
        reader.readAsText(file);
      });
    }
    return Promise.resolve(null);
  });

  const results = await Promise.all(promises);

  // Build Tree
  treeRoot.innerHTML = "";

  // We iterate over the fileMap (or results) to build tree
  results.forEach((res) => {
    if (!res) return;
    const { path, file } = res;

    const parts = path ? path.split("/") : [file.name];
    let currentLevel = fileTree;

    parts.forEach((part, index) => {
      if (index === parts.length - 1) {
        currentLevel[part] = {
          type: "file",
          name: part,
          path: path,
        };
      } else {
        if (!currentLevel[part]) {
          currentLevel[part] = {
            type: "dir",
            name: part,
            children: {},
          };
        }
        if (currentLevel[part].type === "dir") {
          currentLevel = currentLevel[part].children;
        }
      }
    });
  });

  renderTree(fileTree, treeRoot);
  ensureDownloadButton();
  saveSession();
  saveSession();
}

// File System Access API Support
window.selectFolder = async function () {
  if (window.showDirectoryPicker) {
    try {
      const options = { mode: "readwrite" };

      const dirHandle = await window.showDirectoryPicker(options);
      currentDirHandle = dirHandle;
      await storeDirHandleIDB(dirHandle); // persist across reloads

      // Reset state
      fileTree = {};
      fileMap.clear();
      virtualFileMap.clear();
      modifiedFiles.clear();
      fileHandleMap.clear();
      currentFilePath = null;

      const treeRoot = document.getElementById("folderTree");
      treeRoot.innerHTML =
        '<div style="padding:1rem; color:var(--text-muted);"><i class="fas fa-spinner fa-spin"></i> Loading...</div>';

      document.getElementById("uploadPrompt").style.display = "none";
      document.getElementById("mainEditorArea").style.display = "flex";

      await processDirectoryHandle(dirHandle, fileTree);

      renderTree(fileTree, treeRoot);
      ensureDownloadButton();
      saveSession();
    } catch (err) {
      if (err.name !== "AbortError") {
        console.error("Error selecting folder:", err);
        alert("Error accessing folder. Using fallback input.");
        document.getElementById("folderInput").click();
      }
    }
  } else {
    // Fallback for browsers without support
    document.getElementById("folderInput").click();
  }
};

async function processDirectoryHandle(dirHandle, parentNode, pathPrefix = "") {
  for await (const entry of dirHandle.values()) {
    const relativePath = pathPrefix
      ? `${pathPrefix}/${entry.name}`
      : entry.name;

    if (entry.kind === "file") {
      if (entry.name.endsWith(".md") || entry.name.endsWith(".markdown")) {
        const file = await entry.getFile();
        const text = await file.text();

        virtualFileMap.set(relativePath, text);
        fileHandleMap.set(relativePath, entry); // Store handle for writing

        parentNode[entry.name] = {
          type: "file",
          name: entry.name,
          path: relativePath,
        };
      }
    } else if (entry.kind === "directory") {
      parentNode[entry.name] = {
        type: "dir",
        name: entry.name,
        children: {},
      };
      await processDirectoryHandle(
        entry,
        parentNode[entry.name].children,
        relativePath,
      );
    }
  }
}

function ensureDownloadButton() {
  // Legacy function removed as the UI now has dedicated HTML buttons.
  // Instead, we will attach event listeners to the new buttons here to comply with CSP.
  const btnChange = document.getElementById("btnSidebarChange");
  const btnDownload = document.getElementById("btnSidebarDownload");
  const btnClose = document.getElementById("btnSidebarClose");

  if (btnChange && !btnChange.hasAttribute("data-bound")) {
    btnChange.addEventListener("click", () => {
      if (window.selectFolder) {
        window.selectFolder();
      } else {
        const folderInput = document.getElementById("folderInput");
        if (folderInput) folderInput.click();
      }
    });
    btnChange.setAttribute("data-bound", "true");
  }

  if (btnDownload && !btnDownload.hasAttribute("data-bound")) {
    btnDownload.addEventListener("click", () => {
      if (typeof window.downloadFolderAsZip === "function") {
        window.downloadFolderAsZip();
      }
    });
    btnDownload.setAttribute("data-bound", "true");
  }

  if (btnClose && !btnClose.hasAttribute("data-bound")) {
    btnClose.addEventListener("click", () => {
      if (
        confirm(
          "Close project and clear session? Any unsaved changes will be lost.",
        )
      ) {
        sessionStorage.removeItem(STORAGE_KEY);
        location.reload();
      }
    });
    btnClose.setAttribute("data-bound", "true");
  }
}

function renderTree(node, container) {
  // Clear container first to prevent duplicates
  container.innerHTML = "";

  const ul = document.createElement("ul");
  ul.className = "tree-list";

  // Sort: Directories first, then files, alphabetical
  const entries = Object.values(node).sort((a, b) => {
    if (a.type === b.type) return a.name.localeCompare(b.name);
    return a.type === "dir" ? -1 : 1;
  });

  entries.forEach((item) => {
    const li = document.createElement("li");

    if (item.type === "dir") {
      li.className = "tree-dir expanded"; // Start expanded

      const label = document.createElement("div");
      label.className = "tree-item-label dir-label";
      label.innerHTML = `<i class="fas fa-folder-open icon"></i> <span class="text">${item.name}</span>`;

      label.onclick = (e) => {
        e.stopPropagation();
        li.classList.toggle("expanded");
        li.classList.toggle("collapsed");
        const icon = label.querySelector(".icon");
        if (li.classList.contains("collapsed")) {
          icon.className = "fas fa-folder icon";
        } else {
          icon.className = "fas fa-folder-open icon";
        }
      };

      li.appendChild(label);

      const childContainer = document.createElement("div");
      childContainer.className = "tree-children";
      renderTree(item.children, childContainer);
      li.appendChild(childContainer);
    } else {
      li.className = "tree-file";

      const label = document.createElement("div");
      label.className = "tree-item-label file-label";
      label.dataset.path = item.path;

      const isMod = modifiedFiles.has(item.path);

      // Mark as active if this is the current file
      if (item.path === currentFilePath) {
        label.classList.add("active");
      }

      label.innerHTML = `<i class="fas fa-file-alt icon"></i> <span class="text">${item.name}</span>${isMod ? " *" : ""}`;
      if (isMod) label.classList.add("text-warning");

      label.onclick = (e) => {
        e.stopPropagation();
        document
          .querySelectorAll(".file-label")
          .forEach((el) => el.classList.remove("active"));
        label.classList.add("active");

        loadFile(item.path, item.file);
      };

      li.appendChild(label);
    }

    ul.appendChild(li);
  });

  container.appendChild(ul);
}

function loadFile(path, file) {
  currentFilePath = path;
  console.log(currentFilePath)

  // Check modified
  if (modifiedFiles.has(path)) {
    processContent(modifiedFiles.get(path), path.split("/").pop());
    return;
  }

  // Check persisted virtual
  if (virtualFileMap.has(path)) {
    processContent(virtualFileMap.get(path), path.split("/").pop());
    return;
  }

  // Check physical (only active on first session)
  if (file) {
    const reader = new FileReader();
    reader.onload = (e) => {
      // Cache it if not already?
      virtualFileMap.set(path, e.target.result);
      processContent(e.target.result, file.name);
      console.log(e.target.result)
      saveSession(); // Update session with this file content if it wasn't there
    };
    reader.readAsText(file);
  } else {
    alert("File content unavailable. Please re-upload.");
  }
}

function processContent(text, fileName) {
  if (window.parseMarkdownToJSON) {
    const jsonData = window.parseMarkdownToJSON(text);
    window.generatedTestCases = jsonData;
    updateEditorView(fileName);
  } else {
    console.error("Markdown Parser not loaded");
  }
}

function updateEditorView(fileName) {
  // Refresh references for results.js
  if (window.elements) {
    window.elements.testCasesPreview =
      document.getElementById("testCasesPreview");
    window.elements.treeViewContent =
      document.getElementById("treeViewContent");
    window.elements.totalTestCases = document.getElementById("totalTestCases");
    // Add specific export targets
    window.elements.markdownContent =
      document.getElementById("markdownContent");
    window.elements.jsonContent = document.getElementById("jsonContent");
  }

  // Call render functions from results.js
  if (window.refreshAllUI) {
    window.refreshAllUI();
  } else if (window.renderTestCasesList) {
    window.renderTestCasesList();
  }

  // Update Header
  const titleEl = document.getElementById("editorFileTitle");
  if (titleEl) titleEl.textContent = fileName;
}

function showSaveToast(message, type = "success") {
  const toast = document.getElementById("md-save-toast");
  const msg = document.getElementById("md-save-toast-msg");
  if (!toast || !msg) return;
  msg.textContent = message;
  toast.className = `show ${type}`;
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => {
    toast.className = type; // remove 'show'
  }, 3000);
}

async function saveCurrentFile() {
  if (!currentFilePath || !window.generatedTestCases) {
    showSaveToast("No file loaded to save.", "error");
    return;
  }

  if (!window.generateMarkdown) {
    showSaveToast("Generator function not found.", "error");
    return;
  }

  const newContent = window.generateMarkdown(window.generatedTestCases);
  const fileName = currentFilePath.split("/").pop();

  // Always update in-memory store first
  modifiedFiles.set(currentFilePath, newContent);
  virtualFileMap.set(currentFilePath, newContent);
  saveSession();

  // Try fileHandleMap first, then re-acquire from dir handle
  let handle = fileHandleMap.get(currentFilePath);
  if (!handle && currentDirHandle) {
    handle = await getHandleFromDir(currentFilePath);
    if (handle) fileHandleMap.set(currentFilePath, handle); // cache it
  }

  if (handle) {
    // Write directly back to the original file — no dialog
    try {
      const writable = await handle.createWritable();
      await writable.write(newContent);
      await writable.close();
      modifiedFiles.delete(currentFilePath);
      showSaveToast(`✓ Saved to disk: ${fileName}`, "success");
    } catch (err) {
      console.error("Failed to write to disk:", err);
      showSaveToast(
        `Disk write failed for: ${fileName} — try re-opening the folder`,
        "error",
      );
    }
  } else {
    // No dir handle available — ask user to click Change Folder
    showSaveToast(
      `No disk access — click "Change Folder" to enable saving`,
      "error",
    );
  }

  // Update title and sidebar tree only — do NOT call refreshAllUI/updateEditorView
  // (the calling bridge handler already calls refreshAllUI after sync)
  const titleEl = document.getElementById("editorFileTitle");
  if (titleEl) titleEl.textContent = fileName;
  renderTree(fileTree, document.getElementById("folderTree"));
}

function fallbackDownload(content, filePath) {
  const fileName = filePath.split("/").pop();
  const blob = new Blob([content], { type: "text/markdown" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = fileName;
  a.click();
  URL.revokeObjectURL(url);
}

async function downloadFolderAsZip() {
  if (typeof JSZip === "undefined") {
    alert(
      "Could not load JSZip library. Please ensure it is included in the page headers.",
    );
    return;
  }

  const zip = new JSZip();
  // Use virtual map keys to find root folder logic
  const folderName =
    virtualFileMap.size > 0
      ? virtualFileMap.keys().next().value.split("/")[0]
      : "Project";

  // We want to zip everything we have: Modified + Virtual (Persisted)
  const allPaths = new Set([...virtualFileMap.keys(), ...modifiedFiles.keys()]);

  let processedCount = 0;

  for (const path of allPaths) {
    let content = null;
    if (modifiedFiles.has(path)) {
      content = modifiedFiles.get(path);
    } else if (virtualFileMap.has(path)) {
      content = virtualFileMap.get(path);
    }

    if (content !== null) {
      const relativePath = path.includes("/")
        ? path.substring(path.indexOf("/") + 1)
        : path;

      // We'll put everything in a root folder inside zip for tidiness
      zip.folder(folderName).file(relativePath, content);
      processedCount++;
    }
  }

  if (processedCount === 0) {
    alert("No files to download.");
    return;
  }

  const blob = await zip.generateAsync({ type: "blob" });
  const downloadLink = document.createElement("a");
  downloadLink.href = URL.createObjectURL(blob);
  downloadLink.download = `${folderName}.zip`;
  downloadLink.click();
}

// Session Persistence Functions
function saveSession() {
  try {
    const sessionData = {
      fileTree: fileTree,
      virtualFileMap: Array.from(virtualFileMap.entries()),
      modifiedFiles: Array.from(modifiedFiles.entries()),
      currentFilePath: currentFilePath,
    };
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(sessionData));
  } catch (e) {
    console.error("Failed to save session:", e);
  }
}

function restoreSession() {
  try {
    const stored = sessionStorage.getItem(STORAGE_KEY);
    if (!stored) return;

    const sessionData = JSON.parse(stored);
    fileTree = sessionData.fileTree || {};
    virtualFileMap = new Map(sessionData.virtualFileMap || []);
    modifiedFiles = new Map(sessionData.modifiedFiles || []);
    currentFilePath = sessionData.currentFilePath || null;

    // If we have data, show the editor
    if (Object.keys(fileTree).length > 0) {
      document.getElementById("uploadPrompt").style.display = "none";
      document.getElementById("mainEditorArea").style.display = "flex";

      const treeRoot = document.getElementById("folderTree");
      renderTree(fileTree, treeRoot);
      ensureDownloadButton();

      // Restore dir handle from IndexedDB so saves go directly to disk
      loadDirHandleIDB().then(async (savedHandle) => {
        if (savedHandle) {
          // Request permission silently (browser shows a small bar, not a dialog)
          const granted = await requestDirWritePermission(savedHandle);
          if (granted) {
            currentDirHandle = savedHandle;
          }
        }
      });

      // If there was a current file, reload it
      if (currentFilePath) {
        const content =
          modifiedFiles.get(currentFilePath) ||
          virtualFileMap.get(currentFilePath);
        if (content) {
          processContent(content, currentFilePath.split("/").pop());
        }
      }
    }
  } catch (e) {
    console.error("Failed to restore session:", e);
    sessionStorage.removeItem(STORAGE_KEY);
  }
}
/**
 * md-editor-bridge.js
 * -------------------------------------------------------
 * Patches results.js handlers specifically for the MD Editor
 * page so that Add/Edit/Delete operations work without
 * triggering a full page reload (which destroys the session).
 *
 * Must be loaded AFTER results.js and md-editor-logic.js.
 */

(function () {
  "use strict";

  // ── Toast notification ────────────────────────────────────────────────────
  function showToast(msg, type = "success") {
    const existing = document.getElementById("bridge-toast");
    if (existing) existing.remove();

    if (!document.getElementById("bridge-toast-style")) {
      const style = document.createElement("style");
      style.id = "bridge-toast-style";
      style.textContent = `
        @keyframes toastIn  { from { opacity:0; transform: translateY(10px); } to { opacity:1; transform: translateY(0); } }
        @keyframes toastOut { from { opacity:1; } to { opacity:0; } }
      `;
      document.head.appendChild(style);
    }

    const toast = document.createElement("div");
    toast.id = "bridge-toast";
    toast.style.cssText = `
      position: fixed; bottom: 2rem; right: 2rem; z-index: 99999;
      background: ${type === "success" ? "#10b981" : type === "error" ? "#ef4444" : "#0ea5e9"};
      color: white; padding: 0.75rem 1.5rem; border-radius: 10px;
      font-size: 0.9rem; font-weight: 600;
      box-shadow: 0 4px 20px rgba(0,0,0,0.2);
      animation: toastIn 0.3s ease; max-width: 360px;
    `;
    toast.innerHTML = `<span style="margin-right:0.5rem">${type === "success" ? "✓" : type === "error" ? "✗" : "ℹ"}</span>${msg}`;
    document.body.appendChild(toast);
    setTimeout(() => {
      toast.style.animation = "toastOut 0.3s ease forwards";
      setTimeout(() => toast.remove(), 350);
    }, 3000);
  }

  // ── Re-generate markdown, update memory + disk, update title only ──────────
  // IMPORTANT: Does NOT call refreshAllUI — the calling handler does that.
  function syncCurrentFileToVirtualMap() {
    if (
      typeof currentFilePath === "undefined" ||
      !currentFilePath ||
      !window.generateMarkdown ||
      !window.generatedTestCases
    )
      return;

    const newContent = window.generateMarkdown(window.generatedTestCases);
    const fileName = currentFilePath.split("/").pop();

    // 1. Update in-memory stores (DO NOT write to disk here)
    if (typeof virtualFileMap !== "undefined")
      virtualFileMap.set(currentFilePath, newContent);
    if (typeof modifiedFiles !== "undefined")
      modifiedFiles.set(currentFilePath, newContent);
    if (typeof saveSession === "function") saveSession();

    // 2. Update title to indicate pending changes (Unsaved)
    const titleEl = document.getElementById("editorFileTitle");
    if (titleEl) titleEl.textContent = `${fileName} (Unsaved changes)`;

    // Render tree to reflect updated state if applicable
    if (typeof renderTree === "function" && typeof fileTree !== "undefined") {
      renderTree(fileTree, document.getElementById("folderTree"));
    }
  }

  // ── Patch editModalElements lazily ────────────────────────────────────────
  // results.js caches element refs at load time when they may be null.
  // We re-populate them just-in-time before the modal opens.
  function refreshEditModalElements() {
    if (typeof editModalElements === "undefined") return;

    editModalElements.overlay = document.getElementById("editModal");
    editModalElements.title = document.getElementById("editTcTitle");
    editModalElements.steps = document.getElementById("editTcSteps");
    editModalElements.expected = document.getElementById("editTcExpected");
    editModalElements.scenarioType =
      document.getElementById("editTcScenarioType");
    editModalElements.executionType = document.getElementById(
      "editTcExecutionType",
    );
    editModalElements.tags = document.getElementById("editTcTags");
    editModalElements.evidenceContainer = document.getElementById(
      "evidenceListContainer",
    );
    editModalElements.saveBtn = document.getElementById("saveEdit");

    // Hidden index inputs — create if missing
    const ensure = (id) => {
      let el = document.getElementById(id);
      if (!el) {
        el = document.createElement("input");
        el.type = "hidden";
        el.id = id;
        document.body.appendChild(el);
      }
      return el;
    };

    editModalElements.stIdx = ensure("editStIdx");
    editModalElements.planIdx = ensure("editPlanIdx");
    editModalElements.suiteIdx = ensure("editSuiteIdx");
    editModalElements.tcIdx = ensure("editTcIdx");

    // Patch Plan/Suite modal element refs too
    if (typeof planEditModal !== "undefined" && !planEditModal) {
      window.planEditModal = document.getElementById("planEditModal");
    }
    if (typeof suiteEditModal !== "undefined" && !suiteEditModal) {
      window.suiteEditModal = document.getElementById("suiteEditModal");
    }
  }

  // Wrap the native openEditModal to refresh element cache first
  document.addEventListener("DOMContentLoaded", () => {
    // Give results.js a moment to define window.openEditModal
    setTimeout(() => {
      const _origOpenEditModal = window.openEditModal;
      window.openEditModal = function (stIdx, pIdx, sIdx, tIdx) {
        refreshEditModalElements();
        if (_origOpenEditModal) {
          _origOpenEditModal(stIdx, pIdx, sIdx, tIdx);
          // Ensure modal is visible (SQLPage uses display:none not just class)
          const overlay = document.getElementById("editModal");
          if (overlay && overlay.classList.contains("active")) {
            overlay.style.display = "flex";
          }
        }
      };

      // Same for Plan/Suite modals
      const _origOpenPlanEditModal = window.openPlanEditModal;
      window.openPlanEditModal = function (stIdx, pIdx) {
        refreshEditModalElements();
        // Ensure planEditModal ref is fresh
        window.planEditModal = document.getElementById("planEditModal");
        if (window.editPlanName) {
          /* keep from results.js */
        }
        if (_origOpenPlanEditModal) {
          _origOpenPlanEditModal(stIdx, pIdx);
          const overlay = document.getElementById("planEditModal");
          if (overlay && overlay.classList.contains("active")) {
            overlay.style.display = "flex";
          }
        }
      };

      const _origOpenSuiteEditModal = window.openSuiteEditModal;
      window.openSuiteEditModal = function (stIdx, pIdx, sIdx) {
        refreshEditModalElements();
        window.suiteEditModal = document.getElementById("suiteEditModal");
        if (_origOpenSuiteEditModal) {
          _origOpenSuiteEditModal(stIdx, pIdx, sIdx);
          const overlay = document.getElementById("suiteEditModal");
          if (overlay && overlay.classList.contains("active")) {
            overlay.style.display = "flex";
          }
        }
      };

      // Also patch closeAnyModal so it hides properly in SQLPage
      const _origCloseAnyModal = window.closeAnyModal;
      window.closeAnyModal = function (modal) {
        if (modal) {
          modal.classList.remove("active");
          modal.style.display = "none";
        }
      };

      // ── Patch SAVE buttons to close modals with display:none + toast ────
      // Edit Test Case — saveEdit
      const saveEditBtn = document.getElementById("saveEdit");
      if (saveEditBtn) {
        saveEditBtn.addEventListener("click", () => {
          // Give handleSaveTestCaseEdit a tick to finish first
          setTimeout(() => {
            const m = document.getElementById("editModal");
            if (m && m.dataset.saveBlocked === "true") {
              m.dataset.saveBlocked = "false"; // reset
              return; // abort save
            }
            if (m) {
              m.classList.remove("active");
              m.style.display = "none";
            }
            if (typeof window.refreshAllUI === 'function') window.refreshAllUI();
            syncCurrentFileToVirtualMap();
            showToast("Test Case Updated. Click 'Save Changes' button to apply changes.", "success");
          }, 30);
        });
      }

      // Edit Plan — savePlanEdit
      const savePlanEditBtn = document.getElementById("savePlanEdit");
      if (savePlanEditBtn) {
        savePlanEditBtn.addEventListener("click", () => {
          setTimeout(() => {
            const m = document.getElementById("planEditModal");
            if (m) {
              m.classList.remove("active");
              m.style.display = "none";
            }
            if (typeof window.refreshAllUI === 'function') window.refreshAllUI();
            syncCurrentFileToVirtualMap();
            showToast("Plan applied! Click 'Save Changes' to persist changes.", "success");
          }, 30);
        });
      }

      // Edit Suite — saveSuiteEdit
      const saveSuiteEditBtn = document.getElementById("saveSuiteEdit");
      if (saveSuiteEditBtn) {
        saveSuiteEditBtn.addEventListener("click", () => {
          setTimeout(() => {
            const m = document.getElementById("suiteEditModal");
            if (m) {
              m.classList.remove("active");
              m.style.display = "none";
            }
            if (typeof window.refreshAllUI === 'function') window.refreshAllUI();
            syncCurrentFileToVirtualMap();
            showToast("Suite applied! Click 'Save Changes' to persist changes.", "success");
          }, 30);
        });
      }

      // ── Patch editModal close/cancel buttons ─────────────────────────────
      ["closeModal", "cancelEdit"].forEach((id) => {
        const btn = document.getElementById(id);
        if (btn) {
          btn.addEventListener("click", () => {
            const m = document.getElementById("editModal");
            if (m) {
              m.classList.remove("active");
              m.style.display = "none";
            }
          });
        }
      });

      // ── Patch Plan/Suite close/cancel buttons ────────────────────────────
      [
        { btns: ["closePlanEdit", "cancelPlanEdit"], modalId: "planEditModal" },
        {
          btns: ["closeSuiteEdit", "cancelSuiteEdit"],
          modalId: "suiteEditModal",
        },
      ].forEach(({ btns, modalId }) => {
        btns.forEach((id) => {
          const btn = document.getElementById(id);
          if (btn) {
            btn.addEventListener("click", () => {
              const m = document.getElementById(modalId);
              if (m) {
                m.classList.remove("active");
                m.style.display = "none";
              }
            });
          }
        });
      });

      // ── Pre-fill today's date and assignee dropdowns ──────────────────────
      const today = new Date();
      const y = today.getFullYear();
      const m = String(today.getMonth() + 1).padStart(2, "0");
      const d = String(today.getDate()).padStart(2, "0");
      const isoToday = `${y}-${m}-${d}`;
      const displayToday = `${m}-${d}-${y}`;
      // Set both bulkCycleDate (hidden ISO) and bulkCycleDateText (display MM-DD-YYYY)
      const cycleDateHidden = document.getElementById("bulkCycleDate");
      if (cycleDateHidden) cycleDateHidden.value = isoToday;
      const cycleDateText = document.getElementById("bulkCycleDateText");
      if (cycleDateText) cycleDateText.value = displayToday;
      // Populate assignee selects from results.js assigneeMaster (if available)
      const assigneeSelects = [
        "bulkAssignSelect",
        "bulkCycleAssignee",
        "bulkEditAssignee",
        "editPlanCreatedBy",
        "editSuiteCreatedBy",
      ];
      const master =
        typeof assigneeMaster !== "undefined" && Array.isArray(assigneeMaster)
          ? assigneeMaster
          : [];
      if (master.length > 0) {
        const opts = master
          .map((u) => {
            const name = typeof u === "string" ? u : u.name;
            return `<option value="${name}">${name}</option>`;
          })
          .join("");
        assigneeSelects.forEach((id) => {
          const el = document.getElementById(id);
          if (el) {
            let defaultText = "-- Assignee --";
            if (id.includes("CreatedBy") || id === "bulkEditAssignee") {
              defaultText = "-- No Change --";
            }
            if (id === "bulkAssignSelect") {
              defaultText = "-- Choose User --";
            }
            el.innerHTML = `<option value="">${defaultText}</option>` + opts;
          }
        });
      }

      // Populate Scenario Types
      const scMaster =
        typeof scenarioMaster !== "undefined" ? scenarioMaster : [];
      const scEl = document.getElementById("bulkScenarioType");
      if (scEl && scMaster.length > 0) {
        const scOpts = scMaster
          .map((s) => `<option value="${s}">${s}</option>`)
          .join("");
        scEl.innerHTML =
          `<option value="">-- Scenario Type --</option>` + scOpts;
      }

      // Populate Execution Types
      const exMaster =
        typeof executionMaster !== "undefined" ? executionMaster : [];
      const exEl = document.getElementById("bulkExecutionType");
      if (exEl && exMaster.length > 0) {
        const exOpts = exMaster
          .map((s) => `<option value="${s}">${s}</option>`)
          .join("");
        exEl.innerHTML = `<option value="">-- Exec Type --</option>` + exOpts;
      }

      // Populate Statuses
      const stMaster = typeof statusMaster !== "undefined" ? statusMaster : [];
      const stEl = document.getElementById("bulkCycleStatus");
      if (stEl && stMaster.length > 0) {
        const stOpts = stMaster
          .map((s) => `<option value="${s}">${s}</option>`)
          .join("");
        stEl.innerHTML =
          `<option value="">-- Choose Status --</option>` + stOpts;
      }

      // ── Backdrop click to close all modals ───────────────────────────────
      document.querySelectorAll(".modal-overlay").forEach((m) => {
        m.addEventListener("click", (e) => {
          if (e.target === m) {
            m.classList.remove("active");
            m.style.display = "none";
          }
        });
      });

      // ── "+ Add Evidence" button in Edit TC modal ─────────────────────────
      const addEvidenceBtn = document.getElementById("addEvidenceRowBtn");
      if (addEvidenceBtn) {
        addEvidenceBtn.addEventListener("click", () => {
          // Determine next cycle number
          const existingRows = document.querySelectorAll(
            "#evidenceListContainer .evidence-row",
          );
          let nextCycle = "1.0";
          if (existingRows.length > 0) {
            let maxC = 0;
            existingRows.forEach((row) => {
              const cycleEl = row.querySelector(".ev-cycle");
              if (cycleEl) {
                const c = parseFloat(cycleEl.value);
                if (!isNaN(c) && c > maxC) maxC = c;
              }
            });
            if (maxC > 0) nextCycle = (maxC + 0.1).toFixed(1);
          }

          // Get default assignee from existing evidence or assignee master
          const today = new Date();
          const y = today.getFullYear();
          const m = String(today.getMonth() + 1).padStart(2, "0");
          const d = String(today.getDate()).padStart(2, "0");
          const isoToday = `${y}-${m}-${d}`;
          const displayToday = `${m}-${d}-${y}`;

          // Build a blank evidence row the same way addEvidenceRowToModal does
          const noPlaceholder = document.getElementById(
            "noEvidencePlaceholder",
          );
          if (noPlaceholder) noPlaceholder.remove();

          if (typeof addEvidenceRowToModal === "function") {
            addEvidenceRowToModal({
              cycle: "nextec-ev-cycle",
              status: "To-do",
              cycleDate: isoToday,
              assignee: "",
              attachments: "",
            });
          } else {
            // Fallback: build row manually if addEvidenceRowToModal is not accessible
            const ctn = document.getElementById("evidenceListContainer");
            if (!ctn) return;
            const row = document.createElement("div");
            row.className = "evidence-row";
            row.style =
              "background: rgba(255,255,255,0.03); padding: 1rem; border-radius: 8px; border: 1px solid var(--border-color); position: relative; margin-bottom: 0.5rem;";
            row.innerHTML = `
              <button type="button" class="remove-evidence" style="position: absolute; top: 0.5rem; right: 0.5rem; background: none; border: none; color: #ff5555; cursor: pointer; font-size: 1.2rem;">&times;</button>
              <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem; margin-bottom: 0.5rem;">
                <input type="text" class="form-input ev-cycle" value="${nextCycle}" placeholder="Cycle">
                <select class="form-input ev-status">
                  ${["To-do", "In Progress", "Passed", "Failed", "Blocked", "Skipped", "Pending"].map((s) => `<option value="${s}"${s === "To-do" ? " selected" : ""}>${s}</option>`).join("")}
                </select>
              </div>
              <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem; margin-bottom: 0.5rem;">
                <div style="display: flex; align-items: center; position: relative;">
                  <input type="text" class="form-input ev-date" value="${displayToday}" placeholder="MM-DD-YYYY" style="width: 100%; cursor: pointer; padding-right:25px;">
                  <input type="hidden" class="ev-date-iso" value="${isoToday}">
                  <i class="fas fa-calendar-alt" style="position: absolute; right: 8px; pointer-events: none; color: #94a3b8; font-size: 0.8rem;"></i>
                </div>
                <select class="form-input ev-assignee">
                  <option value="Unassigned">-- Assignee --</option>
                </select>
              </div>
              <div style="margin-top: 0.5rem;">
                <textarea class="form-input ev-attachments" rows="2" placeholder="Attachments (Markdown Links e.g. - [Label](url))" style="font-size: 0.85rem;"></textarea>
              </div>
            `;
            row.querySelector(".remove-evidence").addEventListener("click", () => row.remove());
            ctn.appendChild(row);
            // pikaday is now handled automatically by MutationObserver in md-date-picker.js
          }
        });
      }

      console.log("[Bridge] MD Editor Bridge active — modal patches applied.");
    }, 500);
  });

  // ── Wrap refreshAllUI to also sync session ────────────────────────────────
  const _origRefreshAllUI = window.refreshAllUI;
  window.refreshAllUI = function () {
    if (_origRefreshAllUI) _origRefreshAllUI();
    if (window.isMdEditorMode || true) {
      syncCurrentFileToVirtualMap();
    }
  };

  // ── Delete Handlers (prevent page reload) ─────────────────────────────────
  window.handleDeletePlan = function (stIdx, pIdx) {
    const label = ["3", "4"].includes(window.generatedTestCases?.schemaLevel)
      ? "Project"
      : "Plan";
    if (
      !confirm(
        `WARNING: Deleting this ${label} will permanently remove ALL its Suites and Test Cases!\n\nAre you sure?`,
      )
    )
      return;

    if (
      window.generatedTestCases.schemaLevel === "6" &&
      stIdx != null &&
      stIdx !== "null"
    ) {
      window.generatedTestCases.strategies[stIdx].plans.splice(pIdx, 1);
    } else {
      window.generatedTestCases.plans.splice(pIdx, 1);
    }
    window.refreshAllUI();
    syncCurrentFileToVirtualMap();
    showToast(`${label} deleted.`);
  };

  window.handleDeleteSuite = function (stIdx, pIdx, sIdx) {
    if (
      !confirm(
        "WARNING: Deleting this SUITE will permanently remove ALL its Test Cases!\n\nAre you sure?",
      )
    )
      return;

    let plan;
    if (
      window.generatedTestCases.schemaLevel === "6" &&
      stIdx != null &&
      stIdx !== "null"
    ) {
      plan = window.generatedTestCases.strategies[stIdx].plans[pIdx];
    } else {
      plan = window.generatedTestCases.plans[pIdx];
    }
    if (plan) {
      plan.suites.splice(sIdx, 1);
      window.refreshAllUI();
      syncCurrentFileToVirtualMap();
      showToast("Suite deleted.");
    }
  };

  window.handleDeleteTestCase = function (stIdx, pIdx, sIdx, tIdx) {
    if (!confirm("Are you sure you want to delete this Test Case?")) return;

    let suite;
    if (
      window.generatedTestCases.schemaLevel === "6" &&
      stIdx != null &&
      stIdx !== "null"
    ) {
      suite =
        window.generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx];
    } else {
      suite = window.generatedTestCases.plans[pIdx].suites[sIdx];
    }
    if (suite) {
      suite.testCases.splice(tIdx, 1);
      window.refreshAllUI();
      syncCurrentFileToVirtualMap();
      showToast("Test Case deleted.");
    }
  };

  // ── Quick inline edits ────────────────────────────────────────────────────
  window.handleQuickPriority = function (stIdx, pIdx, sIdx, tIdx, value) {
    let suite;
    if (
      window.generatedTestCases.schemaLevel === "6" &&
      stIdx != null &&
      stIdx !== "null"
    ) {
      suite =
        window.generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx];
    } else {
      suite = window.generatedTestCases.plans[pIdx].suites[sIdx];
    }
    if (suite && suite.testCases[tIdx]) {
      suite.testCases[tIdx].priority = value;
      syncCurrentFileToVirtualMap();
      showToast("Priority updated.", "info");
    }
  };

  window.handleQuickAssign = function (stIdx, pIdx, sIdx, tIdx, value) {
    let suite;
    if (
      window.generatedTestCases.schemaLevel === "6" &&
      stIdx != null &&
      stIdx !== "null"
    ) {
      suite =
        window.generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx];
    } else {
      suite = window.generatedTestCases.plans[pIdx].suites[sIdx];
    }
    if (suite && suite.testCases[tIdx]) {
      suite.testCases[tIdx].assignee = value;
      if (suite.testCases[tIdx].evidenceHistory?.length > 0) {
        suite.testCases[tIdx].evidenceHistory[0].assignee = value;
      }
      syncCurrentFileToVirtualMap();
      showToast("Assignee updated.", "info");
    }
  };

  // ── Delete Evidence ───────────────────────────────────────────────────────
  window.handleDeleteEvidence = function (stIdx, pIdx, sIdx, tIdx, evIdx) {
    if (!confirm("Delete this cycle evidence record?")) return;
    let suite;
    if (
      window.generatedTestCases.schemaLevel === "6" &&
      stIdx != null &&
      stIdx !== "null"
    ) {
      suite =
        window.generatedTestCases.strategies[stIdx].plans[pIdx].suites[sIdx];
    } else {
      suite = window.generatedTestCases.plans[pIdx].suites[sIdx];
    }
    if (suite && suite.testCases[tIdx]) {
      suite.testCases[tIdx].evidenceHistory.splice(evIdx, 1);
      window.refreshAllUI();
      syncCurrentFileToVirtualMap();
      showToast("Evidence deleted.");
    }
  };

  // ── Bulk Delete (prevent page reload) ────────────────────────────────────
  window.handleBulkDelete = function () {
    const selected = document.querySelectorAll(".tc-checkbox:checked");
    if (selected.length === 0) {
      showToast("Please select at least one test case to delete.", "error");
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
      if (window.generatedTestCases.schemaLevel === "6" && item.st !== null) {
        suite =
          window.generatedTestCases.strategies[item.st].plans[item.p].suites[
          item.s
          ];
      } else {
        suite = window.generatedTestCases.plans[item.p].suites[item.s];
      }
      if (suite) {
        suite.testCases.splice(item.t, 1);
      }
    });

    window.refreshAllUI();
    syncCurrentFileToVirtualMap();
    const selectAll = document.getElementById("selectAllTcs");
    if (selectAll) selectAll.checked = false;
    if (window.updateSelectedCount) window.updateSelectedCount();
    showToast(`${selected.length} test cases deleted.`);
  };

  // ── Expose helpers globally ───────────────────────────────────────────────
  window.mdEditorBridge = {
    syncCurrentFile: syncCurrentFileToVirtualMap,
    showToast,
  };
})();
