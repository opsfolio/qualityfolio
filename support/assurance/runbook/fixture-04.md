This fixture demonstrates **how to run or list specific tasks** using graph
tags:

- Running `--graph A` will execute **Task-1** and **Task-4**
- Running `--graph B` will execute **Task-2** and **Task-5**
- Running `--graph C` will execute **Task-3** and **Task-6**

```bash task-1 --graph A --descr "A demo task-1"
echo "Task-1 ran successfully"
```

```bash task-2 --graph B --descr "A demo task-2"
echo "Task-2 ran successfully"
```

```bash task-3 --graph C --descr "A demo task-3"
echo "Task-3 ran successfully"
```

```bash task-4 --graph A --descr "A demo task-4"
echo "Task-4 ran successfully"
```

```bash task-5 --graph B --descr "A demo task-5"
echo "Task-5 ran successfully"
```

```bash task-6 --graph C --descr "A demo task-6"
echo "Task-6 ran successfully"
```

Commands used:

- For `/runbook/cli.ts`:

  `../lib/runbook/cli.ts run fixture-04.md --visualize ascii-tree --graph A`

- For `spry.ts`:

- `./spry.ts task ls --md fixture-04.md --select 'flags.graph == "A"'`
