Deterministic Simulation Testing (DST) is a family of ideas and practices for
ensuring that _programs which depend on complex, stateful, or time-sensitive
environments remain perfectly reproducible under test_. DST tries to make tests
behave like _simulations_ of the real system, but without the variance,
nondeterminism, or environmental drift that make certain classes of software
difficult to test reliably.

Below is a conceptual overview and then a direct mapping to our needs in
**Spry**, specifically for “programmable Markdown” as described in your project
files.

## 1. What Deterministic Simulation Testing (DST) Tries to Solve

DST assumes the following are true for most real systems:

- Real environments are nondeterministic.
- Real I/O has timing behavior you cannot perfectly control.
- Real data sources (APIs, local files, DBs) change.
- Real actors (humans, AI agents, background processes) behave variably.

DST’s goal: **Create a deterministic _simulation layer_ that “stands in” for the
entire nondeterministic universe during test runs.**

This simulation layer ensures that:

- All input is _fixed or generated from a reproducible seed_.
- All I/O is orchestrated through controlled deterministic “ports.”
- Time is simulated, not real.
- The order of events is deterministic, not observed “as they come.”
- External side-effects are modeled in-memory unless explicitly permitted.
- When randomness must exist, it flows from deterministic pseudo-random
  generators with known seeds.

### Core Principles of DST

1. **Deterministic Inputs** Every function or step receives exactly the same
   inputs every time the test is run.

2. **Deterministic Time** Time is frozen, advanced manually, or simulated; no
   “real time” calls allowed.

3. **Deterministic I/O** All I/O is stubbed, replayed, or modeled through state
   machines.

4. **Deterministic External Effects** Anything outside the program boundary
   becomes part of the simulation, not the real world.

5. **Deterministic Event Ordering** Asynchronous and concurrent systems are
   forced into repeatable schedules or interleavings.

### Why DST Works So Well

DST turns _testing_ into a form of _model checking_: You re-run the same code
under multiple deterministic universes and verify invariants.

## 2. Why DST Is Relevant for “Programmable Markdown” (Spry)

Spry treats Markdown as an executable, composable medium — every code block,
fence, directive, and attribute contributes behavior. That means your Markdown:

- Runs shell commands
- Runs SQL
- Runs TypeScript
- Loads files
- Executes “emitters” and “plugins”
- Produces artifacts (SQL, HTML, JSON, etc.)
- Depends on local filesystem structure
- Might depend on time, environment variables, or remote URLs

In other words, **a Spry `.md` file is a mini-program**.

Programs demand testability; programmable Markdown demands _repeatable_,
_auditable_, _non-flaky_ testing. That’s textbook DST territory.

## 3. How DST Helps with Testing Programmable Markdown

### A. Stabilizing Markdown Execution Pipelines

Each Markdown cell might:

- read from filesystem
- write artifacts
- depend on the output of prior cells
- call Deno APIs
- generate timestamps
- produce SQL migrations
- perform network fetches
- use random data (e.g., in examples or demos)

DST encourages isolating all such effects behind deterministic “ports.”

For Spry:

- File reads become _fixture-backed_ deterministic reads
- SQL engines use deterministic in-memory SQLite capsules
- Shell commands are simulated (or constrained to deterministic subsets)
- Timestamps and UUIDs are injected from deterministic clocks
- Network fetches are pre-recorded or stubbed

This means Markdown that worked once will work identically tomorrow, a week from
now, or on CI.

### B. Making Code Fences Deterministically Testable

Today, you might have a fence like:

````md
```bash run
ls -la
```
````

or

```sql emit
CREATE TABLE users (...);
```

Under DST:

- The _environment_ inside the fence is simulated.
- The filesystem is a deterministic fixture.
- The SQL engine uses an in-memory DB with deterministic state.
- “ls” is either:

  - simulated, or
  - executed in a sandbox with fixed contents.

Outcomes are perfectly stable. This unlocks “self-verifying README” behavior
with confidence.

### C. Stable Graph + Ontology Construction

Spry Axiom turns mdast/unist into graph edges and structured semantic nodes.
That graph construction must be deterministic to remain testable:

- Node IDs
- Ordering of children
- Emitted edges
- Decorators (like `@id`, `@partial`)
- Processing instructions
- Emitted artifacts

DST ensures that:

> “The same Markdown yields the same graph every time.”

This lets you write tests like:

```ts
assertGraphEquals(
  buildGraph(fixtureMarkdown),
  expectedGraphFixture,
);
```

…without worrying that time, file order, or nondeterministic traversal will
break the test.

### D. Idempotent SQL Migrations via DST

Spry encourages idempotent SQL migrations (as per your README and other design
docs). DST turns this into:

- deterministic CTE-driven SQL migration
- deterministic database state before and after
- deterministic artifact emission for `.auto.sql`

You can test that:

> Running the Markdown twice yields the same final DB state.

DST makes this reliable.

### E. Deterministic Materialization & Plugin Discovery

Spry's plugin system auto-discovers Deno modules (“emitters” and
“interpreters”). Auto-discovery can be nondeterministic if directory ordering
changes.

DST encourages:

- fixed deterministic ordering
- sorted module discovery
- reproducible linkage
- simulation of plugin metadata

This ensures your plugins do not flake under CI.

## 4. Concrete DST Techniques We Can Apply to Spry

Here’s how DST maps cleanly into the Spry architecture:

### 1. Deterministic FS Layer for Markdown Notebooks

Implement a virtual filesystem interface:

- All reads come from a `ReadonlyMap<string, string>` fixture
- No uncontrolled `Deno.readFile()` calls
- All paths normalized
- Symbolic links, parent directories, etc., simulated

### 2. Deterministic “Runtime Ports”

In Spry, “ports” correspond to:

- shell (`bash`, `sh`) execution
- SQL execution
- HTTP fetch
- TypeScript execution
- plugin discovery
- graph building

DST wraps each port:

```ts
interface Port<TInput, TOutput> {
  invoke(input: TInput): TOutput;
}
```

In test mode, ports become deterministic simulators.

### 3. Freeze or Simulate Time

Provide a deterministic clock:

```ts
const clock = new DeterministicClock("2025-01-01T00:00:00Z");
```

Inject into everything that may use time:

- frontmatter generation
- notebooks that generate timestamps
- SQL migrations that use `CURRENT_TIMESTAMP`
- emitted logs

### 4. Deterministic SQL Capsules

Each code block executed under:

````md
```sql capsule:name
...
```
````

gets its own reproducible, seeded in-memory DB.

### 5. Deterministic Event Scheduling

Even if materials are executed asynchronously or in pipelines, DST ensures:

- traversal order is fixed
- event emissions are ordered deterministically
- multi-cell dependencies are resolved deterministically

### 6. Deterministic Hashing

All emitted artifacts (e.g., `.auto.sql`, `.html`) should:

- use deterministic JSON/stringifiers
- avoid nondeterministic key ordering
- use deterministic cryptographic hashers

### 7. Deterministic Randomness

Use seedable PRNG for any example code block needing randomness:

```ts
const rng = new PRNG(seedFromMarkdownFile);
```

## 5. How DST Lets You Test Spry Markdown in CI Reliably

Using DST, you can write tests like:

### Test 1: Markdown builds the same artifacts

```ts
const first = runSpryDeterministically("fixture.md");
const second = runSpryDeterministically("fixture.md");

assertEquals(first.outputs, second.outputs);
```

### Test 2: Graph edges are stable

```ts
assertEquals(
  buildGraph(fixtureMarkdown),
  expectedGraphFixture,
);
```

### Test 3: SQL migrations are idempotent

```sql
SELECT * FROM system_state;
```

assert DB state identical after 2nd run.

### Test 4: Plugin discovery is deterministic

```ts
assertOrderedEqual(discoveredPlugins(), expectedPluginList);
```

### Test 5: Markdown cell evaluation returns stable outputs

Repeated runs yield identical STDOUT, STDERR, side-effects.

## 6. Summary: Why Deterministic Simulation Testing Complements Programmable Markdown

DST gives Spry:

- deterministic `.md` → AST → Graph → Artifacts
- deterministic plugin discovery
- deterministic execution of SQL, shell, TS cells
- deterministic timestamps, randomness, and I/O
- deterministic idempotent SQL migrations
- deterministic CI runs that never flake

In short:

> **DST turns executable Markdown into a _reproducible computational notebook_,
> not just a script with prose.**

This is exactly what Spry is trying to accomplish — Markdown as a **reliable**,
**typed**, **reproducible**, **testable**, **declarative** programming medium.
