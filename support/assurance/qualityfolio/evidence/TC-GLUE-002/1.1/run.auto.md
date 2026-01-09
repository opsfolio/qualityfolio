---
FII: "TR-GLUE-002"
test_case_fii: "TC-GLUE-002"
run_date: "2025-10-30"
environment: "Production"
---

### Actual Result

1. The system rejected each invalid password with a clear error message such as:  
   - “Password must be at least 8 characters long.”  
   - “Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.”  
2. Login or registration was not allowed until the password met the criteria.

### Run Summary

- Status: Failed  
- Notes: The system unexpectedly allowed access after reconnection during network timeout recovery.
