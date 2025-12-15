# Qualityfolio.md - Flexible Authoring Guide (works with Spry's Axiom pattern)

> Goal: Author plain, human-friendly Markdown for tests that can be parsed into
> structure later.\
> Principle: All headings are optional - use as few or as many levels as you
> need. The parser (**Spry's Axiom pattern**) is schema-free at parse time and schema-driven
> at query time.

## Quick Summary

- Write Markdown the way you naturally would.
- Use headings to _suggest_ structure, but none are required.
- Use simple annotations (`@key value`) and fenced code blocks (YAML/JSON) for
  metadata anywhere.
- Use GFM tasks (`- [ ]`, `- [x]`) for steps and expectations.
- When querying/visualizing, apply a schema mapping depth→role (e.g.,
  `{ heading[depth="1"]: "project", heading[depth="2"]: "strategy", heading[depth="3"]: "plan", heading[depth="4"]: "suite", heading[depth="5"]: "case", heading[depth="6"]: "evidence" }`) or auto-discover it.

## Why headings are optional

Teams start simple and grow complexity over time. **Spry's Axiom pattern** supports all of
these equally:

| Project size | Typical content you write                                   | Example mapping (later at query time)                                    |
| ------------ | ----------------------------------------------------------- | ------------------------------------------------------------------------ |
| Small        | project or plan → case (+ steps) → evidence                 | `{ heading[depth="1"]: "project", heading[depth="2"]: "case", heading[depth="3"]: "evidence" }` or `{ heading[depth="1"]: "plan", heading[depth="2"]: "case", heading[depth="3"]: "evidence" }`            |
| Medium       | project → suite → case (+ steps) → evidence             | `{ heading[depth="1"]: "project", heading[depth="2"]: "suite", heading[depth="3"]: "case", heading[depth="4"]: "evidence" }`                 |
| Large        | project → plan → suite → case (+ steps) → evidence  | `{ heading[depth="1"]: "project", heading[depth="2"]: "plan", heading[depth="3"]: "suite", heading[depth="4"]: "case", heading[depth="5"]: "evidence" }` |
| Complex      | project → strategy → plan → suite → case (+ steps) → evidence | `{ heading[depth="1"]: "project", heading[depth="2"]: "strategy", heading[depth="3"]: "plan", heading[depth="4"]: "suite", heading[depth="5"]: "case", heading[depth="6"]: "evidence" }` |

> You decide the depth; **Spry's Axiom pattern** will parse headings, but role names are only
> applied later.

## Authoring patterns (pick one, mix & match later)

### 1) Small (project/ plan + cases + evidence)

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
- [x] Receive reset email
- [ ] Set a new password

Expected

- [x] Confirmation screen
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

- [Run log](./evidence/run-2025-11-01.md)
- [Response JSON](./evidence/resp-2025-11-01.json)

````

> Parse-time: 3 headings. 
>Query-time: map `{ heading[depth="1"]: "project", heading[depth="2"]: "case", heading[depth="3"]: "evidence" }`.

### 2) Medium (project + suite → case + evidence)

````md
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
- [x] Submit

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
````

> Query-time mapping: `{ heading[depth="1"]: "project", heading[depth="2"]: "suite", heading[depth="3"]: "case", heading[depth="4"]: "evidence" }` or
> `{ heading[depth="1"]: "plan", heading[depth="2"]: "suite", heading[depth="3"]: "case", heading[depth="4"]: "evidence" }` - your choice.

### 3) Large (project → plan → suite → case + evidence)

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

- [x] Open `/signup`
- [x] Submit
- [x] Receive verification email
- [x] Click verification link
- [x] Login

Expected

- [x] User marked verified
- [x] Login succeeds

##### Evidence

- [Run log](./evidence/signup-run.md)
- [Verification email JSON](./evidence/signup-email.json)
````

> Query-time mapping commonly used for this depth:
> `{ heading[depth="1"]: "project", heading[depth="2"]: "plan", heading[depth="3"]: "suite", heading[depth="4"]: "case", heading[depth="5"]: "evidence" }`.

### 4) Complex (project → strategy → plan → suite → case + evidence)

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

- [x] Open `/signup`
- [x] Submit
- [x] Receive verification email
- [x] Click verification link
- [x] Login

Expected

- [x] User marked verified
- [x] Login succeeds

###### Evidence

- [Run log](./evidence/signup-run.md)
- [Verification email JSON](./evidence/signup-email.json)
````

> Query-time mapping commonly used for this depth:
> `{ heading[depth="1"]: "project", heading[depth="2"]: "strategy", heading[depth="3"]: "plan", heading[depth="4"]: "suite", heading[depth="5"]: "case", heading[depth="6"]: "evidence" }`.

## Metadata: annotations & code blocks

- Annotations: any line like `@key value` in a heading’s _own section_ (before
  child headings).
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

```json5
{
  notes: "Payment sandbox intermittently 502s",
  linked_issues: ["CHECKOUT-231"]
}
```

> Annotations do not inherit to children - add where you want them to apply.

## Steps & expectations (GFM tasks)

Use checkboxes to make steps and expected results machine-readable:

```md
Steps

- [x] Navigate to `/login`
- [x] Enter valid credentials
- [x] Provide MFA code
- [x] Redirect to `/home`

Expected

- [x] Session cookie set
- [x] CSRF token present
- [x] Home shows display name
```
````

Spry's Axiom pattern extracts each item with `checked` state, the text, and precise line
numbers.

## Frontmatter

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

Frontmatter errors are recorded as issues (warning), not fatal.

## How `folio.ts` parses & how you query

### Parse

```ts
import { parseOne } from "./folio.ts";
const f = await parseOne(
  "qualityfolio.md",
  await Deno.readTextFile("Qualityfolio.md"),
);
// f.headings(), f.leaves(), f.frontmatter(), f.issues()
```

### Apply roles later (choose a schema or discover it)

```ts
// Explicit schema (example): project → suite → plan → case
const view = f.withSchema(
  { h1: "project", h2: "suite", h3: "plan", h4: "case" } as const,
);
// Or discover & apply last-k roles from your desired schema:
import { applyDiscoveredSchema } from "./folio.ts";
const { discovery, view: v2 } = applyDiscoveredSchema(
  f,
  { h1: "project", h2: "suite", h3: "plan", h4: "case", h5: "step" } as const,
);

// Query
view.atRole("case"); // all terminal leaves mapped as "case"
view.groupBy("suite"); // Map<suiteTitle, case[]>
```

### Find tags or code blocks anywhere

```ts
f.findHeadingsByAnnotation("id", "acct-create-plan"); // plan heading by @id
f.findLeavesByAnnotation("severity", "critical"); // case leaves with severity
f.findCodeInHeadings({ lang: "yaml", depth: 3, scope: "self" }); // plan YAML
```

### Render a TOC-like list for your schema

```ts
import { lsSchema } from "./folio.ts";
console.table(lsSchema(f, view));
// HL | Nature  | Title
// 1  | Project | E2E Project Alpha
// 2  | Suite   | Accounts & Auth Suite
// 3  | Plan    | Account Creation Plan
// 4  | Case    | New user can sign up and verify email
```

> `lsSchema` walks headings in document order and prints the heading level (HL),
> schema role (“Nature”), and the heading title.

## File & folder naming (recommended, not required)

- Use lowercase with hyphens: `account-creation-plan.md`,
  `mobile-auth-login.case.md`.
- Keep evidence near the doc for easy links: `./evidence/...`.
- Typical repo layout (optional; use what fits your team):

```
support/
└── assurance/
    └── qualityfolio/
    │   ├── sample
    │   │   └── example-artifact.md	
    │   └── evidence/
    │   │   └── TC-0001/
    │   │       ├── screenshot1.auto.png
    │   │       ├── screenshot2.auto.png
    │   │       ├── result.auto.png
    │   │       └── run.auto.md
    ├── resource-surveillance.sqlite.db
    └── sqlite-etl.sql		
```

> Remember: the parser does not require any folder layout. This is just for DX.

## A Small starter you can copy

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

## <One test case title>

@id <test-case-id>

```yaml HFM
doc-classify:
requirementID: <requirement-id>
Tags: [tag 1, tag 2]
```

**Description**

Context One or two sentences that explain test case.

**Preconditions**

- [x] Write one precondition
- [x] Write another

**Steps**

- [ ] Do something the system should allow
- [ ] Do another thing

**Expected**

- [ ] Outcome that proves behavior
- [ ] Another observable result

### Evidence

@id <add an id to refer this evidence>

```yaml HFM
doc-classify:
cycle: <test-cycle-number>
assignee: Sarah Johnson
env: qa
status: passed
```

- [Run log](./evidence/run-2025-11-01.md)
- [Response JSON](./evidence/resp-2025-11-01.json)

````

## Executing SQL Queries from Surveilr-Generated SQLite Database

This section explains how to generate a SQLite database from Qualityfolio test artifacts (Markdown files) using Surveilr, and how to run SQL queries to derive test metrics:

The workflow covers:

1. Commands to ingest and transform Markdown artifacts
3. Generating the SQLite database
4. Running SQL ETL scripts
5. Executing SQL queries in VS Code’s SQLite extension


**Key Components**

| Item                                | Purpose                                                                                        |
| ----------------------------------- | ---------------------------------------------------------------------------------------------- |
| **qualityfolio/**                   | Contains all test artifacts (Markdown), including projects, suites, plans, cycles, cases, etc. and test execution results as evidence|
| **sqlite-etl.sql**                  | SQL file executed by Surveilr to create/populate tables in the SQLite database.                |
| **resource-surveillance.sqlite.db** | SQLite database generated by Surveilr after ETL.                                               |
| **surveilr ingest / orchestrate**   | Commands used to extract and transform test artifacts into structured data.                    |

### 1. Generating the SQLite Database

Surveilr creates a unified "resource-surveillance" database from your Markdown artifacts.

Run the following commands in the `assurance` folder (where `sqlite-etl.sql` is located):

**Ingest Markdown Artifacts**

```fish
surveilr ingest files -r ./qualityfolio/sample/  && surveilr orchestrate transform-markdown
```

This performs:

* Parsing of every Markdown file under `qualityfolio/sample/`
* Extraction of metadata (YAML, ontology, section roles)
* Transformation into Surveilr’s internal format

### 2. Running the SQLite ETL Script

After ingestion, execute the SQL ETL file to build the SQLite DB:

```fish
surveilr shell sqlite-etl.sql
```

This command:

* Opens the Surveilr SQL shell
* Runs **sqlite-etl.sql**, which creates and populates database tables
* Produces the file: `resource-surveillance.sqlite.db`

This file is automatically placed inside: `support/assurance/`

### 3. Inspecting the SQLite DB in VS Code

1. Use the **SQLite3 Editor** or **SQLite Viewer** extension in VS Code.
2. Open the file: `support/assurance/resource-surveillance.sqlite.db`

You will see tables such as:

* `t_all_sections`
* `t_projects`
* `t_files`
* `t_metadata`

The table most commonly used for Qualityfolio analytics is:

**`t_all_sections`**

| Column              | Description                                                                   |
| ------------------- | ----------------------------------------------------------------------------- |
| uniform_resource_id | Unique ID of the section                                                      |
| file_basename       | Source Markdown file                                                          |
| depth               | Heading depth (h1–h6)                                                         |
| title               | Extracted section title                                                       |
| role_name           | Ontology role (`project`, `suite`, `plan`, `cycle`, `case`, `paragraph` etc.) |
| extracted_id        | ID derived from YAML or heading                                               |

### 4. Running SQL Queries (Example)

Once the database is open in VS Code, you can execute queries from the **Query Editor**.

**Example: Get All Test Cases**

```sql
SELECT title
FROM t_all_sections
WHERE role_name = 'case';
```

**What This Query Returns**

A list of all section titles whose role has been classified as **case**, meaning:

* Individual test cases
* Extracted from corresponding Markdown files
* Processed through Surveilr's transformation engine

### 5. Typical Workflow Summary

| Step                      | Command / Action                                           | Output                            |
| ------------------------- | ---------------------------------------------------------- | --------------------------------- |
| **1. Ingest artifacts**   | `surveilr ingest files -r ./qualityfolio/sample/`          | Raw ingestion                     |
| **2. Transform Markdown** | `surveilr orchestrate transform-markdown`                  | Canonicalized representation      |
| **3. Run ETL**            | `surveilr shell sqlite-etl.sql`                            | `resource-surveillance.sqlite.db` |
| **4. Open DB in VS Code** | SQL extension                                              | Table overview                    |
| **5. Run query**          | `SELECT title FROM t_all_sections WHERE role_name='case';` | List of test cases                |

### 6. Notes

* The **sqlite-etl.sql** file must exist in the same directory where you run the Surveilr shell.
* The **qualityfolio** folder must contain valid Spry/Qualityfolio-style Markdown artifacts for ingestion to succeed.
* You can re-run the commands anytime after updating your Markdown files to regenerate the DB.

## Quality-of-life helper (optional): `qualityfolio.ts`

A small Deno-based CLI (similar to `spry.ts`) could scaffold Markdown:

- `init` presets: minimal, standard, compliance-heavy
- Scaffold case/suite/plan files with frontmatter & section stubs
- Normalize file/folder names
- Inject YAML/JSON metadata blocks

Concept:

```bash
deno run -A https://qualityfolio.dev/qualityfolio.ts init --preset minimal
deno run -A https://qualityfolio.dev/qualityfolio.ts new case "Login works"
deno run -A https://qualityfolio.dev/qualityfolio.ts new plan "Account Creation"
```

## Checklist for authors

- [ ] Use whatever heading depth you need up to 6th level (none are required).
- [ ] Prefer GFM tasks for steps & expected results.
- [ ] Add `@id`, `@severity`, `@component`, etc. where useful.
- [ ] Use fenced YAML/JSON for richer metadata.
- [ ] Link evidence files close to the doc.
- [ ] Let schemas or discovery decide roles later.

## Troubleshooting

- “My evidence isn’t detected” → an evidence must be a leaf heading (no deeper headings
  beneath it).
- “My annotations don’t show up” → ensure `@key value` is not inside a code
  block and is in the heading’s own section.
- “Discovery chose odd roles” → either add minimal content to meaningful
  ancestors (so they’re “significant”) or apply an explicit schema when
  querying.

## License

Your docs are yours. **Spry's Axiom pattern** is designed to read Markdown respectfully and
safely.
