---
doc-classify:
  - select: heading[depth="1"]
    role: project
  - select: heading[depth="2"]
    role: suite
  - select: heading[depth="3"]
    role: plan
  - select: heading[depth="4"]
    role: case
---

# E2E1 End-to-End Qualityfolio

This project validates the full customer journey: account creation →
authentication → cart → checkout → order confirmation → notifications →
integrations.

Objectives:

- Prove the golden path works across environments
- Catch cross-service regressions early
- Generate compliance-grade evidence automatically

Risks:

- Flaky external integrations
- MFA edge cases
- Data consistency across services

## Accounts & Auth E2E Suite

End-to-end user lifecycle: sign-up, verify, login, MFA, password reset.

### E2E Account Creation Plan

@id acct-create-plan

```yaml HFM
doc-classify:
  - role: requirement
    tags: ["one", "two"]
owner: "[riya@example.org](mailto:riya@example.org)"
objective: Sign-up → login → profile bootstrap
```

Validates account creation flows and first-time login.

#### New user can sign up and verify email

A new user signs up, receives a verification email, verifies, and logs in.

@id acct-signup-verify-case

**Preconditions**

- Mail sandbox configured in QA
- Unique test email available

**Steps**

1.
   - [x] Open `/signup`
   - [x] Fill valid user details and submit
   - [x] Receive verification email (link visible in sandbox UI)
   - [x] Click verification link; account marked verified
   - [x] Login with the newly verified user

**Expected**

- [x] Verification email delivered within 60s
- [x] Verification flips `isVerified=true`
- [x] Login succeeds post verification

**Evidence**

- [Signup run log](./evidence/acct-signup-verify-run.md)
- [Verification email JSON](./evidence/acct-signup-verify-email.json)
- ![Signup page](./evidence/acct-signup-verify.png)

#### Returning user can login with MFA

Returning user logs in with valid credentials and completes MFA.

**Preconditions**

- User exists with MFA seeded in QA

**Steps**

- [x] Navigate to `/login`
- [x] Enter valid credentials → see MFA prompt
- [x] Provide valid MFA code
- [x] Redirect to `/home`

**Expected**

- [x] MFA required for this user
- [x] Session cookie set; CSRF token present
- [x] Home shows user display name

**Evidence**

- [Results JSON](./evidence/acct-login-mfa-results.json)
- [MFA prompt screenshot](./evidence/acct-login-mfa.png)

### Password Recovery Plan

Focuses on lockout and reset flows.

```yaml HFM
id: pwd-recovery-plan
nature: { "role": "expectation" }
owner: "[riya@example.org](mailto:riya@example.org)"
objective: Lockout policy & reset email
```

#### Lockout after repeated failures

Repeated failed logins trigger a lockout; valid login blocked until lockout
expires.

```yaml META
id: acct-lockout-case
severity: critical
env: qa
```

**Preconditions**

- Policy: 5 failed attempts → lock for 15 minutes

**Steps**

- [x] Attempt invalid password 5 times
- [x] Observe lockout message
- [ ] Attempt valid credentials during lockout

**Expected**

- [x] Lockout activates on 5th failure
- [ ] Valid credentials rejected during active lockout

**Evidence**

- [Lockout logs](./evidence/acct-lockout-log.txt)
- ![Lockout UI](./evidence/acct-lockout.png)

```json5
{
  "notes": "Known intermittent: rate limiter delays message in <1% runs",
  "linked_issues": ["AUTH-117"]
}
```

---

## Checkout E2E Suite

Cart → address → shipping → payment → confirmation.

### E2E Happy Path Checkout Plan

Covers a signed-in user purchasing a shippable item with saved address and card.

@objective Golden path: single item → card → confirmation

#### Signed-in user can complete checkout with saved card

User with existing address and saved card completes purchase successfully.

**Preconditions**

- User is signed in
- One item already in cart
- Address and card on file

**Steps**

- [x] Open `/cart` and proceed to checkout
- [x] Confirm shipping address
- [x] Choose standard shipping
- [x] Choose saved card
- [x] Submit order

**Expected**

- [x] Order accepted (HTTP 201)
- [x] Confirmation page shows order number
- [x] Inventory decremented accordingly

**Evidence**

- [Order API response](./evidence/checkout-saved-card-order.json)
- [Confirmation screenshot](./evidence/checkout-saved-card-confirm.png)

#### Guest user can checkout with credit card

Guest user purchases without creating an account.

**Preconditions**

- Cart contains at least one shippable item

**Steps**

- [x] Proceed as guest from `/cart`
- [x] Enter shipping address
- [x] Enter email for receipt
- [x] Enter valid card details
- [ ] Submit order

**Expected**

- [x] Order accepted (HTTP 201)
- [ ] Confirmation email sent to guest email

**Evidence**

- [Guest order response](./evidence/checkout-guest-card.json)
- [Payment gateway transcript](./evidence/checkout-guest-card-gateway.json)

```yaml
issue:
  - CHECKOUT-231
notes: "Intermittent 502 from payment sandbox observed 2025-11-08"
```

### E2E Edge Cases & Resilience Plan

Retries, partial failures, and recovery.

#### Payment gateway transient failure triggers retry

**Preconditions**

- Payment sandbox configured to return 500 on first attempt, 200 on second

**Steps**

- [x] Initiate payment
- [x] Observe initial 5xx
- [x] System retries automatically
- [x] Second attempt succeeds; order recorded

**Expected**

- [x] Exactly one retry attempted
- [x] No double charge in ledger
- [x] Order placed with single transaction id

**Evidence**

- [Gateway attempts JSON](./evidence/checkout-retry-gateway-attempts.json)
- [Ledger check screenshot](./evidence/checkout-ledger.png)

---

## Notifications & Integrations E2E Suite

Post-order communications and third-party hooks.

### E2E Notifications Plan

Order confirmation emails and webhooks.

#### Confirmation email sent to customer

**Preconditions**

- Mail sandbox active
- Successful order id available

**Steps**

- [x] Trigger order placement (reuse happy path)
- [x] Poll mail sandbox for confirmation
- [ ] Validate subject and body contain order number

**Expected**

- [x] Email delivered within 60s
- [ ] Subject includes order id; body has correct totals

**Evidence**

- [Email JSON](./evidence/notify-email.json)
- ![Email screenshot](./evidence/notify-email.png)

#### Webhook is delivered to partner system exactly once

A single webhook should be POSTed to the partner with correct signature.

**Preconditions**

- Partner webhook mock running and capturing requests

**Steps**

- [x] Place order
- [x] Receive webhook at partner mock
- [x] Validate HMAC signature
- [x] Ensure no duplicate deliveries

**Expected**

- [x] Status 200 from partner mock
- [x] Signature valid
- [x] Exactly one delivery for the order

**Evidence**

- [Partner mock log](./evidence/notify-webhook-log.txt)
- [Signature check JSON](./evidence/notify-webhook-sig.json)

---

## Operational Observability E2E Suite

SLIs/SLOs around E2E flows.

### E2E Latency & Error Budget Plan

Stay within latency SLO and error budget, measures end-to-end latency and error
rates for golden paths.

#### Golden path latency under 3s P95

**Preconditions**

- Load generator targets prod-like environment
- Baseline SLO P95 <= 3000ms

**Steps**

- [x] Run k6 scenario for 10 minutes
- [x] Collect traces and metrics
- [x] Compute P95 latency for flow

**Expected**

- [x] P95 < 3000ms
- [x] Error rate < 0.1%

**Evidence**

- [k6 summary JSON](./evidence/obs-latency-p95-k6.json)
- [Trace report](./evidence/obs-latency-p95-traces.json)
