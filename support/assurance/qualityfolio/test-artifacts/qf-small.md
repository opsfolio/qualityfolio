---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: case
  - select: heading[depth="3"]
    role: evidence
---

# www.Opsfolio.com

@id opsfolio-project

This project ensures that all **CMMC Level 1** and **Level 2** self-assessment
sections are visible, correctly structured, and navigable — both from the left
navigation panel and through section navigation controls. Additionally, it
validates the **Opsfolio Login functionality** to ensure users can securely
authenticate and access the system without UI or backend issues.

**Objectives**

- Ensure the Login button is clearly visible and functional.
- Validate successful authentication using valid credentials.
- Confirm redirection to the correct post-login page.
- Verify appropriate error messages for invalid credentials.
- Support automation for regression and continuous testing.
- Validate that Level 1 and Level 2 sections display completely and in the
  correct order.
- Confirm that navigation controls (Next/Previous) function correctly.
- Provide audit-ready evidence for navigation and control consistency.

**Risks**

- Login button missing or misaligned on UI.
- Authentication failures for valid users.
- Broken redirects post successful login.
- Missing or unclear error messages for invalid attempts.
- Automation scripts failing due to unstable DOM or dynamic IDs.
- Inconsistent navigation rendering per level.
- Misconfigured section lists after release.
- Caching or feature-flag discrepancies across environments.
- Broken navigation buttons or incorrect sequence transitions.

## Verify Left Navigation Displays All Sections for Level 1 and Level 2

@id TC-CMMC-0001

```yaml HFM
doc-classify:
requirementID: REQ-CMMC-001
Priority: High
Tags: [CMMC Self-Assessment]
Scenario Type: Happy Path
```

**Description**

Verify that all CMMC Level 1 and Level 2 self-assessment sections are correctly
displayed in the left-side navigation panel.

**Preconditions**

- [x] Valid user credentials are available.
- [x] User account has access to both CMMC Level 1 and Level 2 self-assessment
      modules.
- [x] Application environment is loaded with all expected sections.

**Steps**

- [x] Login with valid credentials and verify that the landing page displays the
      **CMMC Level 1 Self-Assessment** section.
- [x] Verify the list of sections displayed on the left-side navigation panel.
- [x] Compare the displayed list with the **expected Level 1 sections**.
- [x] Navigate to the **CMMC Level 2 Self-Assessment** page.
- [x] Verify the list of sections displayed on the left panel.
- [x] Compare the displayed list with the **expected Level 2 sections**.

**Expected Results**

- [x] All expected sections are visible in the left navigation panel.
- [x] Sections appear in the correct defined order for each level.
- [x] No extra or unconfigured sections are displayed.

**Expected Level 1 Sections**

- [x] Company Information
- [x] Access Control
- [x] Identification & Authentication
- [x] Media Protection
- [x] Physical Protection
- [x] System & Communications Protection
- [x] System & Information Integrity
- [x] Policy Framework Assessment

**Expected Level 2 Sections**

- [x] Company Information
- [x] Access Control
- [x] Audit & Accountability
- [x] Awareness & Training
- [x] Configuration Management
- [x] Identification & Authentication
- [x] Incident Response
- [x] Maintenance
- [x] Media Protection
- [x] Personnel Security
- [x] Physical Protection
- [x] Risk Assessment
- [x] Security Assessment
- [x] System & Communications Protection
- [x] System & Information Integrity

### Evidence

@id TC-CMMC-0001

```yaml META
doc-classify:
cycle: 1.1
assignee: Emily Davis
status: passed
```

**Attachment**

- [Results JSON](./evidence/TC-CMMC-0001/1.1/result.auto.json)
- [CMMC Level 1 navigation screenshot](./evidence/TC-CMMC-0001/1.1/cmmc1.auto.png)
- [CMMC Level 2 navigation screenshot](./evidence/TC-CMMC-0001/1.1/cmmc2.auto.png)
- [Run MD](./evidence/TC-CMMC-0001/1.1/run.auto.md)

## Verify Readiness Percentage Reaches 100% After Completing All Sections

@id TC-CMMC-0002

```yaml HFM
doc-classify:
FII: TC-CMMC-0002
requirementID: REQ-CMMC-001
Priority: High
Tags: [CMMC Self-Assessment, Analytics - Self-Assessment Tool]
Scenario Type: Happy Path
```

**Description**

Ensure that the readiness percentage becomes 100% once all sections in the CMMC
Level 1 self-assessment are completed.

**Preconditions**

- [x] Valid user credentials are available.
- [x] User has access to the CMMC Level 1 Self-Assessment module.
- [x] All assessment sections are visible and accessible.

**Steps**

- [x] Login with valid credentials and verify that the landing page displays the
      CMMC Level 1 Self-Assessment section.
- [x] Complete all sections in the Level 1 Self-Assessment.
- [x] Observe the readiness percentage displayed.
- [ ] Verify that the readiness bar reaches 100%.

**Expected Results**

- [x] Readiness bar should display 100% completion after all sections are
      completed.
- [x] Percentage updates immediately without delay.
- [ ] No incorrect or partial percentage is shown.

### Evidence

@id TC-CMMC-0002

```yaml HFM
doc-classify:
cycle: 1.5
assignee: John Carter
status: failed
```

**Attachment**

- [Results JSON](./evidence/TC-CMMC-0002/1.5/result.auto.json)
- [Readiness screenshot1](./evidence/TC-CMMC-0002/1.5/cmmc1.auto.png)
- [Readiness screenshot2](./evidence/TC-CMMC-0002/1.5/cmmc2.auto.png)
- [Run MD](./evidence/TC-CMMC-0002/1.5/run.auto.md)

**Issue**

```yaml META
doc-classify:
  role: issue
issue_id: BUG-CMMC-001
test_case_id: TC-CMMC-0005
title: "No incorrect or partial percentage is shown"
status: open
```

**Issue Details**

- [Bug Details](https://github.com/surveilr/surveilr/issues/354)

