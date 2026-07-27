# Phase 3 Synthetic Observability Test Plan

- Status: Proposed
- Date: 2026-07-27
- Data classification: L0/L1 synthetic only
- Execution path: Validated Phase 2 Manual Trigger path

## 1. Purpose

Verify that Langfuse provides traceable LLM observability without changing deterministic quotation calculations, CFO rules, bounded retries, Human Approval, or idempotency controls.

This plan does not authorize Langfuse installation or workflow modification.

## 2. Global assertions

Every test must satisfy all applicable assertions:

1. LLM attempts never exceed 3.
2. Each LLM attempt has exactly one generation.
3. No fourth LLM call occurs.
4. The per-attempt timeout remains 60 seconds.
5. The full LLM loop timeout remains 180 seconds.
6. Deterministic quotation results match Phase 2.
7. Langfuse data never affects prices or approvals.
8. Raw prompts and outputs are not transmitted.
9. Monetary values are not transmitted.
10. L2/L3 data is not transmitted.
11. Credentials and secrets are not transmitted.
12. Human Approval remains required before persistence.
13. Unapproved external operations remain zero.
14. Langfuse failure does not trigger an LLM retry.
15. Scores are not used for workflow routing.

## 3. Synthetic test cases

| ID | Scenario | Expected generations | Expected terminal result |
|---|---|---:|---|
| P3-T01 | First LLM attempt succeeds | 1 | Human Approval eligible |
| P3-T02 | First attempt fails, second succeeds | 2 | Human Approval eligible |
| P3-T03 | All three attempts fail | 3 | Fail closed |
| P3-T04 | CFO margin violation | 0 | Review Required |
| P3-T05 | Post-AI numeric revalidation fails | 1 to 3 | Fail closed |
| P3-T06 | Human Approval APPROVED | Based on LLM path | Approved result observed |
| P3-T07 | Human Approval REJECTED | Based on LLM path | Rejected result observed |
| P3-T08 | Human Approval EXPIRED | Based on LLM path | Persistence blocked |
| P3-T09 | Duplicate RFQ ID | Based on first execution | Duplicate persistence blocked |
| P3-T10 | Synthetic prompt injection | Maximum 3 | Policy result observed |
| P3-T11 | Langfuse unavailable | Unchanged from LLM path | Audit incomplete, persistence blocked |
| P3-T12 | Langfuse request timeout | Unchanged from LLM path | Audit incomplete, persistence blocked |
| P3-T13 | Redaction canary strings | Based on LLM path | Canary values absent |
| P3-T14 | Same RFQ trace submitted again | No duplicate trace identity | Idempotency result observed |
| P3-T15 | Workflow export and repository scan | Not applicable | No secrets found |

## 4. Detailed expectations

### P3-T01 First-attempt success

- One `ollama-quote-explanation` generation
- `llm_attempt = 1`
- `validation_status = PASS`
- `retry_decision = STOP_SUCCESS`
- Tokens, latency, hashes, and zero local-model API cost visible

### P3-T02 Retry success

- Two generations under the same trace
- Attempts are 1 and 2
- Attempt 1 has stable validation error codes
- Attempt 2 passes
- No third attempt

### P3-T03 Retry exhaustion

- Exactly three generations
- `loop_stop_reason` records exhaustion or validation failure
- Human Approval is not eligible
- Persistence is blocked
- No fourth attempt

### P3-T04 CFO violation

- Deterministic CFO span exists
- No LLM generation exists
- Result remains Review Required
- Langfuse does not override CFO logic

### P3-T05 Post-AI revalidation failure

- Generation exists for each actual LLM call
- `numeric_revalidation_passed = 0`
- `fail-closed` observation exists
- Persistence is blocked

### P3-T06 to P3-T08 Human Approval

The trace distinguishes:

- `APPROVED`
- `REJECTED`
- `EXPIRED`

No approver name, email, or free-text reason is transmitted.

### P3-T09 Duplicate RFQ

Expected metadata:

- `idempotency_status = DUPLICATE`
- `persistence_status = BLOCKED`
- `loop_stop_reason = DUPLICATE_RFQ_ID`

No second persistence occurs.

### P3-T10 Prompt injection

Use only an L1 synthetic injection string.

Expected behavior:

- No tool or external side effect is granted to the LLM
- Maximum three attempts
- Stable policy result recorded
- Raw attack text absent from Langfuse
- `prompt_injection_blocked` is observation-only

### P3-T11 and P3-T12 Langfuse failure

Expected behavior:

- Deterministic calculation remains unchanged
- CFO result remains unchanged
- LLM attempt count remains unchanged
- `telemetry_status = FAILED`
- Correct failure reason recorded locally
- Human Review may occur
- Final persistence is blocked
- No external operation occurs

### P3-T13 Redaction

Use synthetic canaries shaped like:

- fake API key
- fake customer name
- fake email address
- fake monetary field
- fake raw prompt marker

Search Langfuse UI and exported evidence. All canary values must be absent. Hashes and lengths may be present.

### P3-T14 Trace idempotency

- Existing Phase 2 `business_trace_id` remains stable
- Derived `otel_trace_id` remains stable
- The duplicate execution does not create a second business trace identity
- Duplicate status is visible

### P3-T15 Secret scan

Scan:

- Phase 3 documentation
- Sanitized workflow export
- Future compose examples
- Git diff

The scan must find no usable secret, token, password, private key, credential ID, or `.env` content.

## 5. Required observations

A completed trace must make the following fields inspectable when applicable:

- Business trace ID
- OpenTelemetry trace ID
- Workflow execution ID
- Calculation version
- Prompt version
- Model
- Attempt and maximum attempts
- Input and output hashes
- Prompt and output tokens
- Latency
- Cost
- Validation status and error codes
- Retry decision
- Loop stop reason
- Fail-closed reason
- Human Approval result
- Idempotency result
- Persistence result
- Telemetry status

## 6. Completion criteria

Phase 3 is complete only when:

1. One RFQ has a stable unique trace.
2. Each LLM attempt appears as one generation.
3. First success, retry success, and three-attempt failure are distinguishable.
4. Human Approval outcomes are distinguishable.
5. Fail-closed behavior is visible.
6. Idempotency and persistence results are visible.
7. Hashes, tokens, latency, model, and versions are visible.
8. L0/L1 allowlist enforcement passes.
9. Raw prompt and output absence is verified.
10. Secret scanning passes.
11. Langfuse failure and timeout tests pass.
12. Phase 2 deterministic tests continue to pass.
13. Sanitized evidence is committed through PR and CI.
14. No unapproved external action occurs.

## 7. Evidence to retain

- Sanitized Langfuse trace screenshots
- Sanitized generation screenshots
- Test result summary
- Token and latency comparison
- Fail-closed evidence
- Human Approval evidence
- Idempotency evidence
- Secret scan result
- Sanitized workflow export
- PR and CI result

Screenshots must be reviewed for secrets and disallowed data before Git registration.
