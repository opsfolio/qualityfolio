/* =============================================================================
SCF 2025.3 — End-to-End Data Flow (Excel → DuckDB (in-memory) → SQLite file)

PHASE 0 — Setup
  • SET VARIABLE scf_xls_source = '<workbook>.xlsx'
  • INSTALL/LOAD excel extension
  • (Later) INSTALL/LOAD sqlite extension

PHASE 1 — Ingest (Excel ⇒ DuckDB :memory:)
  1) scf_xls_sheet (VIEW)
     - Static mapping of Excel sheet names to desired table names for traceability.
     - Emits (scf_xls_source, sheet_name, table_name).

  2) read_xlsx(..., all_varchar = true) → CREATE TABLEs in DuckDB memory:
     - scf_control                        ← 'SCF 2025.3'
     - scf_authoritative_source           ← 'Authoritative Sources'
     - scf_assessment_objective           ← 'Assessment Objectives 2025.3'
     - scf_evidence_request               ← 'Evidence Request List 2025.3'
     - scf_data_privacy_mgmt_principle    ← 'Data Privacy Mgmt Principles'
     Notes:
       • all_varchar=true guarantees uniform typing for downstream UNPIVOT.
       • A provenance column scf_xls_source is added to each table.

PHASE 2 — Transform (Wide regime columns ⇒ Long form analytics base)
  3) scf_compliance_regime_control_column (VIEW)
     - Discovers “regime” columns by scanning information_schema.columns of scf_control.
     - Normalizes headers (remove CR/LF, collapse whitespace).
     - Filters out non-regime columns (description, risk/threat text, errata, etc.).
     - Produces (ordinal_position, column_name, regime_label) for reliable join keys.

  4) scf_regime_control_unpivoted (VIEW)
     - Adds row_number() as rid over scf_control.
     - UNPIVOT all columns except rid (everything is VARCHAR due to all_varchar).
     - Keep only melted rows whose column_name appears in
       scf_compliance_regime_control_column (i.e., true “regime” columns).
     - Projects a tidy, long form:
         regime_label, scf_no, scf_domain, scf_control, scf_control_question,
         regime_raw_value, regime_column_ordinal
     - This is your canonical “facts” dataset for analytics.

PHASE 3 — Persist (DuckDB :memory: ⇒ SQLite file) & Publish Analytics
  5) ATTACH 'scf-2025.3.sqlite.db' AS scf (TYPE sqlite)
     - Drops pre-existing “scf_*” objects in SQLite schema for idempotency.
     - CREATE TABLE scf."<name>" AS SELECT * FROM "<name>" (for each ingested/viewed table):
         scf_control
         scf_authoritative_source
         scf_assessment_objective
         scf_evidence_request
         scf_data_privacy_mgmt_principle
         scf_xls_sheet
         scf_compliance_regime_control_column
         scf_regime_control_unpivoted
       → This materializes the in-memory DuckDB results into a durable SQLite DB.

  6) CREATE OR REPLACE VIEWs in SQLite schema scf for analytics:
     - scf.scf_regime_control
         (clean projection of mappings: regime_label, scf_no, scf_domain, scf_control,
          scf_control_question, regime_raw_value)
     - scf.scf_regime_count
         (total controls per regime)
     - scf.scf_regime_domain_count
         (domain × regime counts)
     - scf.scf_regime_domain_coverage
         (coverage % of each domain by regime)
     - scf.scf_regime_domain_rank
         (top regimes inside each domain, ranked)
     - scf.scf_regime_overlap_jaccard
         (pairwise regime overlap + Jaccard similarity)
     - scf.scf_analytics_view
         (catalog of the above analytics views with friendly titles/descriptions)

DATA LINEAGE (high level)
  Excel (workbook sheets)
    → DuckDB tables (read_xlsx, all_varchar, +provenance scf_xls_source)
      → Regime discovery view (information_schema → scf_compliance_regime_control_column)
        → Long form mapping view (UNPIVOT) → scf_regime_control_unpivoted
          → ATTACH SQLite + CREATE TABLE AS (persisted copies)
            → SQLite analytics views (counts, coverage, overlap, catalog)

VALIDATION TIPS
  • SELECT COUNT(*) FROM scf_control;                         -- row volume
  • SELECT * FROM scf_compliance_regime_control_column LIMIT 20; -- regime columns detected
  • SELECT * FROM scf_regime_control_unpivoted LIMIT 20;      -- long form looks sane
  • SELECT * FROM scf.scf_regime_count ORDER BY control_count DESC; -- top regimes
  • SELECT * FROM scf.scf_analytics_view;                     -- view catalog

NOTES / EDGE CASES
  • Some Excel sheets (Threat/Risk Catalogs) contain heavy formatting; they’re commented out.
  • Newlines and special characters in headers are neutralized during regime detection, not during
    persistence; analytics rely on the detection view for robustness.
  • Because objects are materialized into SQLite, downstream tools can query without DuckDB present.

============================================================================== */

SET VARIABLE scf_xls_source  = 'Secure Controls Framework (SCF) - 2025.3.xlsx';

INSTALL excel;  LOAD excel;

-- NOTE: This script assumes that we're running in DuckDB :memory: destination

CREATE VIEW "scf_xls_sheet" AS
WITH sheets(sheet_name, table_name) AS (
  VALUES
    ('SCF 2025.3',                 'scf_control'),
    ('Authoritative Sources',      'scf_authoritative_source'),
    ('Assessment Objectives 2025.3','scf_assessment_objective'),
    ('Evidence Request List 2025.3','scf_evidence_request'),
    ('Data Privacy Mgmt Principles','scf_data_privacy_mgmt_principle'),
    ('SCF Domains & Principles','scf_domain_principle'),
    ('Threat Catalog',          'scf_threat_catalog'),
    ('Risk Catalog',            'scf_risk_catalog')
    
)
SELECT
  getvariable('scf_xls_source') AS scf_xls_source,
  sheet_name,
  table_name
FROM sheets;

CREATE TABLE "scf_control" AS
SELECT getvariable('scf_xls_source') AS scf_xls_source, *
FROM read_xlsx(getvariable('scf_xls_source'),
               sheet='SCF 2025.3',
               all_varchar = true);

CREATE TABLE "scf_authoritative_source_raw" AS
SELECT getvariable('scf_xls_source') AS scf_xls_source, *
FROM read_xlsx(getvariable('scf_xls_source'),
               sheet='Authoritative Sources',
               all_varchar = true);

CREATE TABLE "scf_authoritative_source" AS
 
SELECT * REPLACE (regexp_replace(
      regexp_replace("Mapping Column Header", '[\r\n]+', ' ', 'g'),
      '\s+', ' ', 'g'
    )  AS "Mapping Column Header")
FROM scf_authoritative_source_raw;

CREATE TABLE "scf_assessment_objective" AS
SELECT getvariable('scf_xls_source') AS scf_xls_source, *
FROM read_xlsx(getvariable('scf_xls_source'),
               sheet='Assessment Objectives 2025.3',
               all_varchar = true);

CREATE TABLE "scf_evidence_request" AS
SELECT getvariable('scf_xls_source') AS scf_xls_source, *
FROM read_xlsx(getvariable('scf_xls_source'),
               sheet='Evidence Request List 2025.3',
               all_varchar = true);

CREATE TABLE "scf_data_privacy_mgmt_principle" AS
SELECT getvariable('scf_xls_source') AS scf_xls_source, *
FROM read_xlsx(getvariable('scf_xls_source'),
               sheet='Data Privacy Mgmt Principles',
               all_varchar = true);
              
CREATE TABLE "scf_domain_principle" AS
SELECT getvariable('scf_xls_source') AS scf_xls_source, *
FROM read_xlsx(getvariable('scf_xls_source'),
               sheet='SCF Domains & Principles',
               all_varchar = true);

CREATE VIEW scf_compliance_regime_control_column AS
WITH cleaned AS (
  SELECT
    ordinal_position,
    column_name,
    -- remove all CR/LF, then collapse whitespace
    regexp_replace(
      regexp_replace(column_name, '[\r\n]+', ' ', 'g'),
      '\s+', ' ', 'g'
    ) AS regime_label_clean
  FROM information_schema.columns
  WHERE table_name = 'scf_control'
),
filtered AS (
  SELECT
    ordinal_position,
    column_name,
    regime_label_clean,
    lower(regime_label_clean) AS regime_label_lc
  FROM cleaned
  WHERE column_name NOT IN (
    'scf_xls_source',
    'SCF Domain','SCF Control','SCF #',
    'Secure Controls Framework (SCF)\nControl Description',
    'SCF Control Question','Relative Control Weighting',
    'Conformity Validation\nCadence',
    'Risk Threat Summary','Control Threat Summary','Errata\n2025.3'
  )
  AND regime_label_lc NOT LIKE '%possible solutions%'
  AND regime_label_lc NOT LIKE '%pptdf%'
  AND regime_label_lc NOT LIKE '%function grouping%'
  AND regime_label_lc NOT LIKE '%scrm focus%'
  AND regime_label_lc NOT LIKE '%c|p-cmm%'
  AND regime_label_lc NOT LIKE '%minimum security%'
  AND regime_label_lc NOT LIKE 'risk %'
  AND regime_label_lc NOT LIKE '% risk %'
  AND regime_label_lc NOT LIKE 'threat %'
  AND regime_label_lc NOT LIKE '% threat %'
  AND regime_label_lc NOT LIKE 'identify%'
  AND regime_label_lc NOT LIKE 'errata%'
  AND regime_label_lc NOT LIKE 'conformity validation cadence%'
  AND regime_label_lc NOT LIKE 'secure controls framework (scf) control description'
),
dedup AS (
  SELECT
    MIN(ordinal_position) AS ordinal_position,
    column_name,
    regime_label_clean AS regime_label
  FROM filtered
  GROUP BY column_name, regime_label_clean
)
SELECT ordinal_position, column_name, regime_label
FROM dedup
ORDER BY regime_label, ordinal_position;

CREATE OR REPLACE VIEW scf_regime_control_unpivoted AS
WITH sc AS (
  SELECT row_number() OVER () AS rid, *
  FROM scf_control
),
u AS (
  SELECT
    u.rid,
    u.column_name,
    u.value
  FROM sc
  UNPIVOT (value FOR column_name IN (* EXCLUDE (rid))) AS u
)
SELECT
  r.regime_label                              AS regime,
  sc."SCF #"                                  AS scf_no,
  sc."SCF Domain"                             AS scf_domain,
  sc."SCF Control"                            AS scf_control,
  -- coalesce(
  --   sc."Secure Controls Framework (SCF)\nControl Description",
  --   sc."Secure Controls Framework (SCF) Control Description"
  -- )                                           AS scf_control_description,
  sc."SCF Control Question"                   AS scf_control_question,
  r.regime_label                              AS regime_label,
  u.value                                     AS regime_raw_value,
  r.ordinal_position                          AS regime_column_ordinal
FROM u
JOIN scf_compliance_regime_control_column r
  ON r.column_name = u.column_name
JOIN sc
  ON sc.rid = u.rid
WHERE trim(coalesce(u.value, '')) <> '';

-- Correctly import "Threat Catalog" by skipping the complex header and renaming columns
CREATE TABLE "scf_threat_catalog" AS
WITH raw_threat_catalog AS (
    SELECT
        ROW_NUMBER() OVER () as row_num,
        A AS "Threat Grouping",
        B AS "Threat #",
        C AS "Threat*",
        D AS "Threat Description",
        E AS "≥ 5% of pre-tax income",
        F AS "≥ 0.5% of total assets",
        G AS "≥ 1% of total equity",
        H AS "≥ 0.5% of total revenue"
    FROM read_xlsx(
        getvariable('scf_xls_source'),
        sheet='Threat Catalog',
        range='A8:H',
        header=false,
        all_varchar=true
    )
)
SELECT
    getvariable('scf_xls_source') AS scf_xls_source,
    LAST_VALUE("Threat Grouping" IGNORE NULLS) OVER (ORDER BY row_num) as "Threat Grouping",
    "Threat #",
    "Threat Description",
    "≥ 5% of pre-tax income",
    "≥ 0.5% of total assets",
    "≥ 1% of total equity",
    "≥ 0.5% of total revenue"
FROM raw_threat_catalog
WHERE trim(coalesce("Threat #", '')) <> '';

CREATE TABLE "scf_risk_catalog" AS
WITH raw_risk_catalog AS (
    SELECT
        ROW_NUMBER() OVER () as row_num,
        A AS "Risk Grouping",
        B AS "Risk #",
        C AS "Risk*",
        D AS "Description of Possible Risk Due To Control Deficiency",
        E AS "NIST CSF Function",
        F AS "≥ 5% of pre-tax income",
        G AS "≥ 0.5% of total assets",
        H AS "≥ 1% of total equity",
        I AS "≥ 0.5% of total revenue"
    FROM read_xlsx(
        getvariable('scf_xls_source'),
        sheet='Risk Catalog',
        range='A8:I',
        header=false,
        all_varchar=true
    )
)
SELECT
    getvariable('scf_xls_source') AS scf_xls_source,
    LAST_VALUE("Risk Grouping" IGNORE NULLS) OVER (ORDER BY row_num) as "Risk Grouping",
    "Risk #",
    "Risk*",
    "Description of Possible Risk Due To Control Deficiency",
    "NIST CSF Function",
    "≥ 5% of pre-tax income",
    "≥ 0.5% of total assets",
    "≥ 1% of total equity",
    "≥ 0.5% of total revenue"
FROM raw_risk_catalog
WHERE trim(coalesce("Risk #", '')) <> '';



INSTALL sqlite; LOAD sqlite;

ATTACH 'scf-2025.3.sqlite.db' AS scf (TYPE sqlite);

DROP TABLE IF EXISTS scf."scf_control";
DROP TABLE IF EXISTS scf."scf_domain_principle";
DROP TABLE IF EXISTS scf."scf_authoritative_source";
DROP TABLE IF EXISTS scf."scf_assessment_objective";
DROP TABLE IF EXISTS scf."scf_threat_catalog";
DROP TABLE IF EXISTS scf."scf_risk_catalog";
DROP TABLE IF EXISTS scf."scf_evidence_request";
DROP TABLE IF EXISTS scf."scf_data_privacy_mgmt_principle";
DROP TABLE IF EXISTS scf."scf_xls_sheet";
DROP TABLE IF EXISTS scf."scf_compliance_regime_control_column";
DROP VIEW IF EXISTS scf."scf_regime_control";
DROP TABLE IF EXISTS scf."scf_regime_control_unpivoted"; 

CREATE TABLE scf."scf_control" AS SELECT * FROM "scf_control";
CREATE TABLE scf."scf_domain_principle" AS SELECT * FROM "scf_domain_principle";
CREATE TABLE scf."scf_authoritative_source" AS SELECT * FROM "scf_authoritative_source";
CREATE TABLE scf."scf_assessment_objective" AS SELECT * FROM "scf_assessment_objective";
CREATE TABLE scf."scf_threat_catalog" AS SELECT * FROM "scf_threat_catalog";
CREATE TABLE scf."scf_risk_catalog" AS SELECT * FROM "scf_risk_catalog";
CREATE TABLE scf."scf_evidence_request" AS SELECT * FROM "scf_evidence_request";
CREATE TABLE scf."scf_data_privacy_mgmt_principle" AS SELECT * FROM "scf_data_privacy_mgmt_principle";
CREATE TABLE scf."scf_xls_sheet" AS SELECT * FROM "scf_xls_sheet";
CREATE TABLE scf."scf_compliance_regime_control_column" AS SELECT * FROM "scf_compliance_regime_control_column";
CREATE TABLE scf."scf_regime_control_unpivoted" AS SELECT * FROM "scf_regime_control_unpivoted";

-- Only the “in” mappings (clean list)
CREATE OR REPLACE VIEW scf."scf_regime_control" AS
SELECT regime_label, scf_no, scf_domain, scf_control, scf_control_question, regime_raw_value
FROM scf_regime_control_unpivoted;

CREATE OR REPLACE VIEW scf."scf_regime_count" AS
SELECT regime_label as regime, COUNT(regime_label) AS control_count
FROM scf_regime_control
GROUP BY regime_label
ORDER BY control_count DESC, regime_label;

CREATE OR REPLACE VIEW scf."scf_regime_domain_count" AS
SELECT
  scf_domain as domain,
  regime_label as regime,
  COUNT(regime_raw_value) AS control_count
FROM scf_regime_control
GROUP BY scf_domain, regime_label
ORDER BY scf_domain, control_count DESC, regime_label;

-- Domain coverage % by regime
CREATE OR REPLACE VIEW scf."scf_regime_domain_coverage" AS
WITH denom AS (
  SELECT scf_domain, COUNT(DISTINCT scf_no) AS domain_total_controls
  FROM scf_regime_control
  GROUP BY scf_domain
),
num AS (
  SELECT scf_domain, regime_label, COUNT(DISTINCT scf_no) AS mapped_controls
  FROM scf_regime_control
  GROUP BY scf_domain, regime_label
)
SELECT
  n.scf_domain,
  n.regime_label,
  n.mapped_controls,
  d.domain_total_controls,
  ROUND(100.0 * n.mapped_controls / NULLIF(d.domain_total_controls,0), 2) AS coverage_pct
FROM num n
JOIN denom d USING (scf_domain)
ORDER BY n.scf_domain, coverage_pct DESC, n.regime_label;

-- Top regimes within each domain (ranked)
CREATE OR REPLACE VIEW scf."scf_regime_domain_rank" AS
WITH counts AS (
  SELECT scf_domain, regime_label, COUNT(regime_raw_value) AS control_count
  FROM scf_regime_control
  GROUP BY scf_domain, regime_label
)
SELECT
  scf_domain,
  regime_label,
  control_count,
  ROW_NUMBER() OVER (PARTITION BY scf_domain ORDER BY control_count DESC, regime_label) AS regime_rank_in_domain
FROM counts
ORDER BY scf_domain, regime_rank_in_domain;


-- Regime overlap with Jaccard index
CREATE OR REPLACE VIEW scf."scf_regime_overlap_jaccard" AS
WITH base AS (
  SELECT regime_label, COUNT(DISTINCT scf_no) AS controls_in_regime
  FROM scf_regime_control
  GROUP BY regime_label
),
"both" AS (
  SELECT a.regime_label AS regime_a, b.regime_label AS regime_b, COUNT(DISTINCT a.scf_no) AS in_both
  FROM scf_regime_control a
  JOIN scf_regime_control b
    ON a.scf_no = b.scf_no
   AND a.regime_label < b.regime_label
   AND a.regime_raw_value = b.regime_raw_value
  GROUP BY a.regime_label, b.regime_label
)
SELECT
  "both".regime_a,
  "both".regime_b,
  "both".in_both,
  ba.controls_in_regime AS a_total,
  bb.controls_in_regime AS b_total,
  ROUND(1.0 * "both".in_both / NULLIF(ba.controls_in_regime + bb.controls_in_regime - "both".in_both, 0), 4) AS jaccard
FROM "both"
JOIN base ba ON ba.regime_label = "both".regime_a
JOIN base bb ON bb.regime_label = "both".regime_b
ORDER BY jaccard DESC, "both".in_both DESC, "both".regime_a, "both".regime_b;

CREATE OR REPLACE VIEW scf."scf_analytics_view" AS
WITH entries(view_schema, view_name, title, description) AS (
  VALUES
    ('scf','scf_regime_control_unpivoted','Long form of SCF x Regime mappings',
     'One row per (SCF control, regime column) with the raw cell value and regime column ordinal. Use this as the base long-form dataset.'),
    ('scf','scf_regime_control','Clean list of regime mappings',
     'Filtered projection of the unpivoted data. One row per (SCF control, regime) keeping key control fields and the regime''s raw marker.'),
    ('scf','scf_regime_count','Controls per regime (totals)',
     'Aggregate count of how many SCF controls appear under each regime label. Good for quick top-N regime charts.'),
    ('scf','scf_regime_domain_count','Domain x Regime counts',
     'Counts of controls grouped by SCF domain and regime. Useful for heatmaps showing domain coverage by regime.'),
    ('scf','scf_regime_domain_coverage','Domain coverage % by regime',
     'For each SCF domain and regime, shows mapped control count, total controls in the domain, and the percent coverage.'),
    ('scf','scf_regime_domain_rank','Top regimes within each domain',
     'Ranks regimes inside each SCF domain by count of mapped controls (ties broken by regime name).'),
    ('scf','scf_regime_overlap_jaccard','Regime overlap (Jaccard)',
     'Pairwise overlap of regimes based on shared SCF controls, including each regime''s total and the Jaccard similarity score.')
)
SELECT * FROM entries;
