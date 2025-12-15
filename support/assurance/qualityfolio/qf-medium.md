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

## Navigation Visibility

@id navigation-visibility-suite

Verifies visibility and ordering of CMMC Level 1 and Level 2 sections.

**Scope**

- Left navigation visibility for both levels.
- Order validation for all sections.
- Detection of missing or unconfigured items.
- Audit evidence capture.

### Verify Left Navigation Displays All Sections for Level 1 and Level 2

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

#### Evidence

@id TC-CMMC-0001

```yaml META
role: evidence
cycle: 1.1
assignee: prathitha
status: passed
```

**Attachment**

- [Results JSON](./evidence/TC-CMMC-0001/1.1/result.auto.json)
- [CMMC Level 1 navigation screenshot](./evidence/TC-CMMC-0001/1.1/cmmc1.auto.png)
- [CMMC Level 2 navigation screenshot](./evidence/TC-CMMC-0001/1.1/cmmc2.auto.png)
- [Run MD](./evidence/TC-CMMC-0001/1.1/run.auto.md/;)

## Navigation Control

@id navigation-control-suite

Validates section-to-section navigation through UI controls.

**Scope**

- Navigation transitions between sections.
- Sequential integrity for “Next” and “Previous” controls.
- No skipped or duplicated navigation events.
- Cross-level consistency validation.

### Verify Previous and Next Buttons Navigate Between Sections Correctly

@id TC-CMMC-0002

```yaml HFM
doc-classify:
requirementID: REQ-CMMC-001
Priority: High
Tags: [CMMC Self-Assessment]
Scenario Type: Happy Path
```

**Description**

Ensure that the **Previous** and **Next** buttons correctly navigate between
assessment sections for CMMC Level 1 and Level 2 self-assessments.

**Preconditions**

- [x] Valid user credentials are available.
- [x] User has access to both CMMC Level 1 and 2 self-assessment modules.
- [x] Navigation controls (Previous/Next) are visible on section pages.

**Steps**

- [x] Login and verify the CMMC Level 1 Self-Assessment section loads.
- [x] Start from Company Information.
- [x] Click **Next** → verify navigation to Access Control.
- [x] Click **Previous** → verify navigation back to Company Information.
- [x] Navigate to a middle section (e.g., \*\*Media Protection).
- [x] . Repeat **Next** and **Previous** navigation checks.

**Expected Results**

- [x] **Next** navigates to the next logical section in sequence.
- [x] **Previous** navigates to the immediately preceding section.
- [x] Navigation order remains consistent across cycles and levels.
- [x] No skipped or duplicate transitions occur.

#### Evidence

@id TC-CMMC-0002

```yaml META
role: evidence
cycle: 1.1
assignee: prathitha
status: passed
```

**Attachment**

- [Results JSON](./evidence/TC-CMMC-0002/1.1/result.auto.json)
- [Navigation screenshot](./evidence/TC-CMMC-0002/1.1/cmmc-next.auto.png)
- [Run MD](./evidence/TC-CMMC-0002/1.1/run.auto.md)

## Readiness Percentage Dynamics

@id rediness-percentage-dynamics-suite

Validates dynamic and accurate readiness percentage updates when sections are
completed in the CMMC self-assessment.

**Scope**

-Readiness percentage update after completing and submitting a section. -Correct
readiness calculation based on completed vs. total sections. -Immediate UI
update on dashboard/progress widget without manual refresh. -No lag, incorrect
values, or inconsistent readiness between dashboard and section views.
-Readiness percentage must reach 100% when all assessment sections are fully
completed.

### Verify Readiness Percentage Updates Dynamically on Completing a Section

@id TC-CMMC-0003

```yaml HFM
doc-classify:
FII: TC-CMMC-0003
requirementID: REQ-CMMC-001
Priority: High
Tags: [CMMC Self-Assessment, Analytics - Self-Assessment Tool]
Scenario Type: Happy Path
```

**Description**

Ensure that the **readiness percentage** updates dynamically when a section is
completed in the CMMC self-assessment.

**Preconditions**

- [x] Valid user credentials are available.
- [x] User has access to the **CMMC Level 1 Self-Assessment** module.
- [x] Readiness percentage widget/bar is visible on the dashboard or section
      screen.

**Steps**

- [x] Login with valid credentials and verify the **CMMC Level 1
      Self-Assessment** section is displayed on the landing page.
- [x] Open and complete the **Company Information** section with valid details.
- [x] Submit the section and return to the dashboard or progress display area.
- [x] Observe the **readiness percentage bar** for dynamic updates.

**Expected Results**

- [x] Readiness percentage increases immediately after completing the section.
- [x] Updated readiness value reflects correct progress calculation.
- [x] No delay, lag, or incorrect values appear during the update.

#### Evidence

@id TC-CMMC-0003

```yaml META
role: evidence
cycle: 1.5
assignee: arun-ramanan
status: passed
```

**Attachment**

- [Results JSON](./evidence/TC-CMMC-0003/1.5/result.auto.json)
- [Readiness screenshot](./evidence/TC-CMMC-0003/1.5/cmmc1.auto.png)
- [Run MD](./evidence/TC-CMMC-0003/1.5/run.auto.md)

### Verify Readiness Bar Reflects Accurate Percentage Completion

@id TC-CMMC-0004

```yaml HFM
doc-classify:
FII: TC-CMMC-0004
requirementID: REQ-CMMC-001
Priority: High
Tags: [CMMC Self-Assessment, Analytics - Self-Assessment Tool]
Scenario Type: Happy Path
```

**Description**

Validate that the **readiness bar** displays correct percentage values based on
completed sections.

**Preconditions**

- [x] Valid user credentials are available.
- [x] User has access to the **CMMC Level 1 Self-Assessment** module.
- [x] Readiness percentage bar is visible on the dashboard or assessment screen.

**Steps**

- [x] Login with valid credentials and verify that the landing page displays the
      **CMMC Level 1 Self-Assessment** section.
- [x] Open the self-assessment containing 8 sections.
- [x] Complete 2 sections fully.
- [x] Observe the readiness percentage displayed on the readiness bar.

**Expected Results**

- [x] Readiness bar should show **25% completion** (2 of 8 sections completed).
- [x] Percentage displayed matches the actual completed section count.
- [x] No inconsistencies or miscalculations appear.

#### Evidence

@id TC-CMMC-0004

```yaml META
doc-classify:
role: evidence
cycle: 1.5
assignee: arun-ramanan
status: passed
```

**Attachment**

- [Results JSON](./evidence/TC-CMMC-0004/1.5/result.auto.json)
- [Readiness screenshot1](./evidence/TC-CMMC-0004/1.5/cmmc1.auto.png)
- [Readiness screenshot2](./evidence/TC-CMMC-0004/1.5/cmmc2.auto.png)
- [Run MD](./evidence/TC-CMMC-0004/1.5/run.auto.md)

### Verify Readiness Percentage Reaches 100% After Completing All Sections

@id TC-CMMC-0005

```yaml HFM
doc-classify:
FII: TC-CMMC-0005
requirementID: REQ-CMMC-006
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

#### Evidence

@id TC-CMMC-0005

```yaml HFM
role: evidence
cycle: 1.5
assignee: arun-ramanan
status: failed
```

**Attachment**

- [Results JSON](./evidence/TC-CMMC-0005/1.5/result.auto.json)
- [Readiness screenshot1](./evidence/TC-CMMC-0005/1.5/cmmc1.auto.png)
- [Readiness screenshot2](./evidence/TC-CMMC-0005/1.5/cmmc2.auto.png)
- [Run MD](./evidence/TC-CMMC-0005/1.5/run.auto.md)

**Issue**

```yaml META
role: issue
issue_id: BUG-CMMC-001
test_case_id: TC-CMMC-0005
title: "No incorrect or partial percentage is shown"
status: open
```

**Issue Details**

- [Bug Details](https://github.com/surveilr/surveilr/issues/354)

## Login E2E Suite (Manual)

@id suite

Ensures complete manual validation of Opsfolio login flow — from UI visibility
to post-login dashboard verification.

**Scope**

- Manual login validation for CMMC portal.
- Evidence collection for compliance and user acceptance.

### Verify Login button visibility and navigation

@id TC-LOGIN-0001

```yaml
FII: TC-LOGIN-0001
requirementID: REQ-LOGIN-001
Priority: High
Tags: [Opsfolio, UI, Login]
Scenario Type: Happy Path
```

**Description**

Ensure the Login button is visible on the Opsfolio CMMC page and leads correctly
to the authentication screen.

**Preconditions**

- [x] Application is accessible.
- [x] Browser cache cleared.
- [x] Network connectivity stable.

**Steps**

- [x] Navigate to
      [https://opsfolio.com/regime/cmmc](https://opsfolio.com/regime/cmmc)
- [x] Confirm Login button visible at top-right corner.
- [x] Click **Login**.
- [x] Confirm redirection to login page/modal.
- [x] Verify presence of username/password fields.

**Expected**

- [x] Login button visible and clickable.
- [x] Correct redirection to login form.
- [x] Authentication fields displayed properly.

#### Evidence

@id TC-LOGIN-0001

```yaml HFM
role: evidence
cycle: 1.1
assignee: Ann Jose
status: passed
```

- [Results JSON](./evidence/TC-LOGIN-0001/1.1/result.auto.json)
- [Run MD](./evidence/TC-LOGIN-0001/1.1/run.auto.md)

### Verify successful login with valid credentials

@id TC-LOGIN-0002

```yaml
FII: TC-LOGIN-0002
requirementID: REQ-LOGIN-001
Priority: High
Tags: [Opsfolio, UI, Login]
Scenario Type: Happy Path
```

**Description**

Validate successful authentication and dashboard redirection for valid users.

**Preconditions**

- [x] Valid Opsfolio credentials available.
- [x] Authentication endpoint functional.

**Steps**

- [x] Open login page.
- [x] Enter valid username and password.
- [x] Click **Login**.
- [x] Confirm navigation to user dashboard.

**Expected**

- [x] Login succeeds.
- [x] Dashboard loads successfully.
- [x] No unexpected errors.

#### Evidence

@id TC-LOGIN-0002

```yaml HFM
role: evidence
cycle: 1.1
assignee: Dency
status: passed
```

- [Results JSON](./evidence/TC-LOGIN-0002/1.1/result.auto.json)
- [Run MD](./evidence/TC-LOGIN-0002/1.1/run.auto.md)

### Verify error message for invalid credentials

@id TC-LOGIN-0003

```yaml
FII: TC-LOGIN-0003
requirementID: REQ-LOGIN-001
Priority: High
Tags: [Opsfolio, UI, Login]
Scenario Type: Happy Path
```

**Description**

Validate proper error handling for incorrect login attempts.

**Preconditions**

- [x] Application online.
- [x] Invalid credentials known.

**Steps**

- [x] Navigate to login page.
- [x] Enter invalid credentials.
- [x] Click **Login**.
- [x] Observe displayed message.

**Expected**

- [x] “Invalid username or password” message displayed.
- [x] User remains on login page.
- [x] No sensitive information exposed.

#### Evidence

@id TC-LOGIN-0003

```yaml HFM
role: evidence
cycle: 1.1
assignee: Ann Jose
status: passed
```

- [Results JSON](./evidence/TC-LOGIN-0003/1.1/result.auto.json)
- [Run MD](./evidence/TC-LOGIN-0003/1.1/run.auto.md)

### Verify error handling during network failure

@id TC-LOGIN-0004

```yaml
FII: TC-LOGIN-0004
requirementID: REQ-LOGIN-001
Priority: High
Tags: [Opsfolio, UI, Login]
Scenario Type: Unhappy Path
```

**Description**

Validate proper error handling for login attempts due to network timeout on
Opsfolio login page

**Preconditions**

1. Access to the Opsfolio login page —
   [https://opsfolio.com/login/](https://opsfolio.com/login/)
2. Valid Opsfolio user credentials (username and password).
3. An unstable or throttled network connection to reproduce timeout behavior.

**Steps**

1. Navigate to [https://opsfolio.com/login/](https://opsfolio.com/login/).
2. Enter valid username and password.
3. Initiate login and simulate slow or intermittent network connectivity.
4. Observe the system’s behavior and any displayed error messages.

**Expected**

1. The system should display a clear and user-friendly **“Network Timeout”**
   message.
2. Application should **retry the authentication request** or allow the user to
   retry manually.
3. The user should not see misleading messages such as “Invalid credentials.”
4. The application should handle timeouts gracefully without breaking session
   flow.

#### Evidence

@id TC-LOGIN-0004

```yaml HFM
role: evidence
cycle: 1.1
assignee: Prathitha
status: failed
issue_id: ["BUG-OPS-001"]
```

- [Results JSON](./evidence/TC-LOGIN-0004/1.1/result.auto.json)
- [Run MD](./evidence/TC-LOGIN-0004/1.1/run.auto.md)
- [Error - screenshot](./evidence/TC-LOGIN-0004/1.1/network-error.auto.png)
- [Bug MD](./evidence/TC-LOGIN-0004/1.1/bug.md)

## Login E2E Suite (Automated)

@id suite-automation

Automates verification of Opsfolio login flow using browser automation for CI/CD
pipelines and regression testing.

**Scope**

- Playwright-based test automation.
- Authentication workflow validation in QA and Staging(UI + API).
- Supports regression testing before releases.
- Captures execution logs, evidence, and trace files for audit and compliance.

### Verify Login button visibility via automation

@id TC-LOGIN-0101

```yaml
FII: TC-LOGIN-0101
requirementID: REQ-LOGIN-001
Priority: High
Tags: [Opsfolio, UI, Login, Regression]
Scenario Type: Happy Path
automation_tool: Playwright
execution_env: QA
```

**Description**

Automated verification of the **Login button presence and accessibility** on the
Opsfolio CMMC page using DOM validation and visual evidence capture.

**Preconditions**

- [x] Application deployed in QA environment.
- [x] Network connectivity stable.
- [x] Browser automation agent initialized.

**Steps**

- Navigate to `https://opsfolio.com/regime/cmmc`
- Wait for page load completion.
- Validate DOM element `"text=Login"` presence.
- Capture page screenshot post verification.

**Expected**

- [x] “Login” button is visible and clickable.
- [x] No console or JavaScript errors logged.
- [x] Page title and URL are correct.

#### Evidence

@id TC-LOGIN-0101

```yaml HFM
role: evidence
cycle: 1.1
assignee: Prathitha
status: passed
```

- [Results JSON](./evidence/TC-LOGIN-0101/1.1/result.auto.json)
- [Run MD](./evidence/TC-LOGIN-0101/1.1/run.auto.md)

### Verify successful login with valid credentials via automation

@id TC-LOGIN-0102

```yaml
FII: TC-LOGIN-0102
requirementID: REQ-LOGIN-001
Priority: High
Tags: [Opsfolio, UI, Authentication, Login, Regression]
Scenario Type: Happy Path
automation_tool: Playwright
execution_env: QA
```

**Description**

Automated validation ensuring users can successfully log in using valid
credentials and are redirected to the dashboard.

**Preconditions**

- [x] Valid Opsfolio credentials available in secured vault.
- [x] Authentication API endpoint responsive.
- [x] Test user has active account status.

**Steps**

- Launch browser and navigate to `https://opsfolio.com/login`
- Fill in **username** and **password** fields using valid credentials.
- Click the **Login** button.
- Wait for redirect to `/dashboard`.
- Capture network request/response for `/login` and UI screenshot.

**Expected**

- [x] User authenticated successfully (HTTP 200).
- [x] Redirected to dashboard (`/dashboard`).
- [x] Dashboard elements visible (header, user info, logout option).
- [x] No console errors or failed requests.

#### Evidence

@id TC-LOGIN-0102

```yaml HFM
role: evidence
cycle: 1.1
assignee: Prathitha
status: passed
```

- [Results JSON](./evidence/TC-LOGIN-0102/1.1/result.auto.json)
- [Run MD](./evidence/TC-LOGIN-0102/1.1/run.auto.md)

### Verify error handling for invalid credentials via automation

@id TC-LOGIN-0103

```yaml
FII: TC-LOGIN-0103
requirementID: REQ-LOGIN-001
Priority: High
Tags: [Opsfolio, UI, Login, Negative, Regression]
Scenario Type: Negative Path
automation_tool: Playwright
execution_env: QA
```

**Description**

Automated validation of proper error message display and security behavior for
invalid login attempts.

**Preconditions**

- [x] Application online and accessible.
- [x] Invalid credentials available for testing.
- [x] Error message element selector known.

**Steps**

- Open the Opsfolio login page.
- Enter invalid username and password.
- Click the **Login** button.
- Observe the displayed error message.
- Capture screenshot and console logs.

**Expected**

- [x] “Invalid username or password” message displayed.
- [x] User remains on login page (no redirect).
- [x] HTTP status != 200 for `/login` request.
- [x] No sensitive details shown in response or UI.

#### Evidence

@id TC-LOGIN-0103

```yaml HFM
role: evidence
cycle: 1.1
assignee: Ann Jose
status: passed
```

- [Results JSON](./evidence/TC-LOGIN-0103/1.1/result.auto.json)
- [Run MD](./evidence/TC-LOGIN-0103/1.1/run.auto.md)
