-- Save test type handler
INSERT INTO test_types (name, description)
VALUES (:name, :description);

-- Redirect back to settings with test_types tab active
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_types&success=Test type added successfully' AS link;
