-- Save category handler
INSERT INTO categories (name, description)
VALUES (:name, :description);

-- Redirect back to settings
SELECT 'redirect' AS component,
       '/settings.sql?success=Category added successfully' AS link;
