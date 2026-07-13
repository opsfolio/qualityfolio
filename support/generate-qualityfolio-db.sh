cd support/assurance/qualityfolio

cat > .envrc <<EOF
export NOVU_API_KEY="${{ NOVU_API_KEY }}"
export NOVU_API_URL="${{ NOVU_API_URL }}"
export NOVU_WORKFLOW_ID="${{ NOVU_WORKFLOW_ID }}"
export RECIPIENT_EMAIL="${{ secrets.RECIPIENT_EMAIL }}"
export NOVU_EMAIL="${{ secrets.NOVU_EMAIL }}"
export NOVU_PASSWORD="${{ secrets.NOVU_PASSWORD }}"
EOF

source .envrc

spry rb run qualityfolio.md
spry sp spc --fs dev-src.auto --destroy-first --conf sqlpage/sqlpage.json --md qualityfolio.md
cat sqlpage/sqlpage.json
