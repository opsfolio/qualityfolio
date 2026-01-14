

/**
 * opsfolio-integration.js
 *
 * Purpose:
 *  - Detect when SQLPage is running inside an iframe
 *  - Extract header and breadcrumb data from already-rendered HTML
 *  - Send extracted metadata to the parent application
 *  - Remove child-level UI (header, breadcrumbs, spacing)
 *
 * Behavior:
 *  - If NOT inside an iframe → do nothing
 *  - If inside an iframe → auto-run on DOMContentLoaded
 *
 * No configuration required by page authors.
 */

/* ----------------------------------------------------------
 * Utility: Detect iframe context (cross-origin safe)
 * ---------------------------------------------------------- */
function isInIframe() {
    try {
        return window.self !== window.top;
    } catch (e) {
        // Cross-origin access throws SecurityError → definitely iframe
        return true;
    }
}

/* ----------------------------------------------------------
 * Extract header text BEFORE removal
 * ---------------------------------------------------------- */
function extractHeader() {
    const header = document.getElementById("sqlpage_header");
    if (!header) return null;

    return header.textContent?.trim() || null;
}

/* ----------------------------------------------------------
 * Extract breadcrumbs BEFORE removal
 * ---------------------------------------------------------- */
function extractBreadcrumbs() {
    const breadcrumbNav = document.querySelector('nav[aria-label="breadcrumb"]');
    if (!breadcrumbNav) return [];

    const breadcrumbs = [];
    const links = breadcrumbNav.querySelectorAll("li a");

    links.forEach(link => {
        breadcrumbs.push({
            label: link.textContent?.trim() || "",
            href: link.getAttribute("href") || "#"
        });
    });

    return breadcrumbs;
}

/* ----------------------------------------------------------
 * Send metadata to parent window
 * ---------------------------------------------------------- */
function notifyParent(payload) {

    if (!window.parent) return;

    window.parent.postMessage(
        {
            source: "opsfolio-sqlpage",
            type: "ui-metadata",
            payload
        },
        "*"
    );
}

/* ----------------------------------------------------------
 * Remove child UI after extraction
 * ---------------------------------------------------------- */
function cleanupChildUI() {
    // Remove SQLPage header
    document.getElementById("sqlpage_header")?.remove();

    // Remove breadcrumb navigation
    document.querySelector('nav[aria-label="breadcrumb"]')?.remove();

    // Normalize background
    const layoutFluid = document.querySelector(".layout-fluid");
    if (layoutFluid) {
        layoutFluid.style.backgroundColor = "#FFFFFF";
    }

    // Remove top spacing added for fixed header
    const mainWrapper = document.getElementById("sqlpage_main_wrapper");
    if (mainWrapper) {
        mainWrapper.classList.remove("mt-5", "pt-5");
    }
}

/* ----------------------------------------------------------
 * Main integration workflow
 * ---------------------------------------------------------- */
function runOpsfolioIntegration() {
    if (!isInIframe()) return;

    const header = extractHeader();
    const breadcrumbs = extractBreadcrumbs();

    notifyParent({
        header,
        breadcrumbs
    });

    cleanupChildUI();
}

/* ----------------------------------------------------------
 * Auto-run after DOM is fully loaded
 * ---------------------------------------------------------- */
document.addEventListener("DOMContentLoaded", runOpsfolioIntegration);
/* ----------------------------------------------------------
 * Listen for navigation requests from parent (Astro)
 * ---------------------------------------------------------- */
window.addEventListener("message", (event) => {
    if (event.data?.type === "navigate-home" && event.data.href) {
        // Navigate iframe to its home
        window.location.href = event.data.href;
    }
});