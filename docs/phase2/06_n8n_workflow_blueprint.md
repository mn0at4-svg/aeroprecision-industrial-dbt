# Phase 2 n8n workflow blueprint

Status: design only. This is not an n8n workflow export and does not expose a webhook.

## Node sequence and authority boundary

| Step | Node responsibility | May calculate or decide | May cause an external side effect |
|---:|---|---|---|
| 1 | Receive test RFQ | No | No |
| 2 | Reject unexpected fields and invalid schema | Deterministic validation only | No |
| 3 | Check input hashes, control characters, URLs, and L0/L1 eligibility | Deterministic security validation only | No |
| 4 | Read product master | No | Read-only BigQuery access only |
| 5 | Calculate costs, CFO minimum, margin, and decision code | Deterministic code only | No |
| 6 | Re-check calculation and policy values | Deterministic code only | No |
| 7 | Generate optional explanation draft | LLM text only; no tools | No |
| 8 | Validate structured LLM output and re-check all deterministic values | Deterministic code only | No |
| 9 | Create approval-screen payload | No | No |
| 10 | Wait for named human decision | Human only | No external notification in initial phase |
| 11 | Atomically write approved/rejected result and audit records | No | BigQuery write after human decision only |

## Fail-closed state transitions

```text
SCHEMA_INVALID / SECURITY_FLAG / PRODUCT_NOT_FOUND / CALCULATION_INVALID
  -> FAILED_CLOSED

LLM_TIMEOUT / LLM_SCHEMA_INVALID / LLM_OUTPUT_POLICY_CONFLICT / LOOP_LIMIT
  -> FAILED_CLOSED

MARGIN_VIOLATION / HIGH_QUANTITY / REQUESTED_DISCOUNT
  -> REVIEW_REQUIRED -> HUMAN_APPROVAL

POLICY_COMPLIANT
  -> PENDING_HUMAN_APPROVAL

HUMAN_APPROVED -> APPROVED_BY_HUMAN -> ATOMIC_BIGQUERY_WRITE
HUMAN_REJECTED -> REJECTED_BY_HUMAN -> ATOMIC_BIGQUERY_WRITE
HUMAN_EXPIRED -> EXPIRED -> ATOMIC_BIGQUERY_WRITE
```

## Idempotency design

- `rfq_id` is the business idempotency key.
- `payload_hash` is SHA-256 over canonicalized validated input.
- `quote_id` is deterministic from `rfq_id`, `payload_hash`, and `calculation_version`.
- Before the human gate, n8n keeps status only in its execution state and retains the execution record; it does not write an RFQ record to BigQuery.
- At the human decision gate, a single BigQuery transaction must check whether the `rfq_id` / `payload_hash` / decision already exists before inserting calculation, decision, approval, and audit rows.
- A retry returns the existing final decision when that combination already exists. A changed payload for the same `rfq_id` is `REVIEW_REQUIRED_DUPLICATE_CONFLICT`.

## LLM call envelope

- Input: computed non-authoritative explanation fields and L0/L1 synthetic data only.
- Output: schema-conforming explanation, internal rationale, negotiation options, and risk notes.
- Forbidden: prices, percentages, decision codes, tools, URLs, credentials, external calls, database queries, or approvals.
- Limits: maximum three calls, 60 seconds each, 180 seconds total, with a per-RFQ token and cost cap.
- Stop: identical output, no-progress output, timeout, invalid schema, secret/PII detection, unexpected URL, or prompt-injection signal.

## Initial approval screen

The screen must show the deterministic values, `decision_code`, payload hash, calculation version, prompt version, deadline, and a required decision/reason field. The LLM explanation is visually labelled as a draft and cannot alter the calculated result.

## Implementation checklist for company PC

1. Import reviewed workflow export into local Docker n8n.
2. Add n8n-only credentials through the UI; never commit them.
3. Run synthetic fixtures before any BigQuery write permission is granted.
4. Validate every failed path reaches `FAILED_CLOSED` without an unauthorized side effect.
5. Enable BigQuery write only for the final post-human-decision node.
