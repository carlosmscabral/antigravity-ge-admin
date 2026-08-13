#!/usr/bin/env bash
set -e

# Load environment variables from .env if present
if [ -f "$(dirname "$0")/../.env" ]; then
  source "$(dirname "$0")/../.env"
fi

PROJECT_ID="${PROJECT_ID:-vibe-cabral}"
PROJECT_NUMBER="${PROJECT_NUMBER:-280799742875}"
ENGINE_ID="${ENGINE_ID:-cabral-demo-ge_1772569093320}"
APP_RESOURCE_NAME="projects/${PROJECT_NUMBER}/locations/global/collections/default_collection/engines/${ENGINE_ID}"

echo "=== Registering A2A Agent with Gemini Enterprise App ==="
echo "Project ID:        ${PROJECT_ID}"
echo "App Resource Name: ${APP_RESOURCE_NAME}"
echo "----------------------------------------------------"

if [ -z "$1" ]; then
  echo "Usage: $0 <AGENT_CARD_URL_OR_PATH>"
  echo "Example (GCS Bucket): $0 https://storage.googleapis.com/vibe-cabral-agent-cards/agent-card.json"
  echo "Example (Local File): $0 ./agent-card.json"
  exit 1
fi

AGENT_CARD_URL="$1"

agents-cli publish gemini-enterprise \
  --project="${PROJECT_ID}" \
  --gemini-enterprise-app-id="${APP_RESOURCE_NAME}" \
  --display-name="Antigravity Observability BQ Data Agent" \
  --description="Native BigQuery Data Agent providing observational analytics and metrics for Google Antigravity." \
  --registration-type=a2a \
  --agent-card-url="${AGENT_CARD_URL}"

echo "=== A2A Agent Registration Complete! ==="
