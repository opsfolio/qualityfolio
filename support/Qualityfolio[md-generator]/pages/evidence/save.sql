-- Save new Evidence
INSERT INTO evidence (test_case_id, title, content, attachments)
VALUES (
    :test_case_id,
    :title,
    :content,
    :attachments
);

SELECT 'redirect' AS component, 
       'evidence.sql?test_case_id=' || :test_case_id || '&project_id=' || :project_id || '&suite_id=' || COALESCE(:suite_id, '') AS link;
