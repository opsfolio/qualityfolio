---
FII: "TR-CMMC-0005"
test_case_fii: "TC-CMMC-0005"
run_date: "2025-11-10"
environment: "Production"
---

### Run Summary

- Status: Failed
- Notes: Errors encountered:\
  Step 4: Error: [31mExpected readiness percentage to be 100%, but received
  88%. Readiness bar did not update correctly after completing all
  sections.[39m

  Locator: locator('#readiness-percentage')\
  Expected value: [32m"100%"[39m\
  Received value: [31m"88%"[39m\
  Call log:\
  [2m - expect.toHaveText with timeout 5000ms[22m\
  [2m - waiting for locator('#readiness-percentage')[22m\
  [2m 4 × locator resolved to <div id="readiness-percentage">88%</div>[22m\
  [2m - unexpected percentage value "88%"[22m
