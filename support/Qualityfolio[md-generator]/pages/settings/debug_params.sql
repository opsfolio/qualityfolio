SELECT 'table' AS component, 'Debug POST Parameters' AS title;
SELECT 'edit_id' AS Key, $edit_id AS Value;
SELECT 'name' AS Key, $name AS Value;
SELECT 'description' AS Key, $description AS Value;
SELECT 'id' AS Key, $id AS Value;

SELECT 'text' AS component, 'Raw contents of $ edit_id: ' || COALESCE($edit_id, 'NULL') AS contents;
