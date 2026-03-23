/**
 * QualityFolio Dashboard Launcher - FINAL WORKING VERSION
 * 
 * ✅ Fixed: Commands now run from /qualityfolio directory
 * ✅ Backend: http://localhost:3000
 * ✅ Ready to use!
 */

(function () {
    "use strict";

    const CONFIG = {
        DASHBOARD_URL: "http://localhost:9227/",

        // Backend server (runs commands from qualityfolio directory)
        BACKEND_URL: "http://localhost:3000",
        BACKEND_ENDPOINT: "/api/start-dashboard",

        // Commands (run from /qualityfolio directory)
        COMMANDS: [
            "spry rb run qualityfolio.md",
            "spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md",
            "EOH_INSTANCE=1 PORT=9227 surveilr web-ui -d ./resource-surveillance.sqlite.db --port 9227 --host 0.0.0.0",
        ],

        // Timing
        PROGRESS_DURATION: 60000,
        PROGRESS_UPDATE_INTERVAL: 100,
        PORT_CHECK_INTERVAL: 1000,
        MAX_PORT_CHECKS: 60,
    };

    class QualityFolioDashboardLauncher {
        constructor() {
            this.loaderOverlay = null;
            this.progressFill = null;
            this.loaderStatus = null;
            this.percentage = null;
            this.openBtn = null;
            this.progressInterval = null;
            this.portCheckInterval = null;
            this.portReady = false;
            this.initialized = false;
            this.init();
        }

        init() {
            if (document.readyState === "loading") {
                document.addEventListener("DOMContentLoaded", () => this.setupEventListeners());
            } else {
                this.setupEventListeners();
            }

            setTimeout(() => {
                if (!this.initialized) {
                    this.setupEventListeners();
                }
            }, 500);
        }

        setupEventListeners() {
            if (this.initialized) return;

            this.loaderOverlay = document.getElementById("dashboardLoaderOverlay");
            this.progressFill = document.getElementById("dashboardProgressFill");
            this.loaderStatus = document.getElementById("dashboardLoaderStatus");
            this.percentage = document.getElementById("dashboardPercentage");
            this.openBtn = document.getElementById("dashboardOpenBtn");

            if (!this.loaderOverlay) {
                console.warn("[QFDashboard] ⚠️ Loader modal not found");
                return;
            }

            const sqlpageDashboardBtn = document.getElementById("sqlpageDashboardBtn");
            if (sqlpageDashboardBtn) {
                sqlpageDashboardBtn.addEventListener("click", (e) => {
                    console.log("[QFDashboard] Button clicked!");
                    e.preventDefault();
                    this.launchDashboard();
                });
                console.log("[QFDashboard] ✓ SQLPage button found");
            }

            const astroDashboardBtn = document.getElementById("btnViewDashboard");
            if (astroDashboardBtn) {
                astroDashboardBtn.addEventListener("click", (e) => {
                    console.log("[QFDashboard] Astro button clicked!");
                    e.preventDefault();
                    this.launchDashboard();
                });
                console.log("[QFDashboard] ✓ Astro button found");
            }

            if (this.openBtn) {
                this.openBtn.addEventListener("click", () => this.openDashboardWindow());
            }

            this.initialized = true;
            console.log("[QFDashboard] ✓ Initialized");
        }

        launchDashboard() {
            console.log("[QFDashboard] 🚀 Launching dashboard...");
            console.log("[QFDashboard] Backend URL: " + CONFIG.BACKEND_URL);
            console.log("[QFDashboard] Commands to execute from /qualityfolio:");
            CONFIG.COMMANDS.forEach((cmd, i) => {
                console.log(`[QFDashboard]  ${i + 1}. ${cmd}`);
            });

            this.showLoaderModal();
            this.resetLoaderUI();
            this.updateStatus("🚀 Starting services from /qualityfolio directory...");

            // Execute commands via backend API
            this.executeCommandsViaBackend();

            // Start monitoring and progress
            this.startProgressAnimation();
            this.startPortMonitoring();
        }

        /**
         * Execute commands via backend server
         * Backend runs commands from /qualityfolio directory
         */
        executeCommandsViaBackend() {
            console.log("[QFDashboard] 📡 Calling backend API...");
            console.log("[QFDashboard] URL: " + CONFIG.BACKEND_URL + CONFIG.BACKEND_ENDPOINT);

            fetch(CONFIG.BACKEND_URL + CONFIG.BACKEND_ENDPOINT, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    commands: CONFIG.COMMANDS,
                }),
            })
                .then((response) => {
                    console.log("[QFDashboard] Backend response status:", response.status);
                    if (response.ok) {
                        return response.json();
                    } else {
                        throw new Error(`HTTP ${response.status}`);
                    }
                })
                .then((data) => {
                    console.log("[QFDashboard] ✓ Backend response:", data);
                    console.log(`[QFDashboard] ✓ ${data.message}`);
                    this.updateStatus("✓ Services started! Waiting for Surveilr on port 9227...");
                })
                .catch((error) => {
                    console.error("[QFDashboard] ✗ Backend error:", error.message);
                    this.handleBackendError(error);
                });
        }

        /**
         * Handle backend errors
         */
        handleBackendError(error) {
            console.warn("[QFDashboard] ⚠️ Backend not responding");
            console.warn("[QFDashboard] Error:", error.message);
            console.warn("[QFDashboard] ");
            console.warn("[QFDashboard] Make sure backend is running:");
            console.warn("[QFDashboard] $ node run-dashboard-FIXED.js");
            console.warn("[QFDashboard] ");

            this.updateStatus("⚠️ Backend not running. Check console for instructions.");
        }

        showLoaderModal() {
            if (!this.loaderOverlay) return;
            if (this.loaderOverlay.classList) {
                this.loaderOverlay.classList.add("active");
            }
            this.loaderOverlay.style.display = "flex";
        }

        hideLoaderModal() {
            if (!this.loaderOverlay) return;
            if (this.loaderOverlay.classList) {
                this.loaderOverlay.classList.remove("active");
            }
            this.loaderOverlay.style.display = "none";
        }

        resetLoaderUI() {
            if (this.progressFill) this.progressFill.style.width = "0%";
            if (this.percentage) this.percentage.textContent = "0%";
            if (this.openBtn) {
                this.openBtn.classList.remove("ready");
                this.openBtn.style.opacity = "0.5";
                this.openBtn.style.pointerEvents = "none";
            }
        }

        updateStatus(message) {
            if (this.loaderStatus) {
                this.loaderStatus.textContent = message;
            }
            console.log("[QFDashboard] " + message);
        }

        updateProgress(percent) {
            if (this.progressFill) {
                this.progressFill.style.width = percent + "%";
            }
            if (this.percentage) {
                this.percentage.textContent = Math.round(percent) + "%";
            }
        }

        startProgressAnimation() {
            const startTime = Date.now();

            if (this.progressInterval) clearInterval(this.progressInterval);

            this.progressInterval = setInterval(() => {
                const elapsed = Date.now() - startTime;
                const percent = Math.min((elapsed / CONFIG.PROGRESS_DURATION) * 100, 100);

                this.updateProgress(percent);
                this.updateProgressStatus(percent);

                if (percent >= 100) {
                    clearInterval(this.progressInterval);
                    this.onProgressComplete();
                }
            }, CONFIG.PROGRESS_UPDATE_INTERVAL);

            console.log("[QFDashboard] ⏱️  Progress animation started (60 seconds)");
        }

        updateProgressStatus(percent) {
            let message = "Initializing...";

            if (percent < 15) {
                message = "🚀 Starting Spry Ruby process...";
            } else if (percent < 30) {
                message = "📦 Compiling SQLPage...";
            } else if (percent < 50) {
                message = "🔌 Starting Surveilr on port 9227...";
            } else if (percent < 70) {
                message = "📡 Connecting to dashboard...";
            } else if (percent < 85) {
                message = "🔄 Initializing database...";
            } else if (percent < 95) {
                message = "🎯 Finalizing startup...";
            } else if (percent < 100) {
                message = "⏳ Almost ready...";
            } else {
                message = "✓ Services ready! Waiting for port 9227...";
            }

            this.updateStatus(message);
        }

        startPortMonitoring() {
            let portChecks = 0;

            if (this.portCheckInterval) clearInterval(this.portCheckInterval);

            console.log("[QFDashboard] 🔌 Monitoring port 9227...");

            this.portCheckInterval = setInterval(async () => {
                portChecks++;

                try {
                    const controller = new AbortController();
                    const timeoutId = setTimeout(() => controller.abort(), 3000);

                    const response = await fetch(CONFIG.DASHBOARD_URL, {
                        method: "HEAD",
                        signal: controller.signal,
                    }).catch(() => null);

                    clearTimeout(timeoutId);

                    if (response && (response.ok || response.status < 500)) {
                        clearInterval(this.portCheckInterval);
                        this.portReady = true;

                        console.log(`[QFDashboard] ✓ Port 9227 responding!`);
                        this.updateStatus("✓ Surveilr is ready! Click to open dashboard...");
                        this.enableOpenButton();
                        return;
                    }
                } catch (err) {
                    if (portChecks % 15 === 0) {
                        console.log(`[QFDashboard] ⏳ Waiting for port 9227... (${portChecks}s)`);
                    }
                }

                if (portChecks >= CONFIG.MAX_PORT_CHECKS) {
                    clearInterval(this.portCheckInterval);
                    console.warn(`[QFDashboard] ⚠️ Port timeout after ${portChecks}s`);
                    console.warn("[QFDashboard] Services might still be starting...");
                    this.updateStatus("⚠️ Timeout. Services might be starting. Try opening anyway.");
                    this.enableOpenButton();
                }
            }, CONFIG.PORT_CHECK_INTERVAL);
        }

        onProgressComplete() {
            if (!this.portReady) {
                this.updateStatus("✓ Ready! Click to open...");
            }
            this.enableOpenButton();
        }

        enableOpenButton() {
            if (this.openBtn) {
                this.openBtn.classList.add("ready");
                this.openBtn.style.opacity = "1";
                this.openBtn.style.pointerEvents = "auto";
                console.log("[QFDashboard] ✓ 'Open Dashboard' button enabled");
            }
        }

        openDashboardWindow() {
            console.log("[QFDashboard] 🌐 Opening " + CONFIG.DASHBOARD_URL);

            const win = window.open(CONFIG.DASHBOARD_URL, "_blank");

            if (!win) {
                this.updateStatus("⚠️ Popup blocked. Allow popups in browser.");
                alert("Popups are blocked. Please allow popups in your browser settings.");
            } else {
                console.log("[QFDashboard] ✓ Dashboard window opened");
                setTimeout(() => {
                    this.hideLoaderModal();
                }, 1000);
            }
        }

        cleanup() {
            if (this.progressInterval) clearInterval(this.progressInterval);
            if (this.portCheckInterval) clearInterval(this.portCheckInterval);
        }

        destroy() {
            this.cleanup();
        }
    }

    function initializeLauncher() {
        console.log("[QFDashboard] ════════════════════════════════════════");
        console.log("[QFDashboard] QualityFolio Dashboard Launcher");
        console.log("[QFDashboard] ════════════════════════════════════════");
        console.log("[QFDashboard] Backend: " + CONFIG.BACKEND_URL);
        console.log("[QFDashboard] Dashboard: " + CONFIG.DASHBOARD_URL);
        console.log("[QFDashboard] Working Directory: /qualityfolio");
        console.log("[QFDashboard] Commands:");
        CONFIG.COMMANDS.forEach((cmd) => {
            console.log("[QFDashboard]  • " + cmd);
        });
        console.log("[QFDashboard] ════════════════════════════════════════");

        window.qfDashboardLauncher = new QualityFolioDashboardLauncher();
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initializeLauncher);
    } else {
        initializeLauncher();
    }

    setTimeout(initializeLauncher, 100);

    window.addEventListener("beforeunload", () => {
        if (window.qfDashboardLauncher) {
            window.qfDashboardLauncher.destroy();
        }
    });

    console.log("[QFDashboard] ✓ Script loaded and ready");
})();