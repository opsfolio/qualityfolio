-- Confirm Deletion of Project
SELECT 'shell' AS component,
       'Delete Project' AS title,
       'logo.png' AS image,
       '/' AS link,
       'Rahul Raj' AS user_name,
       true AS fluid,
        json_array(
            json_object('title', 'Project', 'link', 'entries.sql', 'icon', 'folder'),
            json_object('title', 'Settings', 'link', 'settings.sql', 'icon', 'settings')
        ) AS menu_item;

SELECT 'redirect' AS component, 'entries.sql' AS link WHERE $id IS NULL;

-- Warning Hero
SELECT 'hero' AS component,
       'Delete Project?' AS title,
       'Are you sure you want to delete project: **' || (SELECT name FROM projects WHERE id = $id) || '**? This action cannot be undone.' AS description;

-- Confirmation Form (simulated with buttons)
SELECT 'form' AS component,
       '/pages/projects/confirm_delete.sql' AS action,
       'Yes, Delete Project' AS validate,
       'Confirm Deletion' AS title;
       
SELECT 'id' AS name, 'hidden' AS type, $id AS value;

SELECT 'alert' AS component,
       'danger' AS color,
       'Warning' AS title,
       'This will permanently delete the project and all its associatedPlans, Suites, Test Cases, and Evidence.' AS description;
