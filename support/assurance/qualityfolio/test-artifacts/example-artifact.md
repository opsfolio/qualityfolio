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

# Qualityfolio

```yaml HFM
tenantID: Qualityfolio
```

@id Qualityfolio

The Qualityfolio application testing project focuses on validating the reliability, security, and usability of the Qualityfolio platform, which supports user authentication, role-based access, event participation, and member interactions. The project aims to ensure that core user journeys—such as login, function correctly and consistently across browsers and devices

**Objectives**

- Verify that valid users can log in successfully with correct credentials.
- Ensure invalid or empty credentials produce appropriate error messages.
- Confirm the system restricts login after a defined number of failed attempts.
- Validate that password fields and session cookies are handled securely.
- Confirm that logged-in users can log out safely, and sessions are terminated correctly.
- Ensure all authentication features conform to OWASP best practices.

**Risks**

- Login failures for valid users due to authentication or session-handling issues.
- Inadequate or unclear error messaging for invalid credentials or expired sessions.
- Broken or incorrect redirection after login, logout, or session timeout.
- Unauthorized access to restricted pages due to improper role validation.
- UI rendering issues on different browsers or screen sizes.
- Session timeout or token expiration issues causing unexpected user logouts.
- Automation instability caused by dynamic DOM elements or frequently changing IDs.

## Qualityfolio Comprehensive Plan

@id PLAN-REQ-SUR-001

```yaml HFM
plan-name: qualityfolio-plan
plan-date: 04-13-2026
created-by: QA Team
```

**Objectives**

- Execute all **10 test cases**.
- Validate CLI help, admin, ingest, orchestrate, shell, merge, and IMAP.
- Capture automated evidence for all test cases.

**Cycle Goals**

- Execute all **10 test cases** in cycle.
- All tests expected to pass with `ok` status.

**Acceptance Criteria**

- The **Solutions footer** contains all expected role-based links.
- Clicking any role-based link in the footer navigates to the correct role landing page.
- The breadcrumb displays the correct path (`Home / Role / [Role Name]`) and the **Home** segment is clickable.
- All **CTA links** on each role-based page function as expected, leading to the correct target pages.
- No broken links, 4xx/5xx errors, or unexpected redirects occur.
- The UI/UX is consistent across all role-based landing pages.

---

**Qualityfolio Comprehensive Requirements**

@id Qualityfolio-REQ-001

```yaml HFM
doc-classify:
  role: requirement
  requirementID: REQ-QUALITYFOLIO-01
  title: Qualityfolio CLI and Engine Integrity
  description: Defines the functional and operational requirements for Qualityfolio's CLI tools, ingestion engine, and orchestration capabilities, ensuring data integrity and correct SQL execution operations.
```

**Functional Requirements**

- **CLI Functions**
  - The system shall expose and reliably execute core CLI functions (`version`, `mask`, `eval`, `text`, `regexp`, `vsv`, `lines`).

- **Execution Engine**
  - The `eval` function shall execute raw SQL and correctly return string representations, supporting complex joins of multiple rows/values.
  - Shell execution runs must produce equivalent parsing and execution outcomes against the internal engine.

- **Ingestion and Administration**
  - The database initialization (`init`), state merging (`merge`), and credential definitions must be secure and reliable.
  - The ingestion engine shall support robust data loading, including CSV transformations, dry-run validations, stats reporting, and multi-tenant ingestion bounds.

- **Orchestration & Mail**
  - The system shall handle structured data transformations (HTML/XML processing) accurately.
  - IMAP integrations must faithfully download, filter, and attachment-map emails to the surveillance targets.

---

**Acceptance Criteria**

- Core SQL shell and CLI functions execute without runtime errors and produce matching reference outputs.
- Ingestion dry-runs correctly predict the ingestion impact without altering the active state.
- Execution pipelines correctly extract and transform the specified XML/HTML values.

---

### Qualityfolio Comprehensive Suite

@id SUITE-REQ-SUR-001

```yaml HFM
suite-name: Qualityfolio-comprehensive-suite
suite-date: 04-13-2026
created-by: QA Team
```

**Scope**

- CLI functions: version, mask, eval, text, regexp, lines, vsv.
- Web UI server availability.
- Admin operations: credentials, init, merge.
- Doctor: system diagnostics.
- File ingestion: dry-run, stats, multi-tenant, CSV auto-transform.
- Orchestration: HTML, XML transforms.
- Shell: SQL execution, engine comparison.
- IMAP: account ingestion, attachments, filtering.

**Test Cases**

- **TC-QUALITYFOLIO-001** – Verify successful login using registered email and correct password
- **TC-QUALITYFOLIO-002** – eval function: execute arbitrary SQL and returns the result as string
- **TC-QUALITYFOLIO-003** – Verify login failure when session token has expired
- **TC-QUALITYFOLIO-004** – Verify login failure with valid email and invalid password
- **TC-QUALITYFOLIO-005** – Verify account lockout after 5 consecutive failed login attempts
- **TC-QUALITYFOLIO-006** – Verify secure transport (HTTPS) is enforced on the login page
- **TC-QUALITYFOLIO-007** – Verify protection against Cross-Site Scripting (XSS) in input fields
- **TC-QUALITYFOLIO-008** – Verify protection against SQL Injection in the login form
- **TC-QUALITYFOLIO-009** – Verify successful logout and secure session termination
- **TC-QUALITYFOLIO-010** – Verify Remember Me functionality persists session correctly

---

#### Verify successful login using registered email and correct password

@id TC-QUALITYFOLIO-001

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: High
tags: ["Login", "Positive", "Authentication"]
scenario-type: Happy Path
Execution Type: Automation
Test Type: UI Tests
```

**Description**

Verify that a user can successfully log in using a registered email and the correct passwords in the QUALITYFOLIO application.

**Preconditions**

- [x] User must have a valid registered account on https://qualityfolio.dev/.
- [x] The account must be active and not locked.

**Steps**

- [x] Navigate to https://qualityfolio.dev/.

**Expected Results**

- [x] User is successfully authenticated.
- [x] The system redirects the user to their dashboard or home page.
- [x] The session is created and remains active until logout or timeout.
- [x] No error messages are displayed.

##### Evidence

@id TC-QUALITYFOLIO-001

```yaml HFM
cycle: 1.0.2
cycle-date: 04-13-2026
severity: Critical
assignee: John Doe
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-001/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-001/1.1/run.auto.md)

#### Verify login failure due to network timeout despite correct credentials

@id TC-QUALITYFOLIO-002

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: High
tags: ["Login", "Network Timeout", "Negative", "Resilience"]
scenario-type: Happy Path
Execution Type: Manual
Test Type: Manual Tests
```

**Description**

This test case validates that when a user attempts to log in with **valid credentials**, but the network connection becomes **unstable or times out** during the request, the system correctly handles the error without granting access. It ensures the application gracefully handles timeouts and maintains security by not allowing unintended login success.

**Preconditions**

- [x] User account already exists with valid credentials.
- [x] Access to the login page of [https://qualityfolio.dev/](https://qualityfolio.dev/).
- [x] Simulated or controlled network interruption setup (e.g., throttled or unstable network).

**Steps**

- [x] Navigate to the login page.
- [x] Enter valid user credentials (registered email and correct password).
- [x] Before clicking **Login**, simulate a network slowdown or disconnection.
- [x] Click on the **Login** button.
- [x] Observe the system response during the timeout or connection drop.
- [ ] Reconnect the network and check whether the session was created or access granted.

**Expected Results**

- [x] The login request fails gracefully due to the network timeout.
- [x] The system displays an appropriate error message, such as:
  - [x] “Unable to connect. Please check your network connection and try again.”
  - [x] “Request timed out. Login could not be completed.”
- [x] User is **not logged in**, and **no active session** is created.
- [x] After restoring the network, the user can successfully log in again with the same credentials.

##### Evidence

@id TC-QUALITYFOLIO-002

```yaml HFM
cycle: 1.0.2
cycle-date: 04-13-2026
severity: Critical
assignee: Sarah Kim
status: failed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-001/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-001/1.1/run.auto..md)
- [Screenshot](../evidence/TC-QUALITYFOLIO-001/1.1/loginButtonClick.png)

**Issue**

```yaml HFM
doc-classify:
  role: issue
  issue_id: BUG-QUALITYFOLIO-002
  created_date: 12-18-2025
  test_case_id: TC-QUALITYFOLIO-002
  title: "Login fails with timeout error even when valid credentials are used"
  status: open
```

**Issue Details**

- [Bug Details](https://github.com/Qualityfolio/Qualityfolio/issues/354)
- [Screenshot](../evidence/TC-QUALITYFOLIO-002/1.1/loginButtonClick.png)

#### Verify login failure when session token has expired

@id TC-QUALITYFOLIO-003

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: High
tags: ["Login", "Session", "Negative", "Security"]
scenario-type: Negative Path
Execution Type: Manual
Test Type: Manual Tests
```

**Description**

This test case validates that when a user attempts to access a protected page using an **expired session token**, the system correctly rejects the request, invalidates the session, and redirects the user to the login page without exposing any protected data.

**Preconditions**

- [x] User account already exists with valid credentials.
- [x] Access to the login page of [https://qualityfolio.dev/](https://qualityfolio.dev/).
- [x] An expired or manually invalidated session token is available for testing.

**Steps**

- [x] Log into the application with valid credentials.
- [x] Allow the session to expire (or manually invalidate the token via browser devtools).
- [x] Attempt to navigate to a protected page (e.g., dashboard).
- [x] Observe the system response.
- [ ] Verify that the user is redirected to the login page.

**Expected Results**

- [x] The system detects the expired session token.
- [x] Access to the protected page is denied.
- [ ] The user is redirected to the login page with a message such as "Your session has expired. Please log in again."
- [ ] No protected data is visible or accessible during or after the redirect.

##### Evidence

@id TC-QUALITYFOLIO-003

```yaml HFM
cycle: 1.0.2
cycle-date: 04-13-2026
severity: Critical
assignee: John Doe
status: closed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-003/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-003/1.1/run.auto.md)
- [Screenshot](../evidence/TC-QUALITYFOLIO-003/1.1/sessionExpiredRedirect.png)

#### Verify login failure with valid email and invalid password

@id TC-QUALITYFOLIO-004

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: High
tags: ["Login", "Negative", "Authentication"]
scenario-type: Negative Path
Execution Type: Manual
Test Type: Manual Tests
```

**Description**

Verify that a user cannot log in when providing a valid email address but an incorrect password.

**Preconditions**

- [x] User has a valid registered account on https://qualityfolio.dev/.

**Steps**

- [x] Navigate to the login page.
- [x] Enter valid email address.
- [x] Enter incorrect password.
- [x] Click on the Login button.

**Expected Results**

- [x] User is not authenticated.
- [x] System displays an error message: "Invalid email or password."

##### Evidence

@id TC-QUALITYFOLIO-004

```yaml HFM
cycle: 1.0.3
cycle-date: 04-13-2026
severity: High
assignee: Sarah Kim
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-004/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-004/1.1/run.auto.md)

#### Verify account lockout after 5 consecutive failed login attempts

@id TC-QUALITYFOLIO-005

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: High
tags: ["Login", "Negative", "Lockout"]
scenario-type: Negative Path
Execution Type: Automation
Test Type: UI Tests
```

**Description**

Verify that a user account is temporarily locked out after 5 consecutive failed login attempts to prevent brute-force attacks.

**Preconditions**

- [x] User has a valid registered account.

**Steps**

- [x] Navigate to the login page.
- [x] Enter valid email address and an incorrect password.
- [x] Repeat the incorrect login attempt 4 more times.
- [x] Attempt to log in with the correct password.

**Expected Results**

- [x] Account is locked out after the 5th attempt.
- [x] System displays an error message: "Account locked due to too many failed attempts. Try again later."
- [x] The 6th attempt with correct credentials is also rejected until the lockout period expires.

##### Evidence

@id TC-QUALITYFOLIO-005

```yaml HFM
cycle: 1.0.3
cycle-date: 04-13-2026
severity: High
assignee: John Doe
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-005/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-005/1.1/run.auto.md)

#### Verify secure transport (HTTPS) is enforced on the login page

@id TC-QUALITYFOLIO-006

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: High
tags: ["Login", "Security", "Transport"]
scenario-type: Security Validation
Execution Type: Automation
Test Type: Manual Tests
```

**Description**

Verify that the login page and authentication requests are transmitted securely over HTTPS, and HTTP requests are forced to redirect.

**Preconditions**

- [x] Access to a web browser and network interception tool.

**Steps**

- [x] Attempt to navigate to http://qualityfolio.dev/.
- [x] Inspect the network traffic during login.

**Expected Results**

- [x] The user is automatically redirected to the HTTPS version of the site.
- [x] Authentication tokens and credentials are encrypted in transit.

##### Evidence

@id TC-QUALITYFOLIO-006

```yaml HFM
cycle: 1.0.3
cycle-date: 04-13-2026
severity: High
assignee: John Doe
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-006/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-006/1.1/run.auto.md)

#### Verify protection against Cross-Site Scripting (XSS) in input fields

@id TC-QUALITYFOLIO-007

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: Critical
tags: ["Login", "Security", "XSS"]
scenario-type: Security Validation
Execution Type: Manual
Test Type: Unit Tests
```

**Description**

Verify that the login input fields sanitize user input to prevent Cross-Site Scripting (XSS) attacks.

**Preconditions**

- [x] Access to the login page.

**Steps**

- [x] Navigate to the login page.
- [x] Enter `<script>alert('XSS')</script>` in the email or password fields.
- [x] Click Login.

**Expected Results**

- [x] The input is sanitized or rejected by the system.
- [x] The script is not executed by the browser.
- [x] An appropriate validation error is shown.

##### Evidence

@id TC-QUALITYFOLIO-007

```yaml HFM
cycle: 1.0.4
cycle-date: 04-13-2026
severity: Critical
assignee: Sarah Kim
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-007/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-007/1.1/run.auto.md)

#### Verify protection against SQL Injection in the login form

@id TC-QUALITYFOLIO-008

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: Critical
tags: ["Login", "Security", "SQLi"]
scenario-type: Security Validation
Execution Type: Automation
Test Type: Service Tests
```

**Description**

Verify that the application prevents SQL injection attacks via the login form fields.

**Preconditions**

- [x] Access to the login page.

**Steps**

- [x] Navigate to the login page.
- [x] Enter known SQL injection payloads (e.g., `' OR '1'='1`) into the email/password fields.
- [x] Click Login.

**Expected Results**

- [x] Database queries are unaffected by the input.
- [x] Authentication is rejected cleanly.
- [x] System displays a generic "Invalid email or password" error.

##### Evidence

@id TC-QUALITYFOLIO-008

```yaml HFM
cycle: 1.0.4
cycle-date: 04-13-2026
severity: Critical
assignee: Sarah Kim
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-008/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-008/1.1/run.auto.md)

#### Verify successful logout and secure session termination

@id TC-QUALITYFOLIO-009

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: High
tags: ["Logout", "Functional", "Positive"]
scenario-type: Happy Path
Execution Type: Automation
Test Type: UI Tests
```

**Description**

Verify that a user can successfully log out and their session token is destroyed server-side and client-side.

**Preconditions**

- [x] User is logged in to the application.

**Steps**

- [x] Click the Logout button.
- [x] Attempt to navigate back to a protected route (e.g., dashboard) using the browser's back button.

**Expected Results**

- [x] User is logged out and redirected to the login page.
- [x] Attempting to access protected pages redirects to the login screen.
- [x] Session cookie is cleared from the browser.

##### Evidence

@id TC-QUALITYFOLIO-009

```yaml HFM
cycle: 1.0.4
cycle-date: 04-13-2026
severity: Critical
assignee: John Doe
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-009/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-009/1.1/run.auto.md)

#### Verify Remember Me functionality persists session correctly

@id TC-QUALITYFOLIO-010

```yaml HFM
requirementID: REQ-QUALITYFOLIO-01
priority: Medium
tags: ["Login", "Functional", "Cookies"]
scenario-type: Happy Path
Execution Type: Manual
Test Type: Unit Tests
```

**Description**

Verify that using the "Remember Me" option during login allows the user to skip the authentication step upon revisiting the application within the defined expiration period.

**Preconditions**

- [x] User has valid credentials.

**Steps**

- [x] Navigate to the login page.
- [x] Enter credentials and check the "Remember Me" checkbox.
- [x] Click Login.
- [x] Close the browser and reopen it.
- [x] Navigate back to the application.

**Expected Results**

- [x] User is automatically signed into the application.
- [x] User is seamlessly redirected to the dashboard without entering credentials.

##### Evidence

@id TC-QUALITYFOLIO-010

```yaml HFM
cycle: 1.0.4
cycle-date: 04-13-2026
severity: Critical
assignee: John Doe
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-QUALITYFOLIO-010/1.1/result.auto.json)
- [Run MD](../evidence/TC-QUALITYFOLIO-010/1.1/run.auto.md)
