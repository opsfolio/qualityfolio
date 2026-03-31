console.log("AI Refine: Script initialized v2.1-POST-FIX");

// AI Refinement logic
window.refineRequirements = function (targetTextarea) {
  console.log("AI Refine: Function triggered");
  // Support passing specific textarea, or auto-detect
  const textarea =
    targetTextarea ||
    document.querySelector('textarea[name="requirement_text"]') ||
    document.getElementById("requirement_text") ||
    document.querySelector('textarea[name="description"]') ||
    document.querySelector("textarea");

  if (!textarea) {
    console.error("AI Refine: Textarea not found!");
    alert("Error: Could not find the Requirement Details box.");
    return;
  }

  const val = textarea.value.trim();
  if (!val) {
    alert("Please enter some initial requirements (e.g., 'User Login') first.");
    return;
  }

  // AI Logic - Call Backend
  const btn = document.getElementById("ai-refine-btn");
  let originalContent = "";

  if (btn) {
    originalContent = btn.innerHTML;
    btn.innerHTML = '<i class="ti ti-loader spin"></i> Refining...';
    btn.disabled = true;
  }

  const formData = new FormData();
  formData.append("requirement_text", val);

  console.log(
    "AI Refine: Requesting api/ai_refine.sql via POST with text length:",
    val.length,
  );

  fetch("/api/ai_refine.sql", {
    method: "POST",
    body: formData,
  })
    .then(async (response) => {
      console.log("AI Refine: Response Status:", response.status);
      const text = await response.text();
      console.log("AI Refine: Response Text:", text);

      try {
        return JSON.parse(text);
      } catch (e) {
        console.error("AI Refine: JSON Parse Error", e);
        throw new Error(
          "Invalid JSON response from server: " + text.substring(0, 100),
        );
      }
    })
    .then((data) => {
      console.log("AI Refine: Raw Data received:", data);

      // Handle SQLPage array wrapper
      if (Array.isArray(data)) {
        // Look for the object that has 'contents' which might contain our data,
        // OR look for an object that directly has 'refined_text' if SQLPage returned a flat list of components?
        // Actually SQLPage returns [ {"component":"json", "contents": { "success": 1, "refined_text": "..." } } ]

        const jsonComponent = data.find(
          (item) => item.contents && item.contents.refined_text !== undefined,
        );
        if (jsonComponent) {
          data = jsonComponent.contents;
        } else {
          // Fallback: maybe it's the first item's contents?
          if (data.length > 0 && data[0].contents) {
            data = data[0].contents;
          }
        }
      }

      console.log("AI Refine: Processed Data:", data);

      if (data && data.success && data.refined_text) {
        textarea.value = data.refined_text;
        // Trigger input event
        textarea.dispatchEvent(new Event("input", { bubbles: true }));

        if (btn) {
          btn.innerHTML = "✨ Done!";
          btn.classList.add("bg-success", "text-white");
          setTimeout(() => {
            btn.innerHTML = originalContent;
            btn.classList.remove("bg-success", "text-white");
            btn.disabled = false;
          }, 2000);
        }
      } else {
        console.error("AI Refine: Success flag false or no text", data);
        // Extract error message if present
        let errorMsg = "Unknown server error";
        if (data && data.refined_text) errorMsg = data.refined_text;

        alert("Error refining text: " + errorMsg);
        if (btn) {
          btn.innerHTML = originalContent;
          btn.disabled = false;
        }
      }
    })
    .catch((error) => {
      console.error("AI Refine Catch Error:", error);
      alert("Error communicating with AI service: " + error.message);
      if (btn) {
        btn.innerHTML = originalContent;
        btn.disabled = false;
      }
    });
};

// --- Improved Injection Logic using MutationObserver ---
function injectRefineButton() {
  // Target: requirement_text OR description (Requirements field in test case form)
  const candidates = [
    { selector: 'textarea[name="requirement_text"]', btnId: "ai-refine-btn" },
    { selector: 'textarea[name="description"]', btnId: "ai-refine-btn-desc" },
  ];

  candidates.forEach(({ selector, btnId }) => {
    const textarea = document.querySelector(selector);
    if (!textarea) return;
    if (document.getElementById(btnId)) return;

    console.log("AI Refine: Found", selector, "— injecting button...");

    let label = textarea.closest(".mb-3, .form-group")?.querySelector("label");

    if (label) {
      label.style.display = "flex";
      label.style.justifyContent = "space-between";
      label.style.alignItems = "center";
      label.style.width = "100%";
      label.style.gap = "10px";

      const btn = document.createElement("button");
      btn.id = btnId;
      btn.type = "button";
      btn.className = "btn btn-sm btn-primary d-flex align-items-center gap-1";
      btn.style.cssText =
        "padding: 2px 12px; font-size: 0.75rem; border-radius: 12px; font-weight: 500; border: none; white-space: nowrap;";
      btn.innerHTML = '<i class="ti ti-wand"></i> AI Refine';
      btn.onclick = (e) => {
        e.preventDefault();
        window.refineRequirements(textarea);
      };
      label.appendChild(btn);
      console.log("AI Refine: Button injected for", selector);
    } else {
      const btn = document.createElement("button");
      btn.id = btnId;
      btn.type = "button";
      btn.className = "btn btn-sm btn-primary mb-2";
      btn.style.cssText =
        "float: right; border-radius: 12px; font-size: 0.75rem;";
      btn.innerHTML = '<i class="ti ti-wand"></i> AI Refine';
      btn.onclick = (e) => {
        e.preventDefault();
        window.refineRequirements(textarea);
      };
      textarea.parentNode.insertBefore(btn, textarea);
    }
  });
}

// Initial check
injectRefineButton();

// Use MutationObserver to handle dynamic content or slow loading
const observer = new MutationObserver(() => {
  injectRefineButton();
});

observer.observe(document.body, { childList: true, subtree: true });

// Also try on load just in case
window.addEventListener("load", injectRefineButton);

// --- PLAN SCOPE GENERATION LOGIC ---

window.generatePlanScope = function () {
  console.log("AI Plan Scope: Function triggered");

  // Find Plan Scope Textarea
  const planScopeTextarea = document.querySelector(
    'textarea[name="plan_scope"]',
  );
  if (!planScopeTextarea) {
    console.error("AI Plan Scope: Plan Scope textarea not found!");
    return;
  }

  // Find Requirement Details (Source)
  // Support both textarea (Generator) and hidden input (Plans)
  let reqSource =
    document.querySelector('[name="requirement_text"]') ||
    document.getElementById("requirement_text");

  const val = reqSource ? reqSource.value.trim() : "";

  if (!val) {
    alert(
      "Please enter some Requirement Details first to generate a Plan Scope.\n(If this is a new plan, ensure the project has requirements saved.)",
    );
    return;
  }

  const btn = document.getElementById("ai-plan-scope-btn");
  let originalContent = "";

  if (btn) {
    originalContent = btn.innerHTML;
    btn.innerHTML = '<i class="ti ti-loader spin"></i> Generating...';
    btn.disabled = true;
  }

  const formData = new FormData();
  formData.append("requirement_text", val);

  console.log("AI Plan Scope: Requesting api/ai_plan_scope.sql...");

  fetch("/api/ai_plan_scope.sql", {
    method: "POST",
    body: formData,
  })
    .then(async (response) => {
      const text = await response.text();
      try {
        return JSON.parse(text);
      } catch (e) {
        console.error("AI Plan Scope: JSON Parse Error", e);
        throw new Error("Invalid JSON response: " + text.substring(0, 100));
      }
    })
    .then((data) => {
      console.log("AI Plan Scope: Data received:", data);

      // Handle SQLPage array wrapper
      if (Array.isArray(data)) {
        const jsonComponent = data.find(
          (item) => item.contents && item.contents.refined_text !== undefined,
        );
        if (jsonComponent) {
          data = jsonComponent.contents;
        } else if (data.length > 0 && data[0].contents) {
          data = data[0].contents;
        }
      }

      if (data && data.success && data.refined_text) {
        planScopeTextarea.value = data.refined_text;
        planScopeTextarea.dispatchEvent(new Event("input", { bubbles: true }));

        if (btn) {
          btn.innerHTML = "✨ Done!";
          btn.classList.add("bg-success", "text-white");
          setTimeout(() => {
            btn.innerHTML = originalContent;
            btn.classList.remove("bg-success", "text-white");
            btn.disabled = false;
          }, 2000);
        }
      } else {
        alert(
          "Error generating scope: " + (data.refined_text || "Unknown error"),
        );
        if (btn) {
          btn.innerHTML = originalContent;
          btn.disabled = false;
        }
      }
    })
    .catch((error) => {
      console.error("AI Plan Scope Error:", error);
      alert("Error: " + error.message);
      if (btn) {
        btn.innerHTML = originalContent;
        btn.disabled = false;
      }
    });
};

function injectPlanScopeButton() {
  const textarea = document.querySelector('textarea[name="plan_scope"]');
  if (!textarea) return;

  if (document.getElementById("ai-plan-scope-btn")) return;

  console.log("AI Plan Scope: Found textarea, injecting button...");

  // Find label
  let label = document.querySelector('label[for="plan_scope"]');
  if (!label) {
    // Try finding label within same container
    const container =
      textarea.closest(".mb-3") || textarea.closest(".form-group");
    if (container) label = container.querySelector("label");
  }

  if (label) {
    // Flex style
    label.style.display = "flex";
    label.style.justifyContent = "space-between";
    label.style.alignItems = "center";
    label.style.width = "100%";

    const btn = document.createElement("button");
    btn.id = "ai-plan-scope-btn";
    btn.type = "button";
    btn.className = "btn btn-sm btn-info d-flex align-items-center gap-1";
    btn.style.cssText =
      "padding: 2px 12px; font-size: 0.75rem; border-radius: 12px; font-weight: 500; border: none; white-space: nowrap; color: white;";
    btn.innerHTML = '<i class="ti ti-wand"></i> AI Generate Scope';
    btn.onclick = (e) => {
      e.preventDefault();
      window.generatePlanScope();
    };

    label.appendChild(btn);
  } else {
    // Fallback
    const btn = document.createElement("button");
    btn.id = "ai-plan-scope-btn";
    btn.type = "button";
    btn.className = "btn btn-sm btn-info mb-2";
    btn.style.cssText =
      "float: right; border-radius: 12px; font-size: 0.75rem; color: white;";
    btn.innerHTML = '<i class="ti ti-wand"></i> AI Generate Scope';
    btn.onclick = (e) => {
      e.preventDefault();
      window.generatePlanScope();
    };
    textarea.parentNode.insertBefore(btn, textarea);
  }
}

// Observe for Plan Scope field
const planObserver = new MutationObserver((mutations) => {
  injectPlanScopeButton();
});
planObserver.observe(document.body, { childList: true, subtree: true });
window.addEventListener("load", injectPlanScopeButton);
