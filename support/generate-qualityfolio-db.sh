cd support/services/qualityfolio
spry rb run qualityfolio.md
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md
cat sqlpage/sqlpage.json
