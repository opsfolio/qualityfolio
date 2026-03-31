-- Save a new Plan

-- 1. Insert into plans
INSERT INTO plans (project_id, name, external_id, plan_date, created_by_id, description, scope)
SELECT 
    :project_id,
    :plan_name,
    :plan_id,
    :plan_date,
    :plan_created_by,
    'Manually created plan',
    :plan_scope
WHERE :project_id IS NOT NULL AND :plan_name IS NOT NULL;

-- 2. Redirect back to plans list
SELECT 'redirect' AS component,
       'plans.sql?project_id=' || :project_id AS link;
