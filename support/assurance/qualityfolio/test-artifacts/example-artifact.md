---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: case
  - select: heading[depth="3"]
    role: evidence
---

# owasp.glueup

@id glueup-project

The OWASP GLUE application testing project focuses on validating the reliability, security, and usability of the OWASP GLUE platform, which supports user authentication, role-based access, event participation, and member interactions. The project aims to ensure that core user journeys—such as login, dashboard navigation, event discovery and registration, and profile management—function correctly and consistently across browsers and devices

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


## Verify successful login using registered email and correct password

@id TC-GLUE-001

```yaml HFM
doc-classify:
requirementID: REQ-GLUE-01
priority: High
tags: ["Login", "Positive", "Authentication"]
scenario-type: Happy Path
```

**Description**

Verify that a user can successfully log in using a registered email and the correct password in the OWASP GlueUp application.

**Preconditions**

- [x] User must have a valid registered account on https://owasp.glueup.com/.
- [x] The account must be active and not locked.

**Steps**

- [x] Navigate to https://owasp.glueup.com/.
- [x] Click on the “Login” option.
- [x] Enter a valid registered **email address**.
- [x] Enter the correct **password**.
- [x] Click on the **Login** or **Sign In** button.


**Expected Results**

- [x] User is successfully authenticated.
- [x] The system redirects the user to their dashboard or home page.
- [x] The session is created and remains active until logout or timeout.
- [x] No error messages are displayed.

### Evidence

@id TC-GLUE-001

```yaml META
cycle: 1.1
assignee: Emily Davis
status: passed
```

**Attachment**

- [Results JSON](../evidence/TC-GLUE-001/1.1/result.auto.json)
- [Run MD](../evidence/TC-GLUE-001/1.1/run.auto.md)


## Verify login failure due to network timeout despite correct credentials

@id TC-GLUE-002

```yaml HFM
doc-classify:
fii: TC-GLUE-002
requirementID: REQ-GLUE-01
priority: High
tags: ["Login", "Network Timeout", "Negative", "Resilience"]
scenario-type: Happy Path
```

**Description**

This test case validates that when a user attempts to log in with **valid credentials**, but the network connection becomes **unstable or times out** during the request, the system correctly handles the error without granting access. It ensures the application gracefully handles timeouts and maintains security by not allowing unintended login success.

**Preconditions**

- [x] User account already exists with valid credentials.
- [x] Access to the login page of [https://owasp.glueup.com/](https://owasp.glueup.com/).
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

### Evidence

@id TC-GLUE-002

```yaml META
cycle: 1.1
assignee: John Carter
status: 
issue_id: ["BUG-GLUE-001"]
```

**Attachment**

- [Results JSON](../evidence/TC-GLUE-002/1.1/result.auto.json)
- [Run MD](../evidence/TC-GLUE-002/1.1/run.auto..md)
- [Screenshot](../evidence/TC-GLUE-002/1.1/loginButtonClick.png)

**Issue**

```yaml HFM
doc-classify:
  role: issue
issue_id: BUG-GLUE-001
created_date: 12-18-2025
test_case_id: TC-GLUE-002
title: "Login fails with timeout error even when valid credentials are used"
status: open
```

**Issue Details**

- [Bug Details](https://github.com/surveilr/surveilr/issues/354)
- [Screenshot](../evidence/TC-GLUE-002/1.1/loginButtonClick.png)