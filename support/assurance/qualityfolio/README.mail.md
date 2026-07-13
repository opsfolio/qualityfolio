# Novu Mail Sending Module (Spryfile.mail.md)

This directory contains `Spryfile.mail.md`, which defines a reusable **Novu Mail Sending Module** for SQLPage. The module acts as a bridge between the SQLPage application and the **Novu notification infrastructure API**, allowing any SQL script to trigger email notifications programmatically.

---

## 1. How it Works

`Spryfile.mail.md` contains a single SQL code block that maps to the target path `fleetfolio/action/send-novu-email.sql`.

When compiled by the **Spry** builder, this markdown file is extracted and deployed:
1. As a physical SQL file at `dev-src.auto/fleetfolio/action/send-novu-email.sql` for the development server filesystem.
2. In the SQLite database `sqlpage_files` table under the path `fleetfolio/action/send-novu-email.sql` for production deployment.

### Required Environment Variables
The module relies on the following environment variables configured on your server (e.g. in your `.envrc` or system environment):
* `NOVU_API_KEY`: API authentication key for Novu.
* `NOVU_API_URL`: Root URL of the Novu API service (e.g., `https://api.novu.infra.opsfolio.com`).
* `NOVU_WORKFLOW_ID`: (Optional fallback) The default workflow/template trigger identifier in Novu.
* `NOVU_EMAIL`: (Optional fallback) The default sender email address.
* `RECIPIENT_EMAIL`: (Optional fallback) The default recipient email address.

---

## 2. Invocation Interface (API Parameters)

The module is called synchronously via SQLPage's `sqlpage.run_sql()` function. You pass parameters as a JSON object:

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `workflow_id` | String | Yes | Trigger identifier of the workflow/template registered in Novu. |
| `to` | String | Yes | Recipient email address. |
| `from` | String | No | Sender email address. Defaults to the `NOVU_EMAIL` env variable. |
| `subject` | String | Yes | Email subject header. |
| `content` | String | Yes | Dynamic message payload. Populates the `{{content}}`/`{{message}}` placeholder variables in Novu. |

---

## 3. How to Use in Other SQL Pages

To send an email from any other SQLPage script, follow these steps:

### Step A: Define your payload variables
Retrieve your data and build the text message using SQL operations.

### Step B: Call the SQL module
Invoke the runner with `sqlpage.run_sql()`, passing the JSON payload:

```sql
-- 1. Construct the message content
SET email_body = 'This is the main message text sent from SQLPage.';

-- 2. Call the Novu email sending script
SET send_result_array = sqlpage.run_sql(
  'fleetfolio/action/send-novu-email.sql',
  json_object(
    'workflow_id', 'qualityfolio-failed-test-case-reminder',
    'to', 'recipient@domain.com',
    'from', 'sender@domain.com',
    'subject', 'Notification Subject Line',
    'content', $email_body
  )
);
```

### Step C: Parse the response
The module returns a single row containing a JSON array. Extract the status and error details:

```sql
-- 3. Extract status and error message
SET send_status = json_extract($send_result_array, '$[0].status');
SET error_msg = json_extract($send_result_array, '$[0].error_message');

-- 4. Perform conditional redirects or display status alerts
SELECT 'redirect' AS component,
       '/target-page.sql?status=' || $send_status || '&message=' || sqlpage.url_encode($error_msg) AS link
WHERE $send_status = 'error';
```

---

## 4. Compilation & Build Integration

When adding new files or modifying `Spryfile.mail.md`, you need to recompile the project:

### Compile to filesystem (dev mode):
```bash
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md --md Spryfile.mail.md
```

### Deploy to SQLite database (production mode):
```bash
spry sp spc --package --conf sqlpage/sqlpage.json -m qualityfolio.md -m Spryfile.mail.md | sqlite3 resource-surveillance.sqlite.db
```
