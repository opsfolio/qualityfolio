# File: public/scripts/start-dashboard.sh
#!/bin/bash

spry rb run qualityfolio.md &
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md &
EOH_INSTANCE=1 PORT=9227 surveilr web-ui -d ./resource-surveillance.sqlite.db --port 9227 --host 0.0.0.0 &

echo "Services started"