# Phase 3 Langfuse Observability Design

- Status: Proposed
- Date: 2026-07-27
- Scope: Phase 3 design only
- Implementation: Not included in this document change

## 1. Purpose

Add LLM observability to the validated Phase 2 manual RFQ path without changing deterministic quotation calculations, CFO rules, bounded LLM retries, Human Approval, or idempotency controls.

Langfuse is an observability destination only. Langfuse observations, scores, and availability must never become inputs to quotation prices, CFO compliance, or Human Approval decisions.

## 2. Selected deployment

- Deployment: Local self-hosted Langfuse
- Runtime: Windows Docker Desktop and Docker Compose
- Network exposure: localhost only
- Cloud telemetry transmission: none
- Data classification: L0 and L1 synthetic data only
- Current official self-hosted release candidate: v3.224.1
- Exact image tags and digests: to be verified and pinned in the implementation PR
- High availability, public exposure, and production SLA: out of scope

The official Docker Compose architecture includes Langfuse Web, Langfuse Worker, Postgres, ClickHouse, Redis, and MinIO-compatible object storage.

Official references:

- https://langfuse.com/self-hosting
- https://langfuse.com/self-hosting/deployment/docker-compose
- https://github.com/langfuse/langfuse/releases/latest
- https://github.com/langfuse/langfuse/blob/main/docker-compose.yml

## 3. Ingestion decision

n8n will use an HTTP Request node to send OpenTelemetry OTLP/HTTP payloads to:

`/api/public/otel/v1/traces`

The deprecated Langfuse Ingestion API and legacy trace, span, generation, and event endpoints must not be used.

The exact authentication header and OTLP payload contract must be validated against the pinned server version before implementation.

No Python or Node.js helper service will be added in the initial implementation.

## 4. Existing safety boundaries

Phase 3 must not change the following controls:

1. LLMs do not calculate prices, costs, margins, or CFO minimum prices.
2. LLMs do not approve or reject quotations.
3. Existing deterministic code remains the calculation source of truth.
4. Langfuse scores and outputs are never decision inputs.
5. Post-AI deterministic revalidation remains mandatory.
6. LLM retries remain limited to 3 attempts.
7. The per-attempt limit remains 60 seconds.
8. The total LLM loop limit remains 180 seconds.
9. Invalid, timed-out, unverifiable, or exhausted LLM output fails closed.
10. Persistence remains blocked until valid Human Approval.
11. BigQuery remains read-only.
12. External webhook publication and notifications remain out of scope.

## 5. Trace identity

The existing Phase 2 business trace identifier remains unchanged:

`RFQ-2026-00001:phase2-calc-v1`

OpenTelemetry requires a 32-character lowercase hexadecimal trace ID. Therefore, two identifiers will be retained:

- `business_trace_id`: existing Phase 2 identifier
- `otel_trace_id`: first 32 lowercase hexadecimal characters of SHA-256 over `aeroprecision|business_trace_id`

The existing identifier is not replaced or discarded. It is retained as allowlisted metadata.

Each span ID will be the first 16 lowercase hexadecimal characters of SHA-256 over:

`business_trace_id|workflow_execution_id|observation_name|attempt|event_sequence`

A zero-only trace ID or span ID is invalid and must fail validation.

## 6. Naming contract

### Trace

- `rfq-quotation`

### Generation

- `ollama-quote-explanation`
- One generation per actual LLM attempt
- Attempt count and generation count must match

### Spans and events

- `deterministic-calculation`
- `cfo-compliance-gate`
- `ai-output-validation`
- `retry-decision`
- `post-ai-revalidation`
- `human-approval-pending`
- `human-approval-decision`
- `idempotency-check`
- `local-persistence`
- `fail-closed`

### Scores

- `schema_valid`
- `policy_valid`
- `numeric_revalidation_passed`
- `human_approved`
- `prompt_injection_blocked`

Scores are observation-only values and must never alter workflow routing, quotation values, CFO compliance, or approval outcomes.

## 7. Observation data allowlist

Only the following fields may be sent to Langfuse:

### Identity and versions

- `business_trace_id`
- `otel_trace_id`
- `rfq_id`
- `workflow_execution_id`
- `calculation_version`
- `prompt_version`
- `request_channel`
- `data_classification`

### LLM execution

- `llm_provider`
- `llm_model`
- `llm_attempt`
- `llm_max_attempts`
- `llm_timeout_ms`
- `llm_loop_timeout_ms`
- `input_hash`
- `output_hash`
- `input_length`
- `output_length`
- `prompt_tokens`
- `output_tokens`
- `latency_ms`
- `cost_usd`
- `started_at`
- `completed_at`

### Validation and workflow state

- `validation_status`
- `validation_error_codes`
- `retry_decision`
- `loop_stop_reason`
- `fail_closed_reason`
- `human_approval_status`
- `human_decision`
- `idempotency_status`
- `persistence_status`
- `telemetry_status`

Validation errors must be stable error codes. Raw rejected content must not be included.

## 8. Denylist

The following data must not be sent:

- Raw prompts
- Raw LLM outputs
- Customer explanations
- Internal rationale text
- Negotiation option text
- Exception reason free text
- Customer names
- Sales representative names
- Approver names or email addresses
- Human decision free-text reason
- Monetary prices, costs, rates, discounts, or margins
- BigQuery credentials
- n8n credentials
- API keys
- Passwords
- OAuth tokens
- Webhook secrets
- Private keys
- Service account JSON
- `.env` content
- L2 or L3 data

Hashes, lengths, token counts, enumerated statuses, and stable validation error codes are used instead.

## 9. Raw prompt and output policy

Raw prompt and raw output storage is disabled by design.

Langfuse receives only:

- SHA-256 hashes
- Character lengths
- Token counts
- Model and version metadata
- Validation status and error codes

Redaction must happen deterministically in n8n before the HTTP Request node. Server-side masking must not be relied upon because it may require an Enterprise license.

## 10. Langfuse failure policy

Langfuse is not allowed to change calculation or CFO behavior.

Initial telemetry limits:

- HTTP timeout: 2,000 ms per telemetry request
- Automatic telemetry retries: 0
- LLM retry budget consumed by telemetry failure: 0

If Langfuse is unavailable or times out:

1. Deterministic calculation and CFO checks remain unchanged.
2. No additional LLM attempt is triggered.
3. `telemetry_status` becomes `FAILED`.
4. `fail_closed_reason` becomes `LANGFUSE_UNAVAILABLE` or `LANGFUSE_TIMEOUT`.
5. Existing local Phase 2 audit fields remain available.
6. The quotation is routed to Human Review.
7. A Human Decision may be collected for review evidence.
8. Final persistence is blocked with `OBSERVABILITY_AUDIT_INCOMPLETE`.
9. No notification, external transmission, or customer action occurs.

This policy prevents observability failure from weakening an existing safety boundary.

## 11. Secrets and local configuration

- Langfuse project credentials: n8n Credentials only
- Credentials in workflow export: prohibited
- Actual Docker environment file: `%USERPROFILE%\.aeroprecision-secrets\langfuse.env`
- Actual environment file in Git repository: prohibited
- Git may contain only placeholder examples with no usable values
- Docker Compose secrets must be long and randomly generated
- Secrets must not be copied between company and home PCs

## 12. Retention

Automatic self-hosted Data Retention is not assumed because the official feature requires Enterprise Edition.

Phase 3 OSS policy:

- Operational target: 30 days
- Data type: L0/L1 synthetic data only
- Default automatic deletion: not available
- Automatic destructive cleanup: not implemented
- Manual cleanup procedure: documented in a later implementation runbook
- Actual deletion: requires explicit user confirmation
- Portfolio evidence must be captured before deletion

## 13. Time and network rules

- Trace timestamps: UTC
- User interface timezone: presentation only
- Langfuse UI: localhost only
- n8n: remains bound to `127.0.0.1:5678`
- Langfuse UI candidate: `127.0.0.1:3000`
- No firewall opening
- No public IP
- No external webhook

## 14. Planned Git placement

- `docs/phase3/01_langfuse_observability_design.md`
- `docs/phase3/02_synthetic_observability_test_plan.md`
- `infra/langfuse/` only after design approval
- Sanitized workflow export only after implementation
- Secrets and runtime volumes are never committed

## 15. Implementation gates

Implementation may begin only after:

1. This design is reviewed.
2. The synthetic test plan is reviewed.
3. Exact Langfuse and dependency versions are verified.
4. Ports are checked again.
5. Container and volume creation is explicitly approved.
6. Secret storage locations are explicitly approved.
7. No unresolved change exists in the Phase 2 calculation contract.
