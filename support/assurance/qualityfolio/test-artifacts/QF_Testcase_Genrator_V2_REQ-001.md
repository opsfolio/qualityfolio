---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: case
  - select: heading[depth="3"]
    role: evidence
---

# QF Testcase Genrator V22222

@id qf-testcase-genrator-v2-project

The QF Testcase Genrator V2 project aims to validate the functionality of the forgot password feature, ensuring it is secure, efficient, and user-friendly.

**Objectives**

- Validate forgot password functionality
- Ensure security and efficiency

**Risks**

- Security vulnerabilities
- User experience issues

**Requirements**

The system shall provide a "Forgot Password" functionality that enables users to recover their password in a secure and efficient manner. 

1. The system shall display a "Forgot Password" link on the login page, allowing users to initiate the password recovery process.
2. Upon clicking the "Forgot Password" link, the system shall prompt the user to enter their registered username or email address associated with their account.
3. The system shall verify the user's identity by sending a password recovery email to the registered email address, which shall contain a unique password reset link or code.
4. The password recovery email shall be sent to the user's registered email address within a reasonable timeframe, not exceeding 5 minutes.
5. The password reset link or code shall be valid for a limited period, not exceeding 30 minutes, to prevent unauthorized access.
6. Upon clicking the password reset link or entering the code, the system shall direct the user to a password reset page where they can enter a new password.
7. The system shall enforce password complexity rules, including a minimum length of 8 characters, at least one uppercase letter, one lowercase letter, one number, and one special character.
8. The system shall allow users to reset their password only once within a 24-hour period to prevent brute-force attacks.
9. The system shall log all password reset attempts, including successful and unsuccessful attempts, for auditing and security purposes.
10. The system shall notify the user via email upon successful password reset, confirming their new password has been updated.
11. The system shall ensure that the password recovery process is accessible and usable on various devices, including desktops, laptops, tablets, and mobile phones.
12. The system shall provide clear instructions and feedback to the user throughout the password recovery process to ensure a smooth and user-friendly experience.

---

## Verify that the forgot password link is displayed on the login page.

@id TC-qf-testcase-genrator-v2-0001

```yaml HFM
  requirementID: REQ-001
  Priority: High
  Tags: ["Functional","UI"]
  Scenario Type: Edge Case
  Execution Type: Manual
```

**Description**

This test case verifies the presence of the forgot password link on the login page.

**Preconditions**

- [x] User is on the login page

**Steps**

- [x] 1. Navigate to the login page
- [x] 2. Verify the forgot password link is displayed

**Expected Results**

- [x] The forgot password link is displayed on the login page.

### Evidence

@id TC-qf-testcase-genrator-v2-0001

```yaml META
  cycle: 1.0
  cycle-date: 2026-04-07
  severity: High
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-qf-testcase-genrator-v2-0001/1.0/result.auto.json)
- [Screenshot](./evidence/TC-qf-testcase-genrator-v2-0001/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-qf-testcase-genrator-v2-0001/1.0/run.auto.md)

---

## Ensure that the password recovery email is sent to the registered email address within 5 minutes.

@id TC-qf-testcase-genrator-v2-0002

```yaml HFM
  requirementID: REQ-001
  Priority: Medium
  Tags: ["Functional","API"]
  Scenario Type: Functional
  Execution Type: Automation
```

**Description**

This test case verifies the password recovery email is sent to the registered email address within the specified timeframe.

**Preconditions**

- [x] User has a registered email address
- [x] User initiates the password recovery process

**Steps**

- [x] 1. Initiate the password recovery process
- [x] 2. Verify the password recovery email is sent within 5 minutes

**Expected Results**

- [x] The password recovery email is sent to the registered email address within 5 minutes.

### Evidence

@id TC-qf-testcase-genrator-v2-0002

```yaml META
  cycle: 1.0
  cycle-date: 04-07-2026
  severity: Medium
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-qf-testcase-genrator-v2-0002/1.0/result.auto.json)
- [Screenshot](./evidence/TC-qf-testcase-genrator-v2-0002/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-qf-testcase-genrator-v2-0002/1.0/run.auto.md)

---

## Validate that the password reset link is valid for only 30 minutes and enforces password complexity rules.

@id TC-qf-testcase-genrator-v2-0003

```yaml HFM
  requirementID: REQ-001
  Priority: High
  Tags: ["Functional","Security"]
  Scenario Type: Functional
  Execution Type: Manual
```

**Description**

This test case verifies the password reset link is valid for only 30 minutes and enforces password complexity rules.

**Preconditions**

- [x] User has received the password recovery email
- [x] User clicks the password reset link

**Steps**

- [x] 1. Click the password reset link
- [x] 2. Verify the link is valid for only 30 minutes
- [x] 3. Verify password complexity rules are enforced

**Expected Results**

- [x] The password reset link is valid for only 30 minutes and enforces password complexity rules.

### Evidence

@id TC-qf-testcase-genrator-v2-0003

```yaml META
  cycle: 1.0
  cycle-date: 04-07-2026
  severity: High
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-qf-testcase-genrator-v2-0003/1.0/result.auto.json)
- [Screenshot](./evidence/TC-qf-testcase-genrator-v2-0003/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-qf-testcase-genrator-v2-0003/1.0/run.auto.md)

---

## Check that the system logs all password reset attempts, including successful and unsuccessful attempts.

@id TC-qf-testcase-genrator-v2-0004

```yaml HFM
  requirementID: REQ-001
  Priority: Low
  Tags: ["Functional","Security"]
  Scenario Type: Functional
  Execution Type: Automation
```

**Description**

This test case verifies the system logs all password reset attempts.

**Preconditions**

- [x] User initiates the password recovery process

**Steps**

- [x] 1. Initiate the password recovery process
- [x] 2. Verify the system logs the attempt

**Expected Results**

- [x] The system logs all password reset attempts, including successful and unsuccessful attempts.

### Evidence

@id TC-qf-testcase-genrator-v2-0004

```yaml META
  cycle: 1.0
  cycle-date: 04-07-2026
  severity: Low
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-qf-testcase-genrator-v2-0004/1.0/result.auto.json)
- [Screenshot](./evidence/TC-qf-testcase-genrator-v2-0004/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-qf-testcase-genrator-v2-0004/1.0/run.auto.md)

---

## Confirm that the password recovery process is accessible and usable on various devices, including desktops, laptops, tablets, and mobile phones.

@id TC-qf-testcase-genrator-v2-0005

```yaml HFM
  requirementID: REQ-001
  Priority: Medium
  Tags: ["Functional","UI"]
  Scenario Type: Functional
  Execution Type: Manual
```

**Description**

This test case verifies the password recovery process is accessible and usable on various devices.

**Preconditions**

- [x] User has a registered email address
- [x] User initiates the password recovery process

**Steps**

- [x] 1. Initiate the password recovery process on various devices
- [x] 2. Verify the process is accessible and usable

**Expected Results**

- [x] The password recovery process is accessible and usable on various devices, including desktops, laptops, tablets, and mobile phones.

### Evidence

@id TC-qf-testcase-genrator-v2-0005

```yaml META
  cycle: 1.0
  cycle-date: 04-07-2026
  severity: Medium
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-qf-testcase-genrator-v2-0005/1.0/result.auto.json)
- [Screenshot](./evidence/TC-qf-testcase-genrator-v2-0005/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-qf-testcase-genrator-v2-0005/1.0/run.auto.md)

---

