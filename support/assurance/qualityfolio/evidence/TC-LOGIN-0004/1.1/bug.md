---
issue_id: BUG-OPS-001
test_case_id: TC-LOGIN-0004
title: "Login fails due to network timeout on Opsfolio login page"
---

**Description**

When users attempt to log in to **Opsfolio** using valid credentials, the
authentication process fails due to a **network timeout**. Instead of displaying
a clear “Network Timeout” message or retrying the request, the system shows a
generic failure message, leading to confusion about whether the issue is
credential-related or network-related.

**Steps**

1. Navigate to [https://opsfolio.com/login/](https://opsfolio.com/login/).
2. Enter valid username and password.
3. Initiate login and simulate slow or intermittent network connectivity.
4. Observe the system’s behavior and any displayed error messages.

**Expected Result**

1. The system should display a clear and user-friendly **“Network Timeout”**
   message.
2. Application should **retry the authentication request** or allow the user to
   retry manually.
3. The user should not see misleading messages such as “Invalid credentials.”
4. The application should handle timeouts gracefully without breaking session
   flow.

**Actual Result**

1. Login attempt fails when the network connection is delayed or unstable.
2. The system displays a generic “Login failed” or “Invalid credentials”
   message.
3. User is unable to log in even with valid credentials, and no retry or timeout
   message is shown.

**Attachment**

- screenshot: [network-error.png](./network-error.png)
