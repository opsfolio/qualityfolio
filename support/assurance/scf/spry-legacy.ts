#!/usr/bin/env -S deno run -A --node-modules-dir=auto
// Use `deno run -A --watch` in the shebang if you're contributing / developing Spry itself.

import { CLI } from "https://raw.githubusercontent.com/programmablemd/spry/refs/tags/v0.100.1/lib/sqlpage/cli.ts";

CLI.instance().run();
