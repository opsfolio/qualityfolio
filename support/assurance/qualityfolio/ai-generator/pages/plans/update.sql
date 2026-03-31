-- Action to update an existing Plan
UPDATE plans
SET 
    name = :plan_name,
    external_id = :external_id,
    plan_date = :plan_date,
    created_by_id = :plan_created_by,
    scope = :plan_scope
WHERE id = :plan_id;

SELECT 'redirect' AS component, 
       COALESCE(:redirect_url, 'plans.sql?project_id=' || :project_id) AS link;
