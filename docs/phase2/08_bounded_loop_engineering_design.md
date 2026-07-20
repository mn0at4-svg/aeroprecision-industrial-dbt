# Phase 2 bounded loop engineering design

## Purpose

The loop improves the **clarity and completeness of an explanation draft only**. It never changes cost, price, margin, CFO policy, decision code, approval status, database state, or external communications.

## Controlled loop

```text
Generate draft (attempt 1)
  -> deterministic quality and security evaluation
  -> ACCEPT: stop
  -> REVISE: issue a narrow revision request, then retry
  -> FAILED_CLOSED: stop and wait for human review
```

Limits:

- Maximum three LLM calls per RFQ, including the initial draft.
- Maximum 60 seconds per call and 180 seconds for the complete loop.
- Stop immediately on repeated output hash, no progress, timeout, invalid JSON, secret/PII detection, unexpected URL, control character, or prompt-injection signal.
- Only L0/L1 synthetic data may enter the loop. L2/L3 data is excluded.

## Deterministic evaluator

The evaluator returns one of three outcomes.

| Outcome | Meaning | Next action |
|---|---|---|
| `ACCEPT` | All required fields are present and quality/security checks pass. | Stop; display draft to human. |
| `REVISE` | No security issue, but a required field is missing or too short. | Retry only if attempts remain. |
| `FAILED_CLOSED` | Security signal, invalid structure, timeout, loop limit, repeated output, or evaluator error. | Stop; no external effect; human review required. |

Required draft fields are `customer_explanation`, `internal_rationale`, `negotiation_option`, and `risk_note`. The evaluator checks that each is a non-empty string and meets its minimum length. It does not judge prices or approvals.

## Metrics: loop off vs. loop on

Use identical synthetic RFQs and compare:

| Metric | Loop off | Loop on |
|---|---|---|
| First-draft creation time | Record | Record |
| Human edits per RFQ | Record | Record |
| Total handling time | Record | Record |
| LLM calls per RFQ | Baseline 1 | 1–3 maximum |
| Structured-output failure rate | Record | Record |
| Timeout rate | Record | Record |
| Tokens and cost | Record | Record |
| Unauthorized action, CFO modification, secret output | Must be 0 | Must be 0 |

The portfolio claim is not that the loop is autonomous. It is that the workflow uses bounded, deterministic quality gates and fail-closed behavior to improve a low-risk draft while preserving human authority.
