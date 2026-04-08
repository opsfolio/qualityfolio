-- upsert_status.sql
-- Handles both INSERT (add) and UPDATE (edit) for test case statuses from a single file.
-- Branches on :edit_id — if present and non-zero → UPDATE, otherwise → INSERT.
--
-- Expected POST parameters:
--   :edit_id  (optional) — the record ID when editing; absent or "0" for new records
--   :name     (required) — the status name

-- ============================================================
-- BRANCH: UPDATE (edit_id is present and non-zero)
-- ============================================================

-- Guard: edit_id supplied but resolves to 0 — treat as bad request
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_case_statuses&error=Error:+Missing+status+ID' AS link
WHERE COALESCE(:edit_id, '') != ''
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) = 0;

-- Duplicate check for UPDATE — block if another record (not this one) already has the same name
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_case_statuses&error=Status+already+exists' AS link
WHERE COALESCE(:edit_id, '') != ''
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0
  AND EXISTS (
    SELECT 1 FROM test_case_statuses
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
      AND id != CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER)
  );

-- Perform the UPDATE (only when no duplicate exists)
UPDATE test_case_statuses
SET name = TRIM(:name)
WHERE id = CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER)
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0
  AND NOT EXISTS (
    SELECT 1 FROM test_case_statuses
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
      AND id != CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER)
  );

-- Redirect with success after UPDATE
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_case_statuses&success=Status+updated+successfully' AS link
WHERE COALESCE(:edit_id, '') != ''
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0
  AND (SELECT changes() > 0);

-- ============================================================
-- BRANCH: INSERT (edit_id is absent or empty)
-- ============================================================

-- Duplicate check — redirect with error if name already exists
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_case_statuses&error=Status+already+exists' AS link
WHERE COALESCE(:edit_id, '') = ''
  AND EXISTS (
    SELECT 1 FROM test_case_statuses
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
  );

-- Insert new record (only when no duplicate exists)
INSERT INTO test_case_statuses (name)
SELECT TRIM(:name)
WHERE COALESCE(:edit_id, '') = ''
  AND NOT EXISTS (
    SELECT 1 FROM test_case_statuses
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
  );

-- Redirect with success after INSERT
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_case_statuses&success=Status+added+successfully' AS link
WHERE COALESCE(:edit_id, '') = ''
  AND (SELECT changes() > 0);