/**
 * QualityFolio Layout Framework
 * Injects the sidebar + topbar and restructures the page
 * to match the reference Qualityfolio design system.
 */
(function () {
  // ── Config ──────────────────────────────────────────────────────────────
  const USER_NAME = "Rahul Raj";
  const USER_ROLE = "QA Engineer";
  const USER_STATUS = "Online";
  const LOGO_SRC = "/logo.png";

  // ── Nav config ──────────────────────────────────────────────────────────
  const NAVIGATION = [
    {
      section: "Main Menu",
      items: [
        { label: "Generator", href: "entries.sql", icon: iconFolder() },
        {
          label: "Markdown Editor",
          href: "md_editor.sql",
          icon: `<svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/></svg>`,
        },
        { label: "View Dashboard", href: "dashboard.sql", icon: iconSettings() },
        { label: "Settings", href: "settings.sql", icon: iconSettings() },

      ],
    },
  ];

  // ── Icon SVGs ────────────────────────────────────────────────────────────
  function iconFolder() {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>`;
  }
  function iconSettings() {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>`;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PAGE TITLE MAP
  // ════════════════════════════════════════════════════════════════════════════
  const PAGE_TITLES = {
    entries: [
      "Test Case Generator",
      "Configure your project and generate test cases with AI",
    ],
    plans: ["Plans", "Manage test plans for this project"],
    suites: ["Test Suites", "Organize and manage test suites"],
    test_cases: ["Test Cases", "View and manage test cases"],
    evidence: ["Evidence", "Track test evidence and results"],
    settings: ["Settings", "Configure team members and preferences"],
    md_editor: ["Markdown Editor", "Edit and manage markdown files"],
    edit_project: ["Edit Project", "Update project configuration"],
    edit_plan: ["Edit Plan", "Modify plan details"],
    edit_suite: ["Edit Suite", "Update suite information"],
    edit_test_case: ["Edit Test Case", "Modify test case details"],
    edit_evidence: ["Edit Evidence", "Update evidence record"],
    save_project: ["Create Project", "Setting up your new project"],
    generate_test_cases: ["AI Generator", "Creating test cases with AI"],
    bulk_assign_test_cases: ["Bulk Operations", "Assign test cases to team"],
    download_project: ["Export", "Downloading project data"],
    "": ["Dashboard", "Welcome to QualityFolio"],
  };

  // ── Helpers ──────────────────────────────────────────────────────────────
  function initials(name) {
    return name
      .split(" ")
      .map((w) => w[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UTILITY FUNCTIONS
  // ════════════════════════════════════════════════════════════════════════════

  function getInitials(name) {
    return name
      .split(" ")
      .map((word) => word.charAt(0))
      .join("")
      .toUpperCase()
      .slice(0, 2);
  }

  function getCurrentPage() {
    const path = window.location.pathname;
    const filename = path.split("/").pop().replace(/\.(sql|html)$/, "");
    return filename || "";
  }

  function getPageInfo() {
    const page = getCurrentPage();
    const [title, subtitle] = PAGE_TITLES[page] || [
      page.replace(/_/g, " ").toUpperCase(),
      "",
    ];
    return { title, subtitle };
  }

  // function getPageTitle() {
  //   const path = window.location.pathname;
  //   const file = path.split("/").pop().replace(".sql", "");
  //   const map = {
  //     entries: [
  //       "Generator",
  //       "Configure your project and generate test cases with AI",
  //     ],
  //     plans: ["Plans", "Manage plans for this project"],
  //     suites: ["Suites", "Manage test suites"],
  //     test_cases: ["Test Cases", "Manage test cases"],
  //     evidence: ["Evidence", "Manage evidence records"],
  //     settings: ["Settings", "Configure team members and test types"],
  //     md_editor: ["Markdown Editor", "Edit Markdown files"],
  //     edit_project: ["Edit Project", "Update project details"],
  //     edit_plan: ["Edit Plan", "Update plan details"],
  //     edit_suite: ["Edit Suite", "Update suite details"],
  //     edit_test_case: ["Edit Test Case", "Update test case details"],
  //     edit_evidence: ["Edit Evidence", "Update evidence details"],
  //     save_project: ["New Project", "Creating your project…"],
  //     generate_test_cases: ["AI Generator", "Generating test cases with AI"],
  //     bulk_assign_test_cases: [
  //       "Bulk Assign",
  //       "Assign test cases to team members",
  //     ],
  //     download_project: ["Download", "Exporting project files"],
  //     "": ["Dashboard", "Welcome to QualityFolio"],
  //   };
  //   return map[file] || [file || "Dashboard", ""];
  // }

  function activeHref() {
    const file = window.location.pathname.split("/").pop();
    // Return the filename as-is so it matches the href in the NAV config
    if (file) return file;
    return "entries.sql"; // default to Generator for root/dashboard
  }

  // ── Inject theme CSS (if not already) ────────────────────────────────────
  function injectTheme() {
    if (!document.querySelector('link[href*="theme.css"]')) {
      const link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = "/css/theme.css";
      document.head.prepend(link);
    }
  }

  // ── Build Sidebar ────────────────────────────────────────────────────────
  function buildSidebar() {

    const currentPage = getCurrentPage();
    let navHTML = "";

    NAVIGATION.forEach((section) => {
      navHTML += `<div class="qf-nav-section-title">${section.section}</div>`;
      section.items.forEach((item) => {
        const isActive = currentPage === item.href.replace(/\.(sql|html)$/, "");
        const activeClass = isActive ? " active" : "";

        navHTML += `
          <a href="/${item.href}" class="qf-nav-link${activeClass}" title="${item.label}">
            <span class="nav-icon">${item.icon}</span>
            <span>${item.label}</span>
          </a>`;
      });
    });

    const sidebar = document.createElement("aside");
    sidebar.id = "qf-sidebar";
    sidebar.innerHTML = `
      <a href="/entries.sql" class="qf-logo">
        <img src="${LOGO_SRC}" alt="QualityFolio" onerror="this.style.display='none'" />
      </a>
      <nav class="qf-nav">${navHTML}</nav>
      <div class="qf-user">
        <div class="qf-user-avatar">${getInitials(USER_NAME)}</div>
        <div>
          <div class="qf-user-name">${USER_ROLE}</div>
          <div class="qf-user-role">${USER_STATUS}</div>
        </div>
      </div>
    `;

    document.body.prepend(sidebar);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD TOPBAR — Modern Design
  // ════════════════════════════════════════════════════════════════════════════
  function buildTopbar() {
    const { title, subtitle } = getPageInfo();
    const initials = getInitials(USER_NAME);
    console.log(initials);
    const topbar = document.createElement("header");
    topbar.id = "qf-topbar";
    topbar.innerHTML = `
      <div class="qf-page-info">
        <div class="qf-page-title">${title}</div>
        ${subtitle ? `<div class="qf-page-subtitle">${subtitle}</div>` : ""}
      </div>
      <div class="qf-topbar-right">
        <div class="qf-user-info">
          <div class="qf-user-info-name">${USER_NAME}</div>
          <div class="qf-user-info-status">${USER_STATUS}</div>
        </div>
        <div class="qf-topbar-divider"></div>
        <div class="qf-avatar-badge" title="${USER_NAME}">${initials}</div>
      </div>
    `;

    document.body.prepend(topbar);
  }
  // ── Hide default SQLPage Navbar ──────────────────────────────────────────
  function hideDefaultNav() {
    const selectors = [
      ".navbar",
      ".navbar-brand",
      "nav.navbar",
      "#sqlpage_header",
      ".sqlpage-menu",
    ];
    selectors.forEach((s) => {
      document.querySelectorAll(s).forEach((el) => {
        el.style.cssText = "display:none!important";
      });
    });
  }

  // ── Wrap main content ────────────────────────────────────────────────────
  function wrapContent() {
    // Move direct child nodes (excluding sidebar+topbar) into a wrapper div
    const wrapper = document.createElement("div");
    wrapper.id = "qf-main";

    // Move all body children except sidebar/topbar into wrapper
    const children = Array.from(document.body.childNodes);
    children.forEach((child) => {
      const id = child.id || "";
      if (id !== "qf-sidebar" && id !== "qf-topbar") {
        wrapper.appendChild(child);
      }
    });
    document.body.appendChild(wrapper);
  }

  // ── Init ─────────────────────────────────────────────────────────────────
  function init() {
    injectTheme();
    buildSidebar();
    buildTopbar();
    hideDefaultNav();
    wrapContent();

    // Watch for dynamically added navbars and hide them
    const observer = new MutationObserver(() => hideDefaultNav());
    observer.observe(document.body, { childList: true, subtree: true });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
