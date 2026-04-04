#!/usr/bin/env bash
# fran_push.sh — export DB → data.json → Cloudflare Pages deploy
# Called by crons after writing new events to the DB.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_DIR="$(dirname "$SCRIPT_DIR")/Memory"
REASON="${2:-cron update}"

echo "[fran_push] Starting deploy — $REASON"

# 1. Export DB → data.json
python3 "$MEMORY_DIR/fran_export.py"
echo "[fran_push] data.json exported"

# 2. Git commit + push (keeps GitHub as source of truth)
cd "$SCRIPT_DIR"
git add data.json
if git diff --cached --quiet; then
  echo "[fran_push] No data.json change — skipping git commit"
else
  git commit -m "data: $REASON [$(date -u '+%Y-%m-%dT%H:%MZ')]"
  git push origin main
  echo "[fran_push] Git pushed"
fi

# 3. Cloudflare Pages deploy (always deploy to pick up any HTML/asset changes)
wrangler pages deploy . \
  --project-name fran-supply-chain \
  --branch main \
  --commit-dirty=true \
  --commit-message "$REASON" 2>&1 | grep -E "Success|Deploying|complete|error|Error" || true

echo "[fran_push] ✅ Published to https://fran-supply-chain.pages.dev/"
