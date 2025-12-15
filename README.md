# Assurance-Prime

**Assurance-Prime** is a collection of example implementations and supporting artifacts for the Spry project (https://github.com/programmablemd/spry). This repository demonstrates real-world "Assurance" examples, test artifacts, runbooks, and ETL/SQL work that show how Spry can be used to gather, structure, and extract assurance evidence.

---

## Overview

- Purpose: Provide concrete Assurance examples and runnable snippets that complement the main Spry project.
- Relationship: This repository is intended to be used alongside the Spry project as example material and test data.

## Where to find examples

All examples and supporting materials live under the `support/assurance` directory. Inside you'll find:

- `qualityfolio/` — ETL scripts, TypeScript helpers, and example evidence outputs
- `runbook/` — runbooks and documentation describing fixtures and example flows
- `scf/` — SQL scripts and other resources used for SCF-related data preparation and analysis

Explore these folders to see sample `*.ts` scripts, SQL files, example artifact markdown, and auto-generated evidence under `evidence/`.

## How to use

1. Browse to an example subdirectory under `support/assurance`.
2. Read any `README.md`, runbook, or `run.auto.md` files to understand the scenario.
3. Run TypeScript helpers or ETL scripts as documented in that subfolder (many examples use Node/TypeScript and SQL).

Tip: Some examples are primarily SQL/ETL; others are TypeScript utilities that may require a Node toolchain (install dependencies with `npm install` or `pnpm` where applicable).

## Notable content

- `support/assurance/qualityfolio` — sample ETL and JSON/JSONL transformations, plus evidence files in `evidence/`.
- `support/assurance/scf` — SQL helpers & transforms used to prepare SCF datasets.

## Contributing

Contributions and additional example cases are welcome. Please follow the repository's contribution guidelines and open PRs against `main`.

## Questions

If you have questions about these examples or want to add more sample implementations, open an issue or a pull request in this repository.

---

_Lightweight, focused, and meant for learning — start in `support/assurance` to discover practical Spry examples._
