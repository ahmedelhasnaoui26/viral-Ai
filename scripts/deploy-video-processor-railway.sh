#!/usr/bin/env bash
# Deploy video-processor to Railway from local files (fixes missing services/ on GitHub).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/services/video-processor"

if ! command -v railway >/dev/null 2>&1; then
  echo "Install Railway CLI: npm i -g @railway/cli"
  exit 1
fi

echo "Deploying from: $(pwd)"
echo ""
echo "Before first deploy:"
echo "  railway login"
echo "  railway link    # link to your Viral Ai Video service"
echo "  Set VIDEO_PROCESSOR_TOKEN in Railway → Variables"
echo ""

railway up

echo ""
echo "After deploy: Railway → Networking → Generate Domain"
echo "Then: supabase secrets set VIDEO_PROCESSOR_URL=https://YOUR-DOMAIN"
echo "      supabase secrets set VIDEO_PROCESSOR_TOKEN=<same-as-railway>"
