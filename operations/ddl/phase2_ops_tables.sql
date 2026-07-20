-- DESIGN ONLY — do not execute without explicit approval on the company PC.
-- Proposed dataset: operations_manufacturing (US), separate from Raw and Analytics.
-- Retention must be explicitly confirmed against the BigQuery Sandbox 60-day limit before execution.

create schema if not exists `aeroprecision-data-pipeline.operations_manufacturing`
options(location = 'US');

create table if not exists `aeroprecision-data-pipeline.operations_manufacturing.ops_rfq_requests` (
  rfq_id string not null, request_payload_json json not null, payload_hash string not null,
  request_status string not null, workflow_execution_id string, trace_id string not null,
  calculation_version string not null, created_at timestamp not null, updated_at timestamp not null
) partition by date(created_at) cluster by rfq_id, request_status;

create table if not exists `aeroprecision-data-pipeline.operations_manufacturing.ops_quote_calculations` (
  quote_id string not null, rfq_id string not null, calculation_version string not null, input_hash string not null,
  material_cost_usd numeric, labor_cost_usd numeric, unit_cost_usd numeric, total_cost_usd numeric,
  minimum_cfo_approved_price_usd numeric, proposed_quote_price_usd numeric,
  realized_gross_margin_pct numeric, cfo_target_gross_margin_pct numeric,
  is_margin_compliant bool, decision_code string not null, calculated_at timestamp not null
) partition by date(calculated_at) cluster by rfq_id, decision_code;

create table if not exists `aeroprecision-data-pipeline.operations_manufacturing.ops_quote_decisions` (
  decision_id string not null, rfq_id string not null, quote_id string not null,
  decision_code string not null, decision_reason string, decision_hash string not null,
  calculation_version string not null, created_at timestamp not null
) partition by date(created_at) cluster by rfq_id, decision_code;

create table if not exists `aeroprecision-data-pipeline.operations_manufacturing.ops_ai_generations` (
  generation_id string not null, rfq_id string not null, quote_id string not null, trace_id string not null,
  prompt_version string not null, model string not null, input_classification string not null,
  input_hash string not null, output_hash string, output_status string not null, loop_attempt int64 not null,
  token_input int64, token_output int64, cost_usd numeric, latency_ms int64, stop_reason string, created_at timestamp not null
) partition by date(created_at) cluster by rfq_id, output_status;

create table if not exists `aeroprecision-data-pipeline.operations_manufacturing.ops_human_approvals` (
  approval_id string not null, rfq_id string not null, quote_id string not null, payload_hash string not null,
  calculation_version string not null, prompt_version string, approver_id string, decision string not null,
  reason string, approval_expires_at timestamp not null, decided_at timestamp, created_at timestamp not null
) partition by date(created_at) cluster by rfq_id, decision;

create table if not exists `aeroprecision-data-pipeline.operations_manufacturing.ops_workflow_audit_log` (
  event_id string not null, rfq_id string, quote_id string, workflow_execution_id string, trace_id string,
  event_type string not null, event_status string not null, event_hash string, actor_type string not null,
  actor_id string, reason string, created_at timestamp not null
) partition by date(created_at) cluster by rfq_id, event_type, event_status;

-- Duplicate prevention is enforced by a transactional idempotency check on rfq_id.
-- BigQuery primary-key constraints must not be assumed to enforce uniqueness.
