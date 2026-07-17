# Novu Mail Sending Module

```sql fleetfolio/action/send-novu-email.sql
-- @route.description "Send email notification using Novu API (reusable module)"

-- 1. Extract parameters
SET local_workflow_id = COALESCE($workflow_id, :workflow_id);
SET local_to_email = COALESCE($to, :to, $to_email, :to_email);
SET local_from_email = COALESCE($from, :from, $from_email, :from_email);
SET local_subject = COALESCE($subject, :subject);
SET local_content = COALESCE($content, :content);
SET local_asset_id = COALESCE($asset_id, :asset_id, $assetId, :assetId);

SET local_api_key = sqlpage.environment_variable('NOVU_API_KEY');
SET local_api_url = sqlpage.environment_variable('NOVU_API_URL');

-- 2. Determine missing parameters for error reporting
SET missing_param = (
  SELECT CASE
    WHEN $local_workflow_id IS NULL THEN 'workflow_id'
    WHEN $local_to_email IS NULL THEN 'to (recipient email)'
    WHEN $local_subject IS NULL THEN 'subject'
    WHEN $local_content IS NULL THEN 'content'
    WHEN $local_api_key IS NULL THEN 'NOVU_API_KEY'
    WHEN $local_api_url IS NULL THEN 'NOVU_API_URL'
    ELSE NULL
  END
);

-- 3. Execute HTTP request via curl (only if all parameters are valid)
-- We use sqlpage.exec with curl because SQLPage's built-in sqlpage.fetch can fail with HTTP/2 "connection error received: not a result of an error" on certain servers.
SET fetch_result = (
  SELECT sqlpage.exec(
    'curl',
    '-s',
    '-X', 'POST',
    '-H', 'Content-Type: application/json',
    '-H', 'Authorization: ApiKey ' || $local_api_key,
    '-d', json_object(
      'name', $local_workflow_id,
      'to', json_object(
        'subscriberId', $local_to_email,
        'email', $local_to_email
      ),
      'payload', json_object(
        'subject', $local_subject,
        'content', $local_content,
        'message', $local_content,  -- fallback for templates expecting message
        'from', $local_from_email,
        'assetId', $local_asset_id
      )
    ),
    $local_api_url || '/v1/events/trigger'
  )
  WHERE $missing_param IS NULL
);

-- 5. Extract errors/acknowledgements
SET acknowledged = (
  SELECT COALESCE(json_extract($fetch_result, '$.data.acknowledged'), 0) = 1
  WHERE $fetch_result IS NOT NULL
);

SET error_msg = (
  SELECT CASE
    WHEN $local_workflow_id IS NULL THEN
      'workflow_id parameter is not set.'
    WHEN $local_to_email IS NULL THEN
      'recipient email (to) parameter is not set.'
    WHEN $local_subject IS NULL THEN
      'subject parameter is not set.'
    WHEN $local_content IS NULL THEN
      'content parameter is not set.'
    WHEN $local_api_key IS NULL THEN
      'NOVU_API_KEY environment variable is not set on the server.'
    WHEN $local_api_url IS NULL THEN
      'NOVU_API_URL environment variable is not set on the server.'
    WHEN $fetch_result IS NULL THEN
      'Failed to execute HTTP request to Novu API.'
    WHEN NOT $acknowledged THEN
      COALESCE(
        json_extract($fetch_result, '$.message'),
        json_extract($fetch_result, '$.error'),
        $fetch_result,
        'Failed to trigger email.'
      )
    ELSE NULL
  END
);

-- 6. Return response row
SELECT 
  CASE WHEN $error_msg IS NULL THEN 'success' ELSE 'error' END AS status,
  $error_msg AS error_message,
  $fetch_result AS fetch_result;
```
