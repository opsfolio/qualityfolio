# Spry Secure Controls Framework (SCF) Exploration Example

This SQLPage exemplar automates the conversion of the latest Secure Controls
Framework (SCF) Excel workbook from the
[official SCF GitHub repository](https://github.com/securecontrolsframework/securecontrolsframework)
into a structured SQLite database and presents content via drill-down HTML web
application.

## Instructions

1. Download the SCF Excel workbook from the GitHub repo (recent example
   available).

2. Run the DuckDB SQL script which is described in `[Spryfile.md](Spryfile.md)`.

   ```bash
   ./spry.ts task prepare-db
   ```

3. Build the SQLPage notebook page from `Spryfile.md` and pipe it into the
   database to create `sqlpage_files` rows:

   ```bash
   ./spry.ts spc --package --conf sqlpage/sqlpage.json | sqlite3 scf-2025.3.sqlite.db
   ```

   `./spry.ts spc` is the Spry SQLPage Content (`spc`) command. Use
   `./spry.ts help spc` for more information.

4. Start the SQLPage server:

   ```bash
   SQLPAGE_SITE_PREFIX="" sqlpage
   ```
