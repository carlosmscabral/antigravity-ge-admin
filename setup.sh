#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo " Google Antigravity Enterprise Observability Master Setup "
echo "=========================================================="

# Check if .env exists, if not copy from .env.example
if [ ! -f "${SCRIPT_DIR}/.env" ]; then
  echo "No .env file found. Copying .env.example to .env..."
  cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
fi

source "${SCRIPT_DIR}/.env"

echo "Using Configuration:"
echo "  PROJECT_ID:     ${PROJECT_ID}"
echo "  LOCATION:       ${LOCATION}"
echo "  DATASET_ID:     ${DATASET_ID}"
echo "  SINK_NAME:      ${SINK_NAME}"
echo "  LOG_METRIC:     ${LOG_METRIC_NAME}"
echo "----------------------------------------------------------"

# Step 1: Provision Infrastructure & IAM
echo ""
echo "[Step 1/3] Setting up BigQuery Dataset, Logging Sink & IAM Roles..."
bash "${SCRIPT_DIR}/scripts/01_setup_bq_and_sink.sh"

# Step 2: Historical Log Backfill
echo ""
echo "[Step 2/3] Exporting and Backfilling Past Cloud Logging Records to BigQuery..."
gcloud logging read 'resource.type="businessaicode.googleapis.com/BAICInstance"' \
  --project="${PROJECT_ID}" --format=json --limit=1000 > /tmp/raw_logs.json 2>/dev/null || true

if [ -s /tmp/raw_logs.json ]; then
  python3 "${SCRIPT_DIR}/scripts/backfill_logs.py"
  bq load --replace --source_format=NEWLINE_DELIMITED_JSON \
    --project_id="${PROJECT_ID}" \
    "${PROJECT_ID}:${DATASET_ID}.businessaicode_googleapis_com_inference_response" \
    /tmp/formatted_logs.json
  echo "Backfill completed successfully!"
else
  echo "No existing logs found in Cloud Logging to backfill."
fi

# Step 3: Create SQL Views
echo ""
echo "[Step 3/3] Creating BigQuery Analytical SQL Views..."
bash "${SCRIPT_DIR}/scripts/02_create_bq_views.sh"

echo ""
echo "=========================================================="
echo " SUCCESS: Enterprise Observability Pipeline Setup Complete!"
echo "=========================================================="
echo "Next Steps:"
echo "1. Follow instructions in docs/ENTERPRISE_OBSERVABILITY_SETUP_GUIDE.md"
echo "   to create your Native BigQuery Data Agent in BigQuery Studio."
echo "2. Create GCP OAuth 2.0 Web Client Credentials."
echo "3. Publish your A2A Agent Card using scripts/03_publish_a2a_agent.sh"
echo "=========================================================="
