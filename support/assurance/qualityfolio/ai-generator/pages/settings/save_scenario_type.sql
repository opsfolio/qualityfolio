-- Save scenario type handler
INSERT INTO scenario_types (name, description)
VALUES (:name, :description);

-- Redirect back to settings with scenario_types tab active
SELECT 'redirect' AS component,
       '/settings.sql?tab=scenario_types&success=Scenario type added successfully' AS link;
