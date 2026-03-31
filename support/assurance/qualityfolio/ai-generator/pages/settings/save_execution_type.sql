-- Save execution type handler
INSERT INTO execution_types (name, description)
VALUES (:name, :description);

-- Redirect back to settings with execution_types tab active
SELECT 'redirect' AS component,
       '/settings.sql?tab=execution_types&success=Execution type added successfully' AS link;
