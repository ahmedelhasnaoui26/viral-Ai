#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN="${VIDEO_PROCESSOR_TOKEN:-dev-local-token}"

echo "Building video processor..."
docker build -t cinemorph-video-processor "$ROOT/services/video-processor"

echo ""
echo "Starting on http://localhost:8080"
echo "Set Supabase secrets:"
echo "  supabase secrets set VIDEO_PROCESSOR_URL=http://host.docker.internal:8080"
echo "  supabase secrets set VIDEO_PROCESSOR_TOKEN=$TOKEN"
echo ""
echo "For iOS Simulator + ngrok: expose port 8080 and use that HTTPS URL instead."
echo ""

docker run --rm -p 8080:8080 \
  -e VIDEO_PROCESSOR_TOKEN="$TOKEN" \
  cinemorph-video-processor
