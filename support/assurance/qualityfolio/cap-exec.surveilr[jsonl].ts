#!/usr/bin/env -S deno run -A

import { flexibleProjectionFromFiles } from "../../../lib/axiom/projection/flexible.ts";

// find all the markdown files in the current directory
const mdFiles = (await Array.fromAsync(Deno.readDir("."))).filter((e) =>
  e.isFile && e.name.endsWith(".md")
).map((e) => e.name);

// take all the files and put one line per projection so that surveilr creates
// a separate `uniform_resource` row for each document
for (const md of mdFiles) {
  const model = await flexibleProjectionFromFiles([md]);
  console.log(JSON.stringify(model)); // one JSON per line ("JSONL")
}
