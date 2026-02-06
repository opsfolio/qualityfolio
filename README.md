<p align="center">
  <a href="https://qualityfolio.dev/">
    <img src="assets/qualityfolio-logo.png" alt="Qualityfolio" width="250">
  </a>
</p>

<p align="center">
  <a href="https://discord.gg/JqE86pyT"><img src="https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"></a>
  <a href="https://docs.opsfolio.com/qualityfolio/getting-started/quick-start"><img src="https://img.shields.io/badge/Docs-4285F4?style=for-the-badge&logo=googledocs&logoColor=white" alt="Docs"></a>
  <a href="https://qualityfolio.dev/"><img src="https://img.shields.io/badge/Website-06B6D4?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Website"></a>
</p>

[**Qualityfolio**](https://qualityfolio.dev/) is a flexible test authoring framework powered by **Spry's Axiom pattern**. Author plain, human-friendly Markdown for tests that can be parsed into any structure later. Start simple, scale infinitely.

## ✨ Why Qualityfolio?

- ✍️ **Write Naturally** - Use Markdown the way you already do
- 🎯 **Schema-Free** - No upfront structure required. Apply schemas at query time
- 📊 **Infinite Flexibility** - Scale from 2 to 6 heading levels as your project grows
- 🔄 **Git-First** - Version control your tests like code
- 🚀 **Auto-Discovery** - Let the parser figure out your structure, or define it yourself
- 📈 **Built-in Dashboard** - Generate test management dashboards with metrics & traceability

## 🔗 Works With Your Existing Workflow

**Qualityfolio doesn't replace your tools—it upgrades them.**

Qualityfolio is built to complement your existing test management, automation frameworks, and documentation systems. Write tests in Markdown, execute with your current tools, and capture evidence in structured SQL for audit-ready traceability.

### 💡 From Fragmented to Unified

**Instead of:**

- ❌ Tests scattered across multiple tools and formats
- ❌ Evidence lost in screenshots and spreadsheets
- ❌ Manual traceability matrices that break on every change
- ❌ No version history or accountability trail

**You get:**

- ✅ **Human-readable Markdown** - Version controlled, reviewable, and Git-native
- ✅ **Structured SQL evidence** - Queryable, immutable, and audit-ready
- ✅ **Automated traceability** - Requirements ↔ Tests ↔ Evidence ↔ Results
- ✅ **Evidence-grade accountability** - Complete history of who tested what, when, and why

> **Philosophy:** Quality is only provable when declared intent (tests) aligns with runtime reality (evidence). Qualityfolio enforces this rigorously.

---

## 🚀 Getting Started

**Simple rules:**

- Use headings to _suggest_ structure (none are required)
- Use GFM tasks (`- [ ]`, `- [ ]`) for steps and expectations
- Add metadata with `@key value` annotations or YAML/JSON blocks

**That's it.** The parser handles the rest.

### 🎯 What Do You Want To Do?

- **📖 [Learn the patterns](#-authoring-patterns)** - See examples from simple to complex
- **🚀 [Start building](#-getting-started)** - Generate your database & dashboard
- **📚 [See examples](#-example-files)** - View real test artifacts
- **🔧 [Get help](#-troubleshooting)** - Common issues & solutions

### 🌐 Try the Qualityfolio Demo

**[View Live Dashboard ](https://demo.qualityfolio.dev/)**

Explore a fully functional Qualityfolio dashboard with sample test artifacts, metrics, and traceability views.

## 🚀 Quick Start

### 💻 Prerequisites

Before you begin, ensure you have the following:

- **Runtime**: Deno 2.x or later (required)
- **Package Manager**: Homebrew (required)
- **Tools**: Spry, Surveilr (required)

### 🔧 Installation

#### 1. Install Dependencies

Ensure the following tools and files are available on your system:

1. **Deno** – runtime required by Spry
2. **Homebrew (brew)** – package manager for installing dependencies
3. **Spry** – runbook and SQLPage orchestration engine
4. **Surveilr** – ingestion and transformation engine
5. **Qualityfolio Extension** – Visual Studio Code Extension/Cursor IDE Extension which simplifies editing Evidence Block values

#### 2. Quick Install Commands

**For Linux:**

```bash
# 1. Install Deno
curl -fsSL https://deno.com/install.sh | sh

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install Spry
brew install programmablemd/packages/spry

# 4. Install Surveilr
wget https://github.com/surveilr/packages/releases/download/3.23.0/surveilr_3.23.0_x86_64-unknown-linux-gnu.tar.gz
tar -xzf surveilr_3.23.0_x86_64-unknown-linux-gnu.tar.gz
sudo mv surveilr /usr/local/bin/

```

**For macOS:**

```bash
# 1. Install Deno
curl -fsSL https://deno.com/install.sh | sh

# 2. Install Homebrew
curl -fsSL -o install.sh https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh

# 3. Install Spry
brew install programmablemd/packages/spry

# 4. Install Surveilr
brew tap surveilr/tap && brew install surveilr

```

#### 3. Install Qualityfolio Extension (for Visual Studio Code/Cursor IDE)

To install Qualityfolio extension, download and install the pre-packaged extension for Visual Studio Code or Cursor IDE.

> 💡 **Tip**: The Qualityfolio extension simplifies editing Evidence Block values directly within your IDE.

### 📝 Authoring Tests in Markdown

Qualityfolio tests follow a structured Markdown hierarchy to ensure full traceability and machine-readable execution. Qualityfolio projects can range from simple to highly complex structures.

An example test artifact file (`example-artifact.md`) for the project **OWASP - GLUE UP** (using Qualityfolio's Small pattern) demonstrates key concepts:

- **Header-based Classification** - Structured metadata for test organization
- **Hierarchical Test Design** - Nested test suites and cases
- **Evidence Block Patterns** - Linking test results with execution evidence

👉 **View the example**: [example-artifact.md](https://raw.githubusercontent.com/programmablemd/assurance-prime/refs/heads/main/support/assurance/qualityfolio/test-artifacts/example-artifact.md)

### 📊 Working with Qualityfolio

#### 1. Generate SQLite Database from Test Artifacts

1. Create test artifact files and store them in a folder (for example, `test-artifacts`).
2. Execute the following command in a terminal:

```bash
spry rb run qualityfolio.md
```

This command ingests the test artifact files and generates the SQLite database `resource-surveillance.sqlite.db`, which can be queried using any SQL editor.

#### 2. Generate Test Management Dashboard

1. After creating your test artifacts, execute the following commands:

```bash
spry rb run qualityfolio.md

spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md

EOH_INSTANCE=1 SQLPAGE_SITE_PREFIX=/netspective-qualityfolio PORT=9227 surveilr web-ui -d ./resource-surveillance.sqlite.db --port 9227 --host 0.0.0.0
```

This will launch the **Test Management Dashboard** with test metrics, requirement traceability matrix, and test cycle–wise execution views at:

```
http://localhost:9227/
```

### 🎯 Next Steps

Once your database and dashboard are running, you can:

- Query `resource-surveillance.sqlite.db` for custom analytics
- Extend SQLPage views by updating `qualityfolio.md`
- Add new test artifacts and execution evidence
- Integrate Qualityfolio into CI/CD pipelines

## 📖 Documentation

All documentation is in the [docs/](https://docs.opsfolio.com/qualityfolio/getting-started/quick-start) folder:

| Topic                                                                                              | Description       |
| -------------------------------------------------------------------------------------------------- | ----------------- |
| [Introduction](https://docs.opsfolio.com/qualityfolio/getting-started/introduction)                | Introduction      |
| [Download Operational Truth™](https://docs.opsfolio.com/qualityfolio/getting-started/installation) | Installation      |
| [Quick Start Guide](https://docs.opsfolio.com/qualityfolio/getting-started/quick-start)            | Quick Start Guide |

---

## 🎓 How It Works

### 🔄 The Axiom Pattern Philosophy

**Start simple. Scale infinitely.** Teams naturally grow in complexity over time, and **Spry's Axiom pattern** adapts to your needs without forcing you to rewrite anything.

> 💡 **Key Insight**: You write Markdown with headings at any depth (1-6 levels). The parser reads the structure, but _role names_ (like "project", "suite", "case") are only applied **at query time** based on your chosen schema.

#### 📊 Scaling Patterns

Choose the complexity level that matches your project's current needs:

| 🏷️ Scale                                                             | 📝 Heading Structure You Write                                                                                      | 🗂️ Query-Time Schema Mapping                                                                                                         |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **🌱 Small** <br/> _Perfect for simple projects or quick test plans_ | `# Project` <br/> `## Test Case` <br/> `### Evidence`                                                               | **3 Levels** <br/> H1 → `project` or `plan` <br/> H2 → `case` <br/> H3 → `evidence`                                                  |
| **📦 Medium** <br/> _Growing teams with test suites_                 | `# Project` <br/> `## Suite` <br/> `### Test Case` <br/> `#### Evidence`                                            | **4 Levels** <br/> H1 → `project` <br/> H2 → `suite` <br/> H3 → `case` <br/> H4 → `evidence`                                         |
| **🏢 Large** <br/> _Enterprise projects with multiple plans_         | `# Project` <br/> `## Plan` <br/> `### Suite` <br/> `#### Test Case` <br/> `##### Evidence`                         | **5 Levels** <br/> H1 → `project` <br/> H2 → `plan` <br/> H3 → `suite` <br/> H4 → `case` <br/> H5 → `evidence`                       |
| **🏗️ Complex** <br/> _Full organizational test strategies_           | `# Project` <br/> `## Strategy` <br/> `### Plan` <br/> `#### Suite` <br/> `##### Test Case` <br/> `###### Evidence` | **6 Levels** <br/> H1 → `project` <br/> H2 → `strategy` <br/> H3 → `plan` <br/> H4 → `suite` <br/> H5 → `case` <br/> H6 → `evidence` |

> ✨ **The Magic**: Start with 3 headings today. Add more levels tomorrow. Your existing Markdown stays valid. No refactoring needed.

## 📝 Authoring Patterns

Pick one to start, mix and match as you grow. All patterns work seamlessly together.

### 🌱 Pattern 1: Small (project/plan + cases + evidence)

````md
---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: case
  - select: heading[depth="3"]
    role: evidence
---

# <Your Project or Test Plan Title>

@id <optional-stable-id>

Context One or two sentences that explain scope.

## Reset password works

@id <test-case-id>

```yaml HFM
doc-classify:
requirementID: <requirement-id>
Tags: [tag 1, tag 2]
```

Short narrative of the scenario.

Steps

- [ ] Open "Forgot Password"
- [ ] Submit email
- [ ] Receive reset email
- [ ] Set a new password

Expected

- [ ] Confirmation screen
- [ ] Login with new password succeeds

### Evidence

@id <add an id to refer this evidence>

```yaml HFM
doc-classify:
cycle: <test-cycle-number>
assignee: Sarah Johnson
env: qa
status: passed
```

- [Run log](./evidence/TC-LOGIN-0001/1.1/run.auto.md)
- [Response JSON](./evidence/TC-LOGIN-0001/1.1/result.auto.json)
````

> Parse-time: 3 headings.
> Query-time: map `{ heading[depth="1"]: "project", heading[depth="2"]: "case", heading[depth="3"]: "evidence" }`.

### 📦 Pattern 2: Medium (project + suite → case + evidence)

```md
---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: suite
  - select: heading[depth="3"]
    role: case
  - select: heading[depth="4"]
    role: evidence
---

# <Your Project or Test Plan Title>

@id <optional-stable-id>

Context One or two sentences that explain scope.

## Authentication Suite

@id <test-suite-id>

Context One or two sentences that explain the test suite.

### Valid login

@id <test-case-id>

Steps

- [ ] Enter valid credentials
- [ ] Submit

Expected

- [ ] Redirect to dashboard

#### Evidence

- Screenshot
- Test execution result

### Logout vallidation

@id <test-case-id>

Steps

- [ ] Click profile menu
- [ ] Click "Sign out"

Expected

- [ ] Return to sign-in

#### Evidence

- Screenshot
- Test execution result
```

> Parse-time: 4 headings.
> Query-time mapping: `{ heading[depth="1"]: "project", heading[depth="2"]: "suite", heading[depth="3"]: "case", heading[depth="4"]: "evidence" }` or
> `{ heading[depth="1"]: "plan", heading[depth="2"]: "suite", heading[depth="3"]: "case", heading[depth="4"]: "evidence" }` - your choice.

### 🏢 Pattern 3: Large (project → plan → suite → case + evidence)

````md
---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: plan
  - select: heading[depth="3"]
    role: suite
  - select: heading[depth="4"]
    role: case
  - select: heading[depth="5"]
    role: evidence
---

# E2E Project Alpha

## Account Creation Plan

### Accounts & Auth Suite

@id acct-create-plan

```yaml
owner: riya@example.org
objective: Sign-up → login → profile bootstrap
```

#### New user can sign up and verify email

@id acct-signup-verify-case

Preconditions

- Mail sandbox configured in QA

Steps

- [ ] Open `/signup`
- [ ] Submit
- [ ] Receive verification email
- [ ] Click verification link
- [ ] Login

Expected

- [ ] User marked verified
- [ ] Login succeeds

##### Evidence

- [Run log](./evidence/TC-LOGIN-0001/1.1/run.auto.md)
- [Verification email JSON](./evidence/TC-LOGIN-0001/1.1/result.auto.json)
````

> Parse-time: 5 headings.
> Query-time mapping commonly used for this depth:
> `{ heading[depth="1"]: "project", heading[depth="2"]: "plan", heading[depth="3"]: "suite", heading[depth="4"]: "case", heading[depth="5"]: "evidence" }`.

### 🏗️ Pattern 4: Complex (project → strategy → plan → suite → case + evidence)

````md
---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: strategy
  - select: heading[depth="3"]
    role: plan
  - select: heading[depth="4"]
    role: suite
  - select: heading[depth="5"]
    role: case
  - select: heading[depth="6"]
    role: evidence
---

# E2E Project Alpha

## Project Strategy

### Account Creation Plan

@id acct-create-plan

```yaml
owner: riya@example.org
objective: Sign-up → login → profile bootstrap
```

#### Accounts & Auth Suite

##### New user can sign up and verify email

@id acct-signup-verify-case

Preconditions

- Mail sandbox configured in QA

Steps

- [ ] Open `/signup`
- [ ] Submit
- [ ] Receive verification email
- [ ] Click verification link
- [ ] Login

Expected

- [ ] User marked verified
- [ ] Login succeeds

###### Evidence

- [Run log](./evidence/TC-LOGIN-0001/1.1/run.auto.md)
- [Verification email JSON](./evidence/TC-LOGIN-0001/1.1/result.auto.json)
````

> Parse-time: 6 headings.
> Query-time mapping commonly used for this depth:
> `{ heading[depth="1"]: "project", heading[depth="2"]: "strategy", heading[depth="3"]: "plan", heading[depth="4"]: "suite", heading[depth="5"]: "case", heading[depth="6"]: "evidence" }`.

## 🏷️ Metadata: Annotations & Code Blocks

- Annotations: any line like `@key value` in a heading’s _own section_ (before child headings).
- Fenced code blocks: use `yaml`, `json`, or `json5` for structured metadata;
  captured with line numbers.

Examples:

````md
@id acct-lockout-case @severity critical @component auth

```yaml
owner: riya@example.org
env: qa
objective: Lockout policy & reset email
```
````

> Annotations do not inherit to children - add where you want them to apply.

## ✅ Steps & Expectations (GFM Tasks)

Use checkboxes to make steps and expected results machine-readable:

```md
Steps

- [ ] Navigate to `/login`
- [ ] Enter valid credentials
- [ ] Provide MFA code
- [ ] Redirect to `/home`

Expected

- [ ] Session cookie set
- [ ] CSRF token present
- [ ] Home shows display name
```

> Spry's Axiom pattern extracts each item with `checked` state, the text, and precise line numbers.

## 📄 Frontmatter (Optional)

If you like, top-of-file frontmatter is parsed:

```md
---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: strategy
  - select: heading[depth="3"]
    role: plan
  - select: heading[depth="4"]
    role: suite
  - select: heading[depth="5"]
    role: case
  - select: heading[depth="6"]
    role: evidence
---
```

## 📁 File & Folder Naming

**Recommended conventions** (not required - use what fits your team):

- Use lowercase with hyphens: `account-creation-plan.md`, `mobile-auth-login.case.md`.
- Keep evidence near the doc for easy links: `./evidence/...`.
- Typical repo layout (optional; use what fits your team):

```
qualifyfolio/
├── support/
│   └── assurance/
│       └── qualityfolio/
│           ├── evidence/
│           │   ├── TC-GLUE-001/
│           │   │   └── 1.1/
│           │   │       ├── result.auto.json
│           │   │       └── run.auto.md
│           │   └── TC-GLUE-002/
│           │       └── 1.1/
│           │           ├── loginButtonClick.png
│           │           ├── result.auto.json
│           │           └── run.auto.md
│           ├── sqlpage/
│           │   └── sqlpage.json                  # runtime configuration file for SQLPage
│           ├── test-artifacts/
│           │   └── example-artifact.md           # example test artifact
│           ├── qualityfolio-json-etl.sql         # SQL ETL script for Qualityfolio data
│           ├── qualityfolio.md                   # SQLPage Markdown page (DB config + queries)
│           └── resource-surveillance.sqlite.db   # Database generated

```

> Remember: the parser does not require any folder layout. This is just for DX.

## 📚 Example Files

👉 **See it in action:** [View example test artifacts](https://github.com/opsfolio/qualityfolio/tree/main/support/assurance/qualityfolio/test-artifacts)

## ✅ Authoring Checklist

- Use whatever heading depth you need up to 6th level (none are required).
- Prefer GFM tasks for steps & expected results.
- Add `@id`, `@severity`, `@component`, etc. where useful.
- Use fenced YAML/JSON for richer metadata.
- Link evidence files close to the doc.
- Let schemas or discovery decide roles later.

## ✅ Troubleshooting

- “My evidence isn’t detected” → an evidence must be a leaf heading (no deeper headings beneath it).
- “My annotations don’t show up” → ensure `@key value` is not inside a code block and is in the heading’s own section.
- “Discovery chose odd roles” → either add minimal content to meaningful ancestors (so they’re “significant”) or apply an explicit schema when querying.

## 📜 License

Your docs are yours. **Spry's Axiom pattern** is designed to read Markdown respectfully and safely.

---

**Made with 💜 for developers who love writing tests in Markdown.**
