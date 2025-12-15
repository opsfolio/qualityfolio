#!/usr/bin/env -S deno run -A

import { CLI } from "../../../lib/axiom/text-ui/cli.ts";

// find all the markdown files in the current directory
const mdFiles = (await Array.fromAsync(Deno.readDir("."))).filter((e) =>
  e.isFile && e.name.endsWith(".md")
).map((e) => e.name);

// take all the files and give a single JSON projection so that survielr creates
// a single uniform_resource with all the documents in a single row
await new CLI().run([
  "projection",
  ...mdFiles,
  "--pretty",
]);
