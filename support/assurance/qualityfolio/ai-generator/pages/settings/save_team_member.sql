-- save_team_member.sql
-- Inserts a new team member. Called via POST from the Add Member modal form.
-- Fields: :full_name, :designation

INSERT INTO team_members (full_name, designation)
VALUES (:full_name, NULLIF(TRIM(COALESCE(:designation, '')), ''));

-- Redirect back to team members tab with success message
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Team+member+added+successfully' AS link;