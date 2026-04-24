---
FII: "TR-QUALITYFOLIO-002"
test_case_fii: "TC-QUALITYFOLIO-002"
run_date: "2026-04-21"
environment: "Production"
---

### Actual Result

1. Navigated to the login page successfully.
2. Entered valid user credentials into the email and password fields.
3. Simulated a network disconnection before submitting the form.
4. Clicked the Login button; the request timed out as expected.
5. Observed that the UI showed a loading state followed by a connection error.
6. After restoring the network and navigating to the dashboard URL, the system unexpectedly granted access to the protected area without requiring a new login attempt.

### Run Summary

- Status: Failed
- Notes: Steps 1 through 5 behaved as expected during the simulated network failure. However, Step 6 failed because the application did not properly invalidate the interrupted authentication attempt, allowing unauthorized access once the connection was restored.
