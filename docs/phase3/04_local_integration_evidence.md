# Phase 3 Local Integration Evidence

## Scope

- Workflow: `Phase 3 RFQ ? Langfuse Observability`
- Test data: one L1 synthetic RFQ
- Deployment: local n8n, local Ollama `qwen3:8b`, local self-hosted Langfuse
- Workflow state: inactive after testing

## Verified safety controls

- Invalid RFQ input is routed to `Fail Closed (Invalid RFQ)`.
- Missing proposal price is routed to `Review Required (CFO Failed)`.
- A valid deterministic candidate price is preserved through the product-master lookup and calculation path.
- CFO-compliant RFQ processing can proceed to the bounded Ollama loop.
- LLM output is deterministically validated before Human Approval.
- Langfuse generation payload sends only L0/L1 allowlisted metadata and hashes.
- Raw prompt and raw model output are not stored in Langfuse.
- Langfuse ingestion was accepted with HTTP 200.
- Langfuse send failure is configured to continue on the regular output path.
- Human Approval remains the boundary before persistence; no approval decision or persistence action was taken during this test.

## Verified observability fields

- business trace ID and workflow execution ID
- calculation version and prompt version
- provider, model, attempt, and maximum attempts
- input/output hashes and lengths
- prompt/output tokens, latency, and local zero cost
- validation status, validation errors, retry decision, and loop stop reason
- data classification, environment, service name, and scope version

## Synthetic first-attempt success evidence

- Model: `qwen3:8b`
- Attempts: `1 / 3`
- Prompt tokens: `412`
- Output tokens: `164`
- Latency: approximately `14.1 seconds`
- Cost: `0 USD`
- Validation status: `PASS`
- Retry decision: `STOP_SUCCESS`
- Loop stop reason: `FIRST_ATTEMPT_PASS`

## Exclusions

- No RAG, BigQuery DML, external webhook publication, notification, customer send, or production deployment.
- No pricing, cost, margin, CFO, approval, or persistence decision is delegated to Langfuse or the LLM.
