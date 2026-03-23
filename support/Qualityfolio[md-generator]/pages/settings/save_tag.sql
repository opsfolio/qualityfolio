-- Save tag handler
INSERT INTO tags (name, color)
VALUES (:name, '#3B82F6'); -- Default color blue

-- Redirect back to settings
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&success=Tag added successfully' AS link;
