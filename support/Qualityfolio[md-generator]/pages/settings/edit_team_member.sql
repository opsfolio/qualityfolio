-- Edit team member page
SELECT 'hero' AS component,
       'Edit Team Member' AS title,
       'Update team member information' AS description;

-- Back Button
SELECT 'button' AS component, 'sm' AS size;
SELECT 'Back to Settings' AS title, '/settings.sql?tab=team_members' AS link, 'arrow-left' AS icon, 'outline-primary' AS color;

-- Edit form
SELECT 'form' AS component,
       'update_team_member.sql' AS action,
       'POST' AS method,
       'Submit' AS validate,
       'Edit Team Member' AS title;

-- Hidden field for ID
SELECT 'hidden' AS type,
       'edit_id' AS name,
       $id AS value;

SELECT 'Full Name' AS label,
       'full_name' AS name,
       'text' AS type,
       full_name AS value,
       TRUE AS required
FROM team_members WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);

SELECT 'Designation' AS label,
       'designation' AS name,
       'text' AS type,
       designation AS value
FROM team_members WHERE id = CAST(REPLACE(COALESCE($id, '0'), ',', '') AS INTEGER);
