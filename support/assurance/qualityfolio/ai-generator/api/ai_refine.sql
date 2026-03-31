-- AI Refine Requirement Details
-- Input: requirement_text
-- Output: JSON { "refined_text": "..." }

SET requirements = COALESCE(:requirement_text, '');

-- Build prompt
SET prompt = 'You are a QA expert. Refine the following Requirement Details and organize it into these three specific sections:

** Requirement Scope**
(High-level summary of what is in scope)

** Functional Requirements**
(Bulleted list of specific behaviors)

** Acceptance Criteria**
(Bulleted list of verifiable criteria)

Input Text:
' || $requirements || '

Return the result in clear Markdown format. 
IMPORTANT: Use "** " as the header prefix and "**" as the suffix for the three sections above (e.g., ** Requirement Scope**). Do NOT use "###" or other markdown headers. Do not add any other introductory text.';

-- Call AI API
SET api_key = COALESCE(
    sqlpage.environment_variable('API_KEY'), 
    sqlpage.environment_variable('GROQ_API_KEY'), 
    sqlpage.environment_variable('GEMINI_API_KEY')
);
SET api_endpoint = COALESCE(
    sqlpage.environment_variable('ANTIGRAVITY_API_ENDPOINT'),
    'https://api.groq.com/openai/v1/chat/completions'
);
SET is_groq = CASE WHEN $api_endpoint LIKE '%groq.com%' THEN 1 ELSE 0 END;
SET api_model = COALESCE(sqlpage.environment_variable('GROQ_MODEL'), 'llama-3.3-70b-versatile');

SET api_response = CASE 
    WHEN $is_groq = 1 THEN
        sqlpage.fetch(json_object(
            'url', $api_endpoint,
            'method', 'POST',
            'headers', json_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || $api_key
            ),
            'body', json_object(
                'model', $api_model,
                'messages', json_array(
                    json_object('role', 'user', 'content', $prompt)
                )
            )
        ))
    ELSE
        sqlpage.fetch(json_object(
            'url', $api_endpoint || '?key=' || $api_key,
            'method', 'POST',
            'headers', json_object('Content-Type', 'application/json'),
            'body', json_object(
                'contents', json_array(
                    json_object('parts', json_array(json_object('text', $prompt)))
                )
            )
        ))
END;



-- Extract generated text
SET generated_text = CASE 
    WHEN $is_groq = 1 THEN json_extract($api_response, '$.choices[0].message.content')
    ELSE json_extract($api_response, '$.candidates[0].content.parts[0].text')
END;

SET generated_text = COALESCE($generated_text, 'Error generating content.');

-- Return JSON
SELECT 'json' AS component;
SELECT json_object(
    'success', CASE WHEN $generated_text = 'Error generating content.' THEN 0 ELSE 1 END,
    'refined_text', $generated_text
) AS contents;
