-- Update scenario type handler
-- Using both named and dollar syntax to be absolutely sure we capture the value
SET _name = COALESCE(:name, $name);
SET _description = COALESCE(:description, $description);
SET _id = CAST(REPLACE(COALESCE(:edit_id, $edit_id, '0'), ',', '') AS INTEGER);

UPDATE scenario_types 
SET name = $_name,
    description = $_description
WHERE id = $_id;

-- Redirect back to settings with scenario_types tab active
SELECT 'redirect' AS component,
       '/settings.sql?tab=scenario_types&success=Scenario+type+updated+successfully+for+ID+' || $_id AS link;
