-- upsert_tag.sql
-- Handles both INSERT (add) and UPDATE (edit) for tags from a single file.
-- Branches on :edit_id — if present and non-zero → UPDATE, otherwise → INSERT.
-- Duplicate names are blocked case-insensitively on both branches.
--
-- Expected POST parameters:
--   :edit_id  (optional) — the record ID when editing; absent or "0" for new records
--   :name     (required) — the tag name

-- ============================================================
-- BRANCH: UPDATE (edit_id is present and non-zero)
-- ============================================================

-- Guard: edit_id supplied but resolves to 0 — treat as bad request
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&error=Error:+Missing+tag+ID' AS link
WHERE COALESCE(:edit_id, '') != ''
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) = 0;

-- Duplicate check for UPDATE — block if another record (not this one) already has the same name
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&error=Tag+already+exists' AS link
WHERE COALESCE(:edit_id, '') != ''
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0
  AND EXISTS (
    SELECT 1 FROM tags
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
      AND id != CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER)
  );

-- Perform the UPDATE (only when no duplicate exists)
UPDATE tags
SET name = TRIM(:name)
WHERE id = CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER)
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0
  AND NOT EXISTS (
    SELECT 1 FROM tags
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
      AND id != CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER)
  );

-- Redirect with success after UPDATE
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&success=Tag+updated+successfully' AS link
WHERE COALESCE(:edit_id, '') != ''
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0
  AND (SELECT changes() > 0);

-- ============================================================
-- BRANCH: INSERT (edit_id is absent or empty)
-- ============================================================

-- Duplicate check — redirect with error if name already exists
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&error=Tag+already+exists' AS link
WHERE COALESCE(:edit_id, '') = ''
  AND EXISTS (
    SELECT 1 FROM tags
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
  );

-- Insert new record with default color (only when no duplicate exists)
INSERT INTO tags (name, color)
SELECT TRIM(:name), '#3B82F6'
WHERE COALESCE(:edit_id, '') = ''
  AND NOT EXISTS (
    SELECT 1 FROM tags
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(:name))
  );

-- Redirect with success after INSERT
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&success=Tag+added+successfully' AS link
WHERE COALESCE(:edit_id, '') = ''
  AND (SELECT changes() > 0);