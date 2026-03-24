-- update_team_member.sql
-- Updates an existing team member. Called via POST from edit_team_member.sql form.
-- Fields: :edit_id (the record ID), :full_name, :designation

-- Guard: if edit_id is missing or zero, redirect with error
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Error:+Missing+member+ID' AS link
WHERE CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) = 0;

-- Perform the update (only runs when edit_id is valid)
UPDATE team_members
SET full_name   = TRIM(:full_name),
    designation = NULLIF(TRIM(COALESCE(:designation, '')), '')
WHERE id = CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER)
  AND CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0;

-- Redirect back with success
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Team+member+updated+successfully' AS link
WHERE CAST(REPLACE(COALESCE(:edit_id, '0'), ',', '') AS INTEGER) != 0;