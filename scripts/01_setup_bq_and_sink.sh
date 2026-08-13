#!/usr/bin/env bash
set -e

# Load environment variables from .env if present
if [ -f "$(dirname "$0")/../.env" ]; then
  source "$(dirname "$0")/../.env"
fi

if [ -z "${PROJECT_ID}" ]; then
  echo "ERROR: PROJECT_ID is not set. Please configure .env or export PROJECT_ID."
  exit 1
fi

LOCATION="${LOCATION:-US}"
DATASET_ID="${DATASET_ID:-antigravity_observability}"
SINK_NAME="${SINK_NAME:-antigravity_observability_sink}"
LOG_METRIC_NAME="${LOG_METRIC_NAME:-businessaicode-users}"

if [ -z "${PROJECT_NUMBER}" ]; then
  echo "Auto-detecting PROJECT_NUMBER for ${PROJECT_ID}..."
  PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}" --format="value(projectNumber)")
fi

echo "=== Enterprise Observability Infrastructure Setup ==="
echo "Project ID:     ${PROJECT_ID}"
echo "Project Number: ${PROJECT_NUMBER}"
echo "Location:       ${LOCATION}"
echo "Dataset ID:     ${DATASET_ID}"
echo "Sink Name:      ${SINK_NAME}"
echo "Metric Name:    ${LOG_METRIC_NAME}"
echo "----------------------------------------------------"

# 1. Create BigQuery Dataset if not exists
echo "Creating BigQuery Dataset '${PROJECT_ID}:${DATASET_ID}'..."
bq --location="${LOCATION}" mk -d \
  --description "Google Antigravity Enterprise Observability Dataset" \
  "${PROJECT_ID}:${DATASET_ID}" 2>/dev/null || echo "Dataset '${DATASET_ID}' already exists."

# 2. Create Cloud Logging Sink
echo "Creating Cloud Logging Sink '${SINK_NAME}'..."
gcloud logging sinks create "${SINK_NAME}" \
  "bigquery.googleapis.com/projects/${PROJECT_ID}/datasets/${DATASET_ID}" \
  --log-filter='resource.type="businessaicode.googleapis.com/BAICInstance"' \
  --use-partitioned-tables \
  --project="${PROJECT_ID}" 2>/dev/null || echo "Sink '${SINK_NAME}' already exists."

# 3. Get Sink Writer Service Account & Grant IAM Permissions
LOG_SINK_SA="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-logging.iam.gserviceaccount.com"
echo "Granting BigQuery Data Editor IAM role to Logging Sink SA (${LOG_SINK_SA})..."

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="${LOG_SINK_SA}" \
  --role="roles/bigquery.dataEditor" \
  --condition=None 2>/dev/null || echo "IAM binding already configured or permission granted."

# 4. Create Log-Based Metric
echo "Creating Log-Based Metric '${LOG_METRIC_NAME}'..."
gcloud logging metrics create "${LOG_METRIC_NAME}" \
  --description="Counter metric tracking active Antigravity users and requests" \
  --log-filter='resource.type="businessaicode.googleapis.com/BAICInstance"' \
  --project="${PROJECT_ID}" 2>/dev/null || echo "Log-Based Metric '${LOG_METRIC_NAME}' already exists."

echo "=== Infrastructure setup completed successfully! ==="
