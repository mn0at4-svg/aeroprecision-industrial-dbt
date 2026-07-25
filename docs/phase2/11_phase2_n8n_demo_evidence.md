# Phase 2 n8n Local RFQ Automation Evidence

## Status

Phase 2 provides a local, security-focused RFQ quotation automation demo.

The verified core path covers deterministic RFQ validation, BigQuery product-cost retrieval, deterministic quotation calculation, local Ollama explanation generation, post-AI validation, explicit Human Approval, duplicate prevention, and local audit persistence.

The workflow export is sanitized. Credentials, private keys, tokens, personal account metadata, and n8n internal project metadata are not included.

## Architecture

1. Receive a synthetic L1 RFQ.
2. Validate required fields, types, ranges, dates, channels, and unexpected fields.
3. Read the product cost master from BigQuery with a read-only service account.
4. Calculate material cost, labor cost, total cost, CFO minimum price, and realized gross margin using deterministic code.
5. Generate explanatory text using local Ollama and qwen3:8b.
6. Validate the structured AI output and prohibit AI-generated numeric or approval decisions.
7. Revalidate prices, margins, and CFO rules using deterministic code.
8. Require explicit Human Approval.
9. Prevent duplicate RFQ persistence by rfq_id.
10. Persist approved synthetic demo records to an n8n local Data Table.

## Verified Deterministic Result

Synthetic product:

- product_id: AP-ACT-001
- requested_quantity: 100
- material_cost_usd: 344.06
- labor_cost_usd: 527.00
- unit_cost_usd: 871.06
- total_cost_usd: 87,106.00
- minimum_cfo_approved_price_usd: 120,312.15
- proposed_quote_price_usd: 125,000.00
- realized_gross_margin_pct: 30.00%
- cfo_target_gross_margin_pct: 27.60%
- is_margin_compliant: true

The LLM does not calculate or modify these values.

## Bounded-Loop Evidence

| Scenario | Attempts | Input tokens | Output tokens | Elapsed time | Result |
|---|---:|---:|---:|---:|---|
| First-attempt success | 1 | 412 | 167 | 7,144 ms | PASS |
| First validation failure, second success | 2 | 887 | 261 | 9,876 ms | PASS |
| Forced validation failure on all attempts | 3 | 1,369 | 357 | 12,025 ms | FAIL CLOSED |

Controls verified:

- Maximum attempts: 3
- Per-call timeout: 60 seconds
- Total loop timeout: 180 seconds
- Fourth LLM call after attempt 3: 0
- Local LLM API cost: USD 0
- Human Approval eligibility after terminal AI failure: NOT_ELIGIBLE
- Persistence after terminal AI failure: blocked

## Human Approval and Idempotency Evidence

Verified behavior:

- Calculation and AI validation do not finalize a quotation.
- Approval payload includes a SHA-256 hash, calculation version, prompt version, and expiration.
- An approver ID, decision, reason, and timestamp are recorded.
- Approved synthetic RFQs can be persisted locally.
- A repeated rfq_id is classified as DUPLICATE and blocked.
- Invalid or expired approval data fails closed.

## Security Boundaries

- LLM input is limited to L1 synthetic data.
- Ollama has no BigQuery, file, IAM, notification, or persistence authority.
- BigQuery product access uses a read-only service account.
- BigQuery Sandbox remains unbilled.
- BigQuery DML persistence is not used because Sandbox rejects DML without billing.
- Approved demo records are stored only in a local n8n Data Table.
- No customer notification, email, Slack, Teams, or external delivery is enabled.
- No workflow is published or externally exposed.
- Secrets are excluded from Git.

## Webhook Status

The local test Webhook successfully received a synthetic POST request, and the request body was extracted and passed through strict schema validation.

The Webhook-to-existing-workflow end-to-end merge remains deferred because the n8n editor test execution did not schedule the shared downstream path consistently. The fully verified demo path therefore remains the manual synthetic trigger.

This limitation does not affect the verified deterministic calculation, bounded-loop, Human Approval, duplicate prevention, or fail-closed evidence.

## Persistence Decision

The proposed BigQuery operational DDL remains a version-controlled design artifact.

For this Sandbox portfolio demo:

- BigQuery is read-only.
- Local n8n Data Tables provide reversible synthetic persistence.
- Production BigQuery DML requires a separately approved billing and deployment decision.

## Workflow Artifact

The sanitized workflow export is stored at:

`workflows/phase2/rfq-quotation-local.workflow.json`

Credentials must be recreated and attached locally after import. The export intentionally contains no credential values.
