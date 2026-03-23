-- Save team member handler
INSERT INTO team_members (full_name, designation)
VALUES (:full_name, :designation);

-- Redirect back to settings
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Team member added successfully' AS link;
