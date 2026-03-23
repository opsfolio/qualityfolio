---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: case
  - select: heading[depth="3"]
    role: evidence
---

# QF_Test

@id qf_test-project

The QF_Test project aims to validate the functionality of the Forgot Password feature in an enterprise application, ensuring that users can recover their account access securely and efficiently.

**Objectives**

- Validate the Forgot Password feature
- Ensure security and efficiency

**Risks**

- Security vulnerabilities
- User frustration

**Requirements**

The system shall provide a "Forgot Password" feature that enables users to recover their account access when they have forgotten their password. 

1. The system shall display a "Forgot Password" link on the login page, allowing users to initiate the password recovery process.
2. Upon clicking the "Forgot Password" link, the system shall prompt the user to enter their username or email address associated with their account.
3. The system shall verify the user's identity by sending a password recovery email to the email address associated with the provided username or email address.
4. The password recovery email shall contain a unique password reset link that expires after a predetermined period, such as 30 minutes.
5. The system shall allow the user to reset their password by clicking on the password reset link and entering a new password that meets the system's password complexity requirements.
6. The system shall enforce password complexity requirements, including a minimum length, at least one uppercase letter, at least one lowercase letter, at least one number, and at least one special character.
7. The system shall store passwords securely using a salted hashing algorithm and shall not store passwords in plaintext.
8. The system shall provide feedback to the user upon successful password reset, such as a confirmation message or email.
9. The system shall log all password reset attempts, including successful and unsuccessful attempts, for auditing and security purposes.
10. The system shall limit the number of password reset attempts within a certain time frame to prevent brute-force attacks.

---

## Verify that a user can initiate the password recovery process using the Forgot Password link on the login page

@id TC-0001

```yaml HFM
  requirementID: REQ-001
  Priority: High
  Tags: ["Functional","Regression"]
  Scenario Type: Functional
  Execution Type: Manual
```

**Description**

This test case verifies that the Forgot Password link is visible and clickable on the login page, allowing users to start the password recovery process.

**Preconditions**

- [x] The user is on the login page
- [x] The user has a valid account

**Steps**

- [x] 1. Click on the Forgot Password link
- [x] 2. Enter a valid username or email address
- [x] 3. Click on the Submit button

**Expected Results**

- [x] The system displays a password recovery email sent confirmation message

### Evidence

@id TC-0001

```yaml META
  cycle: 1.0
  cycle-date: 03-19-2026
  severity: High
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-0001/1.0/result.auto.json)
- [Screenshot](./evidence/TC-0001/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-0001/1.0/run.auto.md)

---

## Ensure that the system sends a password recovery email to the user's registered email address with a unique password reset link

@id TC-0002

```yaml HFM
  requirementID: REQ-001
  Priority: Medium
  Tags: ["Functional","API"]
  Scenario Type: Functional
  Execution Type: Automated
```

**Description**

This test case ensures that the system sends a password recovery email with a unique password reset link to the user's registered email address.

**Preconditions**

- [x] The user has initiated the password recovery process
- [x] The user has a valid email address

**Steps**

- [x] 1. Initiate the password recovery process
- [x] 2. Verify that an email is sent to the user's registered email address

**Expected Results**

- [x] The email contains a unique password reset link that expires after a predetermined period

### Evidence

@id TC-0002

```yaml META
  cycle: 1.0
  cycle-date: 03-19-2026
  severity: Medium
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-0002/1.0/result.auto.json)
- [Screenshot](./evidence/TC-0002/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-0002/1.0/run.auto.md)

---

## Validate that the system enforces password complexity requirements during the password reset process

@id TC-0003

```yaml HFM
  requirementID: REQ-001
  Priority: High
  Tags: ["Functional","Security"]
  Scenario Type: Boundarys
  Execution Type: Manual
```

**Description**

This test case validates that the system enforces password complexity requirements, including minimum length, uppercase letters, lowercase letters, numbers, and special characters.

**Preconditions**

- [x] The user is on the password reset page
- [x] The user has a valid account

**Steps**

- [x] 1. Enter a new password that does not meet the complexity requirements
- [x] 2. Click on the Submit button

**Expected Results**

- [x] The system displays an error message indicating that the password does not meet the complexity requirements

### Evidence

@id TC-0003

```yaml META
  cycle: 1.0
  cycle-date: 03-19-2026
  severity: High
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-0003/1.0/result.auto.json)
- [Screenshot](./evidence/TC-0003/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-0003/1.0/run.auto.md)

---

## Check that the system logs all password reset attempts, including successful and unsuccessful attempts, for auditing and security purposes

@id TC-0004

```yaml HFM
  requirementID: REQ-001
  Priority: Low
  Tags: ["Security","Regression"]
  Scenario Type: Negative
  Execution Type: Automated
```

**Description**

This test case checks that the system logs all password reset attempts, including successful and unsuccessful attempts, to ensure auditing and security.

**Preconditions**

- [x] The user has initiated the password recovery process
- [x] The system has logging enabled

**Steps**

- [x] 1. Initiate the password recovery process
- [x] 2. Verify that the system logs the attempt

**Expected Results**

- [x] The system logs the password reset attempt with the corresponding status

### Evidence

@id TC-0004

```yaml META
  cycle: 1.0
  cycle-date: 03-19-2026
  severity: Low
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-0004/1.0/result.auto.json)
- [Screenshot](./evidence/TC-0004/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-0004/1.0/run.auto.md)

---

## Confirm that the system limits the number of password reset attempts within a certain time frame to prevent brute-force attacks

@id TC-0005

```yaml HFM
  requirementID: REQ-001
  Priority: Critical
  Tags: ["Security","Smoke"]
  Scenario Type: Negative
  Execution Type: Automated
```

**Description**

This test case confirms that the system limits the number of password reset attempts within a certain time frame to prevent brute-force attacks.

**Preconditions**

- [x] The user has initiated the password recovery process
- [x] The system has rate limiting enabled

**Steps**

- [x] 1. Initiate multiple password recovery attempts within a short time frame
- [x] 2. Verify that the system blocks further attempts

**Expected Results**

- [x] The system displays an error message indicating that the password reset attempts are temporarily blocked

### Evidence

@id TC-0005

```yaml META
  cycle: 1.0
  cycle-date: 03-19-2026
  severity: Critical
  assignee: Ajesh Jose
  status: To-do
```

**Attachments**

- [Result JSON](./evidence/TC-0005/1.0/result.auto.json)
- [Screenshot](./evidence/TC-0005/1.0/screenshot.auto.png)
- [Run MD](./evidence/TC-0005/1.0/run.auto.md)

---

