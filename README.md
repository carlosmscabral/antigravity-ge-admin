# Google Antigravity Enterprise Observability with Gemini Enterprise

[![GCP BigQuery](https://img.shields.io/badge/GCP-BigQuery-blue.svg)](https://cloud.google.com/bigquery)
[![Gemini Enterprise](https://img.shields.io/badge/Gemini-Enterprise-purple.svg)](https://antigravity.google/docs/enterprise)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An end-to-end, automated enterprise observability implementation for **Google Antigravity** developer telemetry. This repository provides automated log parsing, Cloud Logging sinks, BigQuery storage, analytical views, and integration with **Gemini Enterprise** via a Native BigQuery Data Agent (A2A protocol).

---

## 🏛️ Architecture Overview

```
+---------------------------------------------------------------------------------------------------+
| DEVELOPER ENVIRONMENT                                                                             |
|  [ Developer ] ---> ( Antigravity IDE Extension / CLI )                                           |
+---------------------------------------------------------------------------------------------------+
                                   | (1. Inference Request)
                                   v
+---------------------------------------------------------------------------------------------------+
| GCP PROJECT: vibe-cabral                                                                          |
|                                                                                                   |
|  +-----------------------+      +---------------------------+      +---------------------------+  |
|  | BAICInstance Endpoint | ---> | Cloud Logging             | ---> | BigQuery Dataset          |  |
|  |                       |      | (antigravity_obs_sink)    |      | (antigravity_observability|  |
|  +-----------------------+      +---------------------------+      +---------------------------+  |
|                                                                                  |                |
|                                                                                  v                |
|                                                                    +---------------------------+  |
|                                                                    | SQL Analytics Views       |  |
|                                                                    | - vw_inference_responses  |  |
|                                                                    | - vw_user_token_usage_daily|  |
|                                                                    | - vw_active_users_summary |  |
|                                                                    +---------------------------+  |
|                                                                                  |                |
|                                                                                  v                |
|                                                                    +---------------------------+  |
|                                                                    | Native BQ Data Agent      |  |
|                                                                    | (BigQuery Studio Canvas)  |  |
|                                                                    +---------------------------+  |
+---------------------------------------------------------------------------------------------------+
                                                                                   ^
                                                                                   | (A2A + OAuth2)
+----------------------------------------------------------------------------------+----------------+
| GEMINI ENTERPRISE                                                                                 |
|  [ Platform Admin ] ---> ( Gemini Enterprise App: cabral-demo-ge )                                |
+---------------------------------------------------------------------------------------------------+
```

Detailed architecture diagrams and sequence flows are documented in [`docs/ARCHITECTURE_AND_FLOWS.md`](docs/ARCHITECTURE_AND_FLOWS.md).

---

## 🚀 Quickstart Guide

### 1. Configure Environment Variables
Copy `.env.example` to `.env` and set your GCP project details:
```bash
cp .env.example .env
```

Edit `.env`:
```bash
PROJECT_ID="your-gcp-project-id"
PROJECT_NUMBER="123456789012"
LOCATION="US"
DATASET_ID="antigravity_observability"
SINK_NAME="antigravity_observability_sink"
LOG_METRIC_NAME="businessaicode-users"
ENGINE_ID="your-gemini-enterprise-engine-id"
```

### 2. Run Automated One-Command Setup
Execute the master setup script:
```bash
./setup.sh
```

This script automatically:
1. Provisions the BigQuery dataset and Cloud Logging sink.
2. Binds required BigQuery IAM roles to the Logging Sink Writer Service Account (`roles/bigquery.dataEditor`).
3. Creates log-based metrics for active users.
4. Exports and backfills existing Cloud Logging records into BigQuery.
5. Re-creates all 3 analytical SQL views (`vw_inference_responses`, `vw_user_token_usage_daily`, `vw_active_users_summary`).

---

## 📚 Detailed Documentation & Runbooks

- [**Complete End-to-End Setup Guide**](docs/ENTERPRISE_OBSERVABILITY_SETUP_GUIDE.md): Detailed walkthrough for setting up the Native BigQuery Data Agent, System Instructions, Golden SQL Queries, GCP OAuth 2.0 Web Client credentials, and Gemini Enterprise A2A registration.
- [**Architecture & Visual Flows**](docs/ARCHITECTURE_AND_FLOWS.md): C4 system diagrams, data flow sequence diagrams, schema transformation walks, and A2A handshake sequence diagrams.

---

## 🛠️ Repository Structure

```
.
├── .env.example                       # Environment variable template
├── setup.sh                           # Master automated setup script
├── docs/
│   ├── ARCHITECTURE_AND_FLOWS.md      # Visual architecture & sequence diagrams
│   └── ENTERPRISE_OBSERVABILITY_SETUP_GUIDE.md  # Detailed setup guide & runbook
└── scripts/
    ├── 01_setup_bq_and_sink.sh        # Infrastructure & IAM provisioning
    ├── 02_create_bq_views.sh          # BigQuery SQL views creation
    ├── 03_publish_a2a_agent.sh        # A2A agent registration helper
    └── backfill_logs.py               # Historical log export & ingestion script
```

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
