# Phase 2: RFQ quotation automation — approved design baseline

Status: **Approved for design. No cloud resource, credential, or workflow is created by this document.**

## Scope

Phase 2 receives an RFQ, validates it, reads product costs, calculates pricing and CFO compliance deterministically, produces an optional explanation draft, and waits for explicit human approval. No approval, BigQuery write, notification, external send, or final quote is automatic.

## Approved baseline

| Decision | Baseline |
|---|---|
| n8n runtime | Local Docker on the company PC for implementation; no public webhook in the design stage. |
| LLM provider | OpenAI API, explanation-only, structured output, no tools or write access. |
| Human approval | n8n UI initially; email/Slack/Teams are not connected in Phase 2. |
| Loop data classification | L0/L1 synthetic data only. L2/L3 data never enters an LLM loop. |
| Surcharge | Decimal range `-0.05` through `0.15`. Negative value is a recorded market adjustment. |
| Quantity | Integer range `1` through `100000`; quantity `501+` is `REVIEW_REQUIRED_HIGH_QUANTITY`. |
| Requested discount | Recorded for audit and explanation only. It never changes price automatically. |
| Provisional price | `proposed_quote_price_usd = minimum_cfo_approved_price_usd`. |

## Non-negotiable controls

- SQL or deterministic code calculates cost, price, margin, and decision code. LLM output is never an input to those calculations.
- Validation failure, timeout, schema mismatch, suspected prompt injection, or audit-log failure stops processing and enters `FAILED_CLOSED`.
- A normal LLM improvement loop allows at most three calls, 60 seconds per call and 180 seconds overall.
- A retry with the same `rfq_id` returns the existing state rather than creating a second calculation, decision, or approval.
- Human approval displays the payload hash, calculation version, prompt version, and expiry. An expired approval cannot execute.

## Implementation boundary

Today’s artefacts are safe to create on a home PC. Docker, credentials, API billing, BigQuery DDL execution, service accounts, webhook exposure, and integration testing are company-PC-only tasks requiring explicit confirmation.
