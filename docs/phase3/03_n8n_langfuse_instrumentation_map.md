# Phase 3 n8n Langfuse Instrumentation Map

## 1. Scope

Add LLM observability without changing the Phase 2 deterministic pricing,
CFO compliance, Human Approval, retry, idempotency, or persistence boundaries.

## 2. Trace contract

- Trace name: `rfq-quotation`
- Business trace ID: `{rfq_id}:{calculation_version}`
- OTEL trace ID: first 32 hexadecimal characters of the SHA-256 business trace ID
- Environment: `development`
- Data sent to Langfuse: L0/L1 allowlisted metadata only
- Raw prompt and raw output: prohibited

## 3. Observation names

- Root span: `rfq-quotation`
- Generation: `ollama-quote-explanation`
- Supporting spans:
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

Each LLM attempt creates exactly one generation. Attempt number is metadata,
not part of the generation name.

## 4. Placement

1. Initialize trace context after deterministic calculation and before the CFO gate.
2. Hash each allowlisted LLM request before its Ollama HTTP node.
3. Hash each raw LLM response after its deterministic validation node.
4. Emit each generation from an isolated observability branch.
5. Emit approval, idempotency, persistence, and fail-closed spans from isolated branches.
6. Keep disconnected BigQuery DML scaffolds disconnected.

## 5. Allowlist

- trace ID and workflow execution ID
- RFQ ID
- calculation and prompt versions
- provider and model
- attempt and maximum attempts
- input and output SHA-256
- input and output lengths
- prompt and output tokens
- latency and zero local-model cost
- validation status and validation errors
- retry decision and loop stop reason
- fail-closed reason
- Human Approval result
- idempotency and persistence result
- data classification and request channel

## 6. Denylist

- raw prompt or raw LLM output
- customer free-form text
- price, cost, margin, and CFO minimum values
- L2/L3 data
- credentials, API keys, tokens, secrets, and `.env` contents

## 7. Failure boundary

Langfuse failure must not modify calculation, CFO rules, retry limits, or Human
Approval. It must never cause automatic approval or persistence. The business
workflow retains its existing deterministic and fail-closed behavior.

## 8. Scores

Scores are informational only and use the dedicated Langfuse Scores API after
trace ingestion is verified. Scores are never connected back to pricing or
approval branches.

## 9. Implementation gate

The inactive n8n workflow is not modified until an L0-only OTLP canary confirms
the endpoint, authentication, hierarchy, attributes, and redaction behavior.
