#!/usr/bin/env bash
set -e

# Load environment variables from .env if present
if [ -f "$(dirname "$0")/../.env" ]; then
  source "$(dirname "$0")/../.env"
fi

PROJECT_ID="${PROJECT_ID:-vibe-cabral}"
DATASET_ID="${DATASET_ID:-antigravity_observability}"

echo "=== Creating BigQuery SQL Views for Antigravity Observability ==="
echo "Project ID: ${PROJECT_ID}"
echo "Dataset ID: ${DATASET_ID}"
echo "----------------------------------------------------"

# 1. View for parsed inference responses
echo "Creating view vw_inference_responses..."
bq query --use_legacy_sql=false --project_id="${PROJECT_ID}" "
CREATE OR REPLACE VIEW \`${PROJECT_ID}.${DATASET_ID}.vw_inference_responses\` AS
SELECT
  timestamp,
  receiveTimestamp,
  insertId,
  JSON_VALUE(labels.user_id) AS user_id,
  JSON_VALUE(labels.trajectory_id) AS trajectory_id,
  JSON_VALUE(labels.request_id) AS request_id,
  JSON_VALUE(labels.client_name) AS client_name,
  JSON_VALUE(labels.client_version) AS client_version,
  JSON_VALUE(labels.model) AS model,
  JSON_VALUE(jsonPayload.experience) AS experience,
  SAFE_CAST(JSON_VALUE(jsonPayload.metadata.totalTokenCount) AS INT64) AS total_token_count
FROM
  \`${PROJECT_ID}.${DATASET_ID}.businessaicode_googleapis_com_inference_response\`
WHERE
  JSON_VALUE(jsonPayload.\`@type\`) = 'type.googleapis.com/google.cloud.businessaicode.logging.v1.InferenceResponseLog';
"

echo "View vw_inference_responses created."

# 2. View for daily user token usage summary
echo "Creating view vw_user_token_usage_daily..."
bq query --use_legacy_sql=false --project_id="${PROJECT_ID}" "
CREATE OR REPLACE VIEW \`${PROJECT_ID}.${DATASET_ID}.vw_user_token_usage_daily\` AS
SELECT
  DATE(timestamp) AS usage_date,
  JSON_VALUE(labels.user_id) AS user_id,
  JSON_VALUE(labels.client_name) AS client_name,
  JSON_VALUE(labels.client_version) AS client_version,
  JSON_VALUE(labels.model) AS model,
  COUNT(1) AS request_count,
  COUNT(DISTINCT JSON_VALUE(labels.trajectory_id)) AS trajectory_count,
  SUM(SAFE_CAST(JSON_VALUE(jsonPayload.metadata.totalTokenCount) AS INT64)) AS total_tokens,
  AVG(SAFE_CAST(JSON_VALUE(jsonPayload.metadata.totalTokenCount) AS INT64)) AS avg_tokens_per_request
FROM
  \`${PROJECT_ID}.${DATASET_ID}.businessaicode_googleapis_com_inference_response\`
WHERE
  JSON_VALUE(jsonPayload.\`@type\`) = 'type.googleapis.com/google.cloud.businessaicode.logging.v1.InferenceResponseLog'
GROUP BY
  usage_date, user_id, client_name, client_version, model;
"

echo "View vw_user_token_usage_daily created."

# 3. View for active users summary
echo "Creating view vw_active_users_summary..."
bq query --use_legacy_sql=false --project_id="${PROJECT_ID}" "
CREATE OR REPLACE VIEW \`${PROJECT_ID}.${DATASET_ID}.vw_active_users_summary\` AS
SELECT
  JSON_VALUE(labels.user_id) AS user_id,
  COUNT(DISTINCT JSON_VALUE(labels.trajectory_id)) AS total_sessions,
  COUNT(1) AS total_requests,
  SUM(SAFE_CAST(JSON_VALUE(jsonPayload.metadata.totalTokenCount) AS INT64)) AS total_token_consumption,
  MIN(timestamp) AS first_seen,
  MAX(timestamp) AS last_seen
FROM
  \`${PROJECT_ID}.${DATASET_ID}.businessaicode_googleapis_com_inference_response\`
WHERE
  JSON_VALUE(jsonPayload.\`@type\`) = 'type.googleapis.com/google.cloud.businessaicode.logging.v1.InferenceResponseLog'
GROUP BY
  user_id;
"

echo "View vw_active_users_summary created."
echo "=== BigQuery Views setup complete! ==="
