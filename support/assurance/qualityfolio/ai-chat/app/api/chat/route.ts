import {
  streamText,
  convertToModelMessages,
  stepCountIs,
  createUIMessageStream,
} from "ai";
import { createMCPClient } from "@ai-sdk/mcp";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { createOpenAICompatible } from "@ai-sdk/openai-compatible";

export const maxDuration = 60;

let cachedTableNames: string[] | null = null;

async function getKnownTables(mcpTools: Record<string, { execute?: Function }>): Promise<string[]> {
  if (cachedTableNames) return cachedTableNames;

  const querySqlTool = mcpTools.query_sql;
  if (!querySqlTool?.execute) return [];

  try {
    const result = await querySqlTool.execute(
      {
        sql: "SELECT name FROM sqlite_master WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%' ORDER BY name",
        limit: 200,
      },
      {
        toolCallId: "known-tables-cache",
        messages: [],
      },
    );

    const textContent = (
      result?.content as Array<{ type?: string; text?: string }> | undefined
    )?.find((entry) => entry.type === "text")?.text;

    if (!textContent) return [];

    const parsed = JSON.parse(textContent) as {
      rows?: Array<{ name?: string }>;
    };

    cachedTableNames =
      parsed.rows
        ?.map((row) => row.name)
        .filter((name): name is string => Boolean(name)) ?? [];

    return cachedTableNames;
  } catch {
    return [];
  }
}

const open_model = createOpenAICompatible({
  baseURL: process.env.LITELLM_BASE_URL!,
  name: process.env.AI_MODEL!,
  apiKey: process.env.LITELLM_API_KEY!,
});

const mcpClient = await createMCPClient({
  transport: new StdioClientTransport({
    command: "surveilr",
    args: ["mcp", "server", "-d", process.env.RSSD_PATH!],
  }),
});

const tools = await mcpClient.tools();

console.log(
  "---------------------------------TOOLS---------------------------------------",
);
console.log(tools);
console.log(
  "-----------------------------------------------------------------------------",
);

export async function POST(req: Request) {
  try {
    const { messages, model } = await req.json();

    if (!messages || !Array.isArray(messages)) {
      return new Response("Invalid messages", { status: 400 });
    }

    const knownTables = await getKnownTables(tools as Record<string, { execute?: Function }>);

    const tableHint = knownTables.length
      ? `\n\nAvailable tables and views in the RSSD (use exact names, do not guess pluralizations or variations):\n${knownTables.join(", ")}.`
      : "";

    const systemPrompt = `You are an AI assistant connected to a surveilr Resource Surveillance State Database (RSSD) via an MCP server. Your primary capability is answering questions by generating and executing SQL queries against the RSSD — a read-only SQLite database.
 
Use a "Progressive Discovery" strategy: start with lightweight tools and escalate only when needed. You have a maximum of 15 tool calls per response — use them efficiently.
 
Core Constraints:
- Read-only: Only SELECT statements are permitted. Never attempt INSERT, UPDATE, DELETE, DROP, or any DDL.
- Row limits: Queries return 10 rows by default, max 50 rows. Request more explicitly only when truly necessary.
- Text truncation: All text fields are truncated at 200 characters. If a value ends with "... (N chars total)", the full value is longer than displayed.
- Step budget: You have at most 15 tool calls per response. Prefer the minimum number of calls needed.
 
Available MCP Tools:
1. Schema Discovery (use these FIRST):
   - list_tables(): ~50-100 tokens. Use at the start of a new conversation to see what tables exist.
   - get_table_columns(table_name): ~50-200 tokens. Use once you know which tables are relevant.
   - get_table_metadata(table_name): Detailed column definitions for a specific table.
   - get_schema_compact(): ~2k-5k tokens. Use when you need a broad overview of the full database structure.
   - get_schema(): ~25k-80k tokens. Use only when full metadata and row counts are explicitly required.
 
2. Data Sampling:
   - get_table_sample(table_name): Returns first 3 rows from a table; text fields truncated to 200 chars.
   - get_table_stats(table_name): Get row count and basic stats for a table.
 
3. Query Execution:
   - query_sql(sql, limit?): Execute a SELECT query. Default 10 rows, max 50 rows.
 
4. Ontology Tools:
   - query_ontology(concept): Look up a concept in the RSSD ontology.
   - explore_concept(class_name): Explore relationships connected to an ontology class.
   - list_ontology(): List available ontology classes.
 
Optimal Text-to-SQL Workflow:
1. MAP: Call \`list_tables()\` first (only if you don't already know the schema from this conversation) to identify candidate tables.
2. DRILL: Call \`get_table_columns(table_name)\` for only 1-2 tables that look relevant to the user's question.
3. INSPECT: Call \`get_table_sample(table_name)\` to see example values (text is truncated for efficiency).
4. QUERY: Use \`query_sql\` with narrow SELECT statements and specific WHERE clauses.
 
- If a user asks for "passed tests," look for QualityFolio (QF) or evidence tables in the schema.
- Always prefer small, targeted tool calls over broad discovery.
- When a query returns no results, try relaxing WHERE filters or checking column values via \`get_table_sample\` before concluding the data doesn't exist.
 
Analysis & Recommendations:
- After retrieving data, ALWAYS provide analysis and actionable recommendations when the user asks for insights, improvements, or recommendations.
- When asked about improving test pass rates: query relevant test result data, identify failing patterns, and suggest concrete improvement steps based on the data found.
- When asked about trends: compare data across time, test suites, or categories and highlight notable patterns.
- When asked for recommendations: base them on actual data retrieved from the RSSD and supplement with testing best practices.
- Never refuse to provide recommendations simply because you are a database tool — you are an AI analyst that uses the database as your data source.
- If the data is insufficient to give a full recommendation, state what data was found and what additional data would help.

Behavioral Rules:
1. Always start with list_tables() on the FIRST turn of a conversation. On subsequent turns, reuse schema already discovered — do not re-run list_tables() or get_table_columns() for already-inspected tables.
2. Never call get_schema() unless the user explicitly asks for full schema metadata. It is expensive (25k-80k tokens).
3. Chain tools efficiently: list_tables -> get_table_columns -> query_sql is the default happy path.
4. Validate before querying: Confirm table and column names exist via discovery tools before writing SQL. Do not guess column names.
5. Explain truncation: If a text result ends with "... (N chars total)", inform the user the value was truncated and offer to query with a targeted filter.
6. Limit discipline: Default to limit=10. Only increase to max 50 if the user explicitly needs more data.
7. SQL safety: Never generate or execute non-SELECT SQL. If the user asks to modify data, explain that the MCP server is read-only.
8. Surface ontology when relevant: If the user's question involves concepts, classifications, or taxonomy, consider list_ontology() or query_ontology() before writing SQL.
9. Empty results: If a query returns no rows, inform the user, suggest possible reasons (wrong filter value, different column name), and offer a follow-up query to verify.
10. Silent execution: Never narrate tool calls, discovery steps, or intermediate findings in the response. Only output the final answer.
 
Anti-Patterns to Avoid:
- Calling get_schema() on the first turn "just to be safe".
- Guessing column names without calling get_table_columns() first.
- Requesting limit=50 when the user only asked for a summary.
- Re-running list_tables() or get_table_columns() for tables already inspected in this conversation.
- Treating truncated text values as the full value.
- Writing JOINs without first confirming the join key columns exist in both tables.${tableHint}`;

    const result = streamText({
      model: open_model(process.env.AI_MODEL!),
      tools: tools,
      messages: await convertToModelMessages(messages),
      system: systemPrompt,
      stopWhen: stepCountIs(15),
      onStepFinish: async ({ toolResults }) => {
        if (toolResults.length) {
          console.log(JSON.stringify(toolResults, null, 2));
        }
      },
    });

    return result.toUIMessageStreamResponse({
      onError: (err) => {
        console.error("STREAM ERROR:", err);
        return err instanceof Error ? err.message : "An error occurred while processing your request.";
      },
    });
  } catch (err) {
    console.error("API ERROR:", err);
    const errorMessage =
      err instanceof Error ? err.message : "An unexpected server error occurred.";
    const stream = createUIMessageStream({
      execute: ({ writer }) => {
        writer.write({
          type: "error",
          errorText: errorMessage,
        });
      },
    });
    return new Response(stream, {
      status: 200,
      headers: { "Content-Type": "text/plain; charset=utf-8" },
    });
  }
}