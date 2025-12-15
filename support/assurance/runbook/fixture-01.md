```bash task-1 --descr "A demo task"
echo "task-1 successful"
```

Run the task and capture it's output in `task2Output`, can retrieve it using
`${captured.task2Output}` in any `--interpolate` (or `-I`) cells:

```bash task-2 -C task2Output --dep task-3 --descr "Another demo task"
echo "task-2 successful"
```

Run the task and capture it's output in file `./task-3.txt`:

```bash task-3 --capture ./task-3.txt --gitignore --descr "Another demo task"
#!/usr/bin/env -S bash
echo "task-3 successful"
```

The `-I` allows _unsafe_ interpolation so that we can use the output of
`task-2`:

```bash task-4 -I --descr "Show captured output"
#!/usr/bin/env -S cat
# from task-2 captured output: "${captured.task2Output.text().trim()}"
```

The `clean` task is "special" so we put it in its own `graph` (the name is not
relevant) so it is not run with the other tasks. You can create as many graphs
as necessary with isolate them from the "main" graph and allow execution using
`--graph` argument in `spry.ts`.

```bash clean --graph special --silent
rm -f task-3.txt
rm -f .gitignore
rm -f .envrc
```

```envrc prepare-env -C ./.envrc --gitignore --descr "Generate .envrc file and add it to local .gitignore if it's not already there"
export SPRY_DB="sqlite://scf-2025.3.sqlite.db?mode=rwc"
export PORT=9227
```

> You can run clean using `./spry.ts task clean fixture-01.md` or
> `./spry.ts run fixture-01.md --graph special`

> The `--silent` allows you to ignore the output from `clean` task.
