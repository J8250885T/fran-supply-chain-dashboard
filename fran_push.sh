#!/usr/bin/env bash
# fran_push.sh — export DB → data.json, git push → GitHub Pages deploy
# Called by crons after writing new events to the DB.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(dirname "$SCRIPT_DIR")"
MEMORY_DIR="$WORKSPACE_DIR/Memory"
REASON="${2:-cron update}"

echo "[fran_push] Starting deploy — $REASON"

# 1. Export DB → data.json
python3 "$MEMORY_DIR/fran_export.py"
echo "[fran_push] data.json exported"

# 2. Git commit and push to GitHub → triggers GitHub Pages deploy
cd "$SCRIPT_DIR"
git add index.html data.json logo.webp netlify.toml .gitignore .github/ 2>/dev/null || true
git add data.json
if git diff --cached --quiet; then
  echo "[fran_push] No data.json change — force push to refresh"
  git commit --allow-empty -m "deploy: $REASON [$(date -u '+%Y-%m-%dT%H:%MZ')]"
else
  git commit -m "data: $REASON [$(date -u '+%Y-%m-%dT%H:%MZ')]"
fi
git push origin main
echo "[fran_push] ✅ Pushed to GitHub Pages: https://j8250885t.github.io/fran-supply-chain-dashboard/"
