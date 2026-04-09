#!/usr/bin/env bash
# fran_push.sh — export DB → data.json → Cloudflare Pages deploy
# Called by crons after writing new events to the DB.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_DIR="$(dirname "$SCRIPT_DIR")/Memory"
REASON="${2:-cron update}"

echo "[fran_push] Starting — $REASON"

# ── Credentials ───────────────────────────────────────────────────────────────
# Uses the wrangler OAuth session stored at ~/.wrangler/config/default.toml
# Do NOT set CLOUDFLARE_API_TOKEN here — it overrides and breaks the OAuth session.
export CLOUDFLARE_ACCOUNT_ID="b7ebf617ef365f26fa46f2c86c9c1bcd"

# ── 1. Export DB → data.json ──────────────────────────────────────────────────
python3 "$MEMORY_DIR/fran_export.py"
echo "[fran_push] data.json exported"

# ── 2. Git commit + push (keeps GitHub as source of truth) ───────────────────
cd "$SCRIPT_DIR"
git add data.json index.html logo.webp 2>/dev/null || true
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -m "data: $REASON [$(date -u '+%Y-%m-%dT%H:%MZ')]" 2>/dev/null || true
  git push origin main 2>&1 | tail -3
fi

# ── 3. Deploy directly to production via wrangler ────────────────────────────
# --branch main tells Cloudflare Pages this IS the production deployment.
# No promotion step needed — this goes live immediately at fran-supply-chain.pages.dev
echo "[fran_push] Deploying to Cloudflare Pages..."
npx wrangler pages deploy . \
  --project-name fran-supply-chain \
  --branch main \
  --commit-dirty=true 2>&1

echo "[fran_push] ✅ Live: https://fran-supply-chain.pages.dev"
echo "[fran_push] Done."
