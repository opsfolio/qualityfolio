UPDATE evidence
    SET title = :title,
    content = :content,
    attachments = :attachments
WHERE id = :id;

SELECT 'redirect' AS component, 'evidence.sql?test_case_id=' || :test_case_id || '&project_id=' || :project_id || '&suite_id=' || COALESCE(:suite_id, '') AS link;
