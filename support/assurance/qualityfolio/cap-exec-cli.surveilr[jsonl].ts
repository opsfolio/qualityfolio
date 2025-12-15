#!/usr/bin/env -S deno run -A

import { CLI } from "../../../lib/axiom/text-ui/cli.ts";

// find all the markdown files in the current directory
const mdFiles = (await Array.fromAsync(Deno.readDir("."))).filter((e) =>
  e.isFile && e.name.endsWith(".md")
).map((e) => e.name);

// use the CLI to take all the files and put one line per projection so that
// surveilr creates a separate `uniform_resource` row for each document
await new CLI().run([
  "projection",
  ...mdFiles,
  "--jsonl",
]);
