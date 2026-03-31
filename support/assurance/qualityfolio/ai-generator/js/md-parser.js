// ===== Markdown Parser for QualityFolio =====
// Reverses generic markdown generation to structured JSON

class MDParser {
  constructor() {
    this.schemaLevel = "5"; // Default
    this.lines = [];
    this.currentIndex = 0;
    this.structure = {
      projectName: "Imported Project",
      testCasePrefix: "TC",
      requirementPrefix: "REQ",
      cycle: "1.0",
      cycleDate: new Date().toISOString().split("T")[0],
      schemaLevel: "5",
      plans: [],
    };
  }

  parse(markdownText) {
    this.lines = markdownText.split("\n");
    this.currentIndex = 0;

    // 1. Parse Frontmatter to determine Schema
    this.parseFrontmatter();

    // 2. Parse Content
    this.parseBody();

    return this.structure;
  }

  parseFrontmatter() {
    let inFM = false;
    let fmBuffer = [];

    // Check first line
    if (this.lines[0].trim() === "---") {
      inFM = true;
      this.currentIndex++;
    }

    while (this.currentIndex < this.lines.length) {
      const line = this.lines[this.currentIndex];
      if (line.trim() === "---") {
        this.currentIndex++;
        break;
      }
      if (inFM) fmBuffer.push(line);
      this.currentIndex++;
    }

    const fmText = fmBuffer.join("\n");

    // Auto-detect Schema Level based on header depths
    const headers = this.lines
      .map((l, idx) => ({ t: l.trim(), idx }))
      .filter((h) => h.t.startsWith("#"));

    const depths = headers.map((h) => h.t.match(/^#+/)[0].length);
    const maxDepth = depths.length > 0 ? Math.max(...depths) : 1;

    // Mapping:
    // Level 5 (Project->Plan->Suite->Case->Ev) => Max Depth 5 or 6
    // Level 4 (Project->Suite->Case->Ev)      => Max Depth 4
    // Level 3 (Project->Case->Ev)            => Max Depth 3
    if (maxDepth >= 5) {
      this.structure.schemaLevel = "5";
    } else if (maxDepth === 4) {
      this.structure.schemaLevel = "4";
    } else if (maxDepth === 3) {
      this.structure.schemaLevel = "3";
    } else {
      this.structure.schemaLevel = "5"; // Default fallback
    }

    // Overwrite if frontmatter specifies it
    if (fmText.includes("role: plan") || fmText.includes("schema: 5")) {
      this.structure.schemaLevel = "5";
    } else if (fmText.includes("role: suite") || fmText.includes("schema: 4")) {
      this.structure.schemaLevel = "4";
    } else if (fmText.includes("role: case") || fmText.includes("schema: 3")) {
      this.structure.schemaLevel = "3";
    }
  }

  parseBody() {
    let currentPlan = null;
    let currentSuite = null;
    let currentCase = null;

    // Normalization helpers
    const ensurePlan = () => {
      if (!currentPlan) {
        currentPlan = { planName: "Imported Plan", suites: [] };
        this.structure.plans.push(currentPlan);
      }
      return currentPlan;
    };
    const ensureSuite = () => {
      const p = ensurePlan();
      if (!currentSuite) {
        currentSuite = { suiteName: "Imported Suite", testCases: [] };
        p.suites.push(currentSuite);
      }
      return currentSuite;
    };

    while (this.currentIndex < this.lines.length) {
      const line = this.lines[this.currentIndex];
      const trimmed = line.trim();

      if (trimmed.startsWith("#")) {
        // It's a header
        const level = trimmed.match(/^#+/)[0].length;
        const title = trimmed.replace(/^#+\s*/, "");

        // Determine Role based on Schema and Level
        const role = this.getRoleForHeader(level);

        if (role === "project") {
          this.structure.projectName = title;
          this.parseProjectDetails();
        } else if (role === "plan") {
          currentPlan = {
            planName: title,
            suites: [],
            ...this.parseMetadataBlock(),
          };
          // Check for YAML
          const yamlData = this.parseYamlBlockRaw();
          if (yamlData) currentPlan.yamlMetadata = yamlData;

          currentPlan.description = this.parseBlockContent(); // Capture text body
          this.structure.plans.push(currentPlan);
          currentSuite = null;
          currentCase = null;
        } else if (role === "suite") {
          const p = ensurePlan();
          currentSuite = {
            suiteName: title,
            testCases: [],
            ...this.parseMetadataBlock(),
          };
          // Check for YAML
          const yamlData = this.parseYamlBlockRaw();
          if (yamlData) currentSuite.yamlMetadata = yamlData;

          currentSuite.description = this.parseBlockContent(); // Capture text body
          p.suites.push(currentSuite);
          currentCase = null;
        } else if (role === "case") {
          const s = ensureSuite();
          currentCase = {
            title: title,
            steps: [],
            tags: [],
            evidenceHistory: [],
            ...this.parseCommonParams(),
          };
          // Parse YAML HFM for specific fields
          const yamlData = this.parseYamlBlock();
          if (yamlData) {
            // Store raw YAML to preserve custom fields during regeneration
            currentCase.yamlMetadata = { ...yamlData };

            currentCase.priority = yamlData.Priority || "Medium";
            currentCase.scenarioType =
              yamlData["Scenario Type"] || "Happy Path";
            currentCase.executionType = yamlData["Execution Type"] || "Manual";
            currentCase.requirementId = yamlData.requirementID || ""; // Capture Req ID
            try {
              currentCase.tags =
                typeof yamlData.Tags === "string"
                  ? JSON.parse(yamlData.Tags)
                  : yamlData.Tags;
            } catch (e) {
              currentCase.tags = [];
            }
          }

          this.parseTestCaseBody(currentCase);
          s.testCases.push(currentCase);
        } else if (role === "evidence") {
          // Evidence is attached to current case
          if (currentCase) {
            const evData = this.parseYamlBlock();
            if (evData) {
              // Normalize Date (DD-MM-YYYY to YYYY-MM-DD)
              let eDate =
                evData["cycle-date"] ||
                evData.date ||
                new Date().toISOString().split("T")[0];
              if (eDate.match(/^\d{2}-\d{2}-\d{4}$/)) {
                const [d, m, y] = eDate.split("-");
                eDate = `${y}-${m}-${d}`;
              }

              // Normalize Status (Title Case)
              let eStatus = evData.status || "To-do";
              eStatus =
                eStatus.charAt(0).toUpperCase() +
                eStatus.slice(1).toLowerCase();

              currentCase.evidenceHistory.push({
                cycle: evData.cycle || "1.0",
                cycleDate: eDate,
                status: eStatus,
                assignee: evData.assignee || "Unassigned",
              });
            }
          }
        }
      }

      this.currentIndex++;
    }
  }

  getRoleForHeader(depth) {
    if (depth === 1) return "project";
    const s = this.structure.schemaLevel;

    if (s === "3") {
      if (depth === 2) return "case";
      if (depth === 3) return "evidence";
    } else if (s === "4") {
      if (depth === 2) return "suite";
      if (depth === 3) return "case";
      if (depth === 4) return "evidence";
    } else {
      if (depth === 2) return "plan";
      if (depth === 3) return "suite";
      if (depth === 4) return "case";
      if (depth === 5) return "evidence";
    }
    return "unknown";
  }

  parseMetadataBlock() {
    // Look ahead for @id
    let meta = {};
    let i = this.currentIndex + 1;
    while (i < this.lines.length) {
      const l = this.lines[i].trim();
      if (l.startsWith("#")) break; // Stop at next header

      if (l.startsWith("@id")) {
        meta.id = l.replace("@id", "").trim();
      }
      i++;
    }
    return meta;
  }

  parseProjectDetails() {
    // Look for details and content
    let buffer = [];
    let i = this.currentIndex + 1;
    while (i < this.lines.length && !this.lines[i].startsWith("##")) {
      const line = this.lines[i];
      const trimmed = line.trim();

      // Extract Project ID if present
      if (trimmed.startsWith("@id")) {
        this.structure.id = trimmed.replace("@id", "").trim();
      } else {
        buffer.push(line);
      }
      i++;
    }
    const fullText = buffer.join("\n").trim();
    this.structure.description = fullText;
  }

  parseCommonParams() {
    // Look ahead for Description, Preconditions, etc.
    // Actually, parseTestCaseBody does this better
    return {};
  }

  parseYamlBlockRaw() {
    let yamlStart = -1;
    let yamlEnd = -1;

    // Scan until next header
    for (let i = this.currentIndex + 1; i < this.lines.length; i++) {
      const trimmed = this.lines[i].trim();
      if (trimmed.startsWith("#")) break;

      if (
        yamlStart === -1 &&
        (trimmed.match(/^```yaml/i) || trimmed.match(/^```yml/i))
      ) {
        yamlStart = i;
      } else if (yamlStart > -1 && trimmed.startsWith("```")) {
        yamlEnd = i;
        break;
      }
    }

    if (yamlStart > -1 && yamlEnd > -1) {
      const block = this.lines.slice(yamlStart + 1, yamlEnd);
      return block.join("\n");
    }
    return null;
  }

  parseYamlBlock() {
    let yamlStart = -1;
    let yamlEnd = -1;

    // Scan until next header
    for (let i = this.currentIndex + 1; i < this.lines.length; i++) {
      const trimmed = this.lines[i].trim();
      if (trimmed.startsWith("#")) break;

      if (
        yamlStart === -1 &&
        (trimmed.match(/^```yaml/i) || trimmed.match(/^```yml/i))
      ) {
        yamlStart = i;
      } else if (yamlStart > -1 && trimmed.startsWith("```")) {
        yamlEnd = i;
        break;
      }
    }

    if (yamlStart > -1 && yamlEnd > -1) {
      const block = this.lines.slice(yamlStart + 1, yamlEnd);
      const data = {};
      block.forEach((l) => {
        const parts = l.split(":");
        if (parts.length >= 2) {
          const key = parts[0].trim();
          const val = parts.slice(1).join(":").trim();
          data[key] = val.replace(/^"|"$/g, ""); // strip quotes
        }
      });
      return data;
    }
    return null;
  }

  parseTestCaseBody(tcObj) {
    // Scan forward until next header
    let mode = "desc";
    let descBuffer = [];
    let inCodeBlock = false;

    for (let i = this.currentIndex + 1; i < this.lines.length; i++) {
      const line = this.lines[i];

      // If we hit a header and we are NOT in a code block, break
      if (line.startsWith("#") && !inCodeBlock) break;

      const trim = line.trim();

      // Handle Code Block Toggle
      if (trim.startsWith("```")) {
        inCodeBlock = !inCodeBlock;
        continue; // Skip the fence line itself from description
      }

      if (inCodeBlock) {
        // If we are in specific modes like 'steps' or 'exp', we might want to capture code?
        // For now, let's assume Description can contain code blocks, but we want to skip METADATA blocks.
        // If the block started with ```yaml HFM, we initiated it.
        // But parseYamlBlock scans ahead independently.
        // The issue is that parseTestCaseBody iterates linearly.
        // If we are inside the Metadata YAML block, we should SKIP it from Description.
        // We can't easily distinguish "Metadata YAML" from "Description Code Block" here without context.
        // HEURISTIC: If the block content looks like metadata (requirementID, Priority), skip it.
        // simpler: The user's metadata block starts with ```yaml HFM.
        // Let's assume all YAML HFM blocks are metadata and should be skipped.
        // But wait, line.startsWith('```') is just the fence.
        // We need to know if the *opening* fence was metadata.
        // This is getting complicated.
        // Simpler approach: Just skip the lines if they match known metadata keys? No.

        // Better approach: parseYamlBlock already extracted it.
        // Check if this block is the metadata block?
        // For now, let's just NOT add to descBuffer if it looks like the metadata block.
        // Actually, the previous issue was that 'requirementID: ...' was added.
        // If we just skip ALL code blocks from description for now?
        // No, user might want code in description.

        // Let's rely on the tag.
        // If the line that started the block was ```yaml HFM, then skip content.
        // But we lost that context.

        // Let's just track if the block is "HFM Metadata".
        continue;
      }

      // Robust ID parsing
      if (trim.match(/^@id/i)) {
        tcObj.testCaseId = trim.replace(/^@id/i, "").trim();
        continue;
      }

      if (trim === "**Description**") {
        mode = "desc";
        continue;
      }
      if (trim === "**Preconditions**") {
        mode = "pre";
        tcObj.preconditions = [];
        continue;
      }
      if (trim === "**Steps**") {
        mode = "steps";
        tcObj.steps = [];
        continue;
      }
      if (trim === "**Expected Results**") {
        mode = "exp";
        continue;
      }
      if (trim === "---") continue;

      if (mode === "desc") {
        if (trim.length > 0 && !trim.startsWith("@id")) {
          descBuffer.push(trim);
        }
      } else if (mode === "pre") {
        if (trim.match(/^\[x\]/i)) {
          tcObj.preconditions.push(trim.substring(3).trim());
        } else if (trim.match(/^[-*]\s*\[x\]/i)) {
          tcObj.preconditions.push(trim.replace(/^[-*]\s*\[x\]\s*/i, ""));
        } else if (trim.startsWith("- ")) {
          tcObj.preconditions.push(trim.substring(2).trim());
        }
      } else if (mode === "steps") {
        // Regex for various step formats:
        let stepText = "";
        if (trim.match(/^(\d+\.|[-*])\s*\[x\]\s*/i)) {
          stepText = trim.replace(/^(\d+\.|[-*])\s*\[x\]\s*/i, "");
        } else if (trim.match(/^\[x\]\s*/i)) {
          stepText = trim.replace(/^\[x\]\s*/i, "");
        } else if (trim.match(/^(\d+\.|[-*])\s+/)) {
          stepText = trim.replace(/^(\d+\.|[-*])\s+/, "");
        }

        if (stepText) {
          tcObj.steps.push(stepText);
        }
      } else if (mode === "exp") {
        // Accumulate expected results
        let expText = "";
        if (trim.match(/^(\d+\.|[-*])\s*\[x\]\s*/i)) {
          expText = trim.replace(/^(\d+\.|[-*])\s*\[x\]\s*/i, "");
        } else if (trim.match(/^\[x\]\s*/i)) {
          expText = trim.replace(/^\[x\]\s*/i, "");
        } else if (trim.match(/^(\d+\.|[-*])\s+/)) {
          expText = trim.replace(/^(\d+\.|[-*])\s+/, "");
        } else if (trim.length > 0) {
          expText = trim; // Plain text line
        }

        if (expText) {
          // Accumulate with newline
          tcObj.expectedResult = tcObj.expectedResult
            ? tcObj.expectedResult + "\n" + expText
            : expText;
        }
      }
    }

    tcObj.description = descBuffer.join("\n").trim();
  }
  parseBlockContent() {
    let buffer = [];
    let i = this.currentIndex + 1;
    let inCodeBlock = false;

    while (i < this.lines.length) {
      const line = this.lines[i];
      const trimmed = line.trim();

      if (trimmed.startsWith("#")) break;
      if (trimmed === "---") {
        i++;
        continue;
      }

      if (trimmed.startsWith("```")) {
        inCodeBlock = !inCodeBlock;
        i++;
        continue;
      }

      if (inCodeBlock) {
        i++;
        continue;
      }

      const isMeta =
        trimmed.startsWith("@id") || trimmed.startsWith("doc-classify:");

      if (!isMeta) {
        buffer.push(line);
      }

      i++;
    }

    while (buffer.length > 0 && buffer[0].trim() === "") buffer.shift();
    while (buffer.length > 0 && buffer[buffer.length - 1].trim() === "")
      buffer.pop();

    return buffer.join("\n");
  }
}

// Global Parser Function
window.parseMarkdownToJSON = function (text) {
  const parser = new MDParser();
  return parser.parse(text);
};
