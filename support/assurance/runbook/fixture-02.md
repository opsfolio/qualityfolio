```bash task-1 --descr "A demo task"
echo "task-1 successful"
```

```bash task-2 --dep task-3 -C --descr "Another demo task"
echo "task-2 successful"
```

```bash PARTIAL test-partial { newLocal: { type: "string", required: true } }
echo "this is the newLocal in test-partial: ${newLocal}"
```

```bash PARTIAL --not-directive --descr "Ignore PARTIAL as a directive"
echo "the name of this task is PARTIAL because --not-directive was passed"
```

The `-I` (or `--interpolate` will allow the task to be interpolated by Spry)

```bash task-3 -I --descr "Another demo task"
#!/usr/bin/env -S bash
echo "task-3 successful"
$!{await partial("test-partial", { newLocal: "passed from task-3"})}
```

> The following is an example of how to see the output of an interpolation. Just
> use `#!/usr/bin/env -S cat` to cat the output.

```bash task-4 --interpolate --descr "Another demo task"
#!/usr/bin/env -S cat
# locals for unsafe use: $!{Object.keys(__l).join(", ")}
# already capture/memoized: $!{Object.keys(captured).join(", ")}
# keys available in current TASK: $!{Object.keys(TASK).join(", ")}

# this should resolve relative to CWD properly whether local or remote
# relative file: $!{resolveRelPath("../qualityfolio/Qualityfolio.md")}

echo "task: ${TASK.spawnableIdentity}"

# partial 1 (error): $!{await partial("non-existent")}

# partial 2 (works): $!{await partial("test-partial", { newLocal: "passed from task-4"})}

# partial 3 (error): $!{await partial("test-partial", { mistypedNewLocal: "passed from task-4"})}

$!{await partial("test-partial", { newLocal: "passed from task-4 with await"})}
```
