# Phase 2 Human Approval and audit specification

## Approval payload

Before a quote can be finalized, the reviewer must see:

- `rfq_id`, `quote_id`, and `workflow_execution_id`
- `payload_hash`, `calculation_version`, and `prompt_version`
- Deterministic total cost, CFO minimum, proposed price, actual margin, and `decision_code`
- Requested discount and high-quantity review flag where present
- Approval deadline and the complete explanation draft marked as non-authoritative

## Required decision record

| Field | Requirement |
|---|---|
| `approver_id` | Required named user ID; never free-text only. |
| `decision` | `APPROVED`, `REJECTED`, or `EXPIRED`. |
| `reason` | Required for rejection, exception, timeout, or any review-required RFQ. |
| `decided_at` | UTC timestamp recorded by the system. |
| `payload_hash` | Must exactly match the approval-screen payload. |

## Fail-closed rules

- Missing hash, mismatched hash, missing approver ID, or expired deadline prevents finalization.
- Any audit-log write failure stops processing before a notification or external send.
- A decision from a previous payload, prompt version, or calculation version cannot be reused.
- Human approval is a final gate; it does not let an LLM change numeric policy.
