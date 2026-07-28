# Manufacturing RFQ Automation with AI Guardrails

[English](https://mn0at4-svg.github.io/aeroprecision-industrial-dbt/rfq-ai-guardrails/) | [日本語](https://mn0at4-svg.github.io/aeroprecision-industrial-dbt/rfq-ai-guardrails-ja/)

> I designed a manufacturing RFQ automation workflow where deterministic finance controls and human approval remain authoritative, while the LLM is bounded, observable, and fail-closed.

## Executive summary

Manufacturing RFQs combine commercial urgency with decisions that materially affect cost, margin, delivery commitments, and customer trust. An LLM can make the explanation layer faster and more useful, but it should not become the authority for financial calculation or approval.

This portfolio demonstrates an AI Ops design for a synthetic manufacturing environment, **AeroPrecision Industrial**. It combines a tested data foundation, deterministic quotation controls, bounded LLM assistance, observability, and a Human Approval boundary.

The design principle is simple:

> Use AI to assist people with context and explanation. Keep financial authority in deterministic controls and accountable human decisions.

## The business risk

A quotation workflow becomes unsafe when a language model can influence or override the calculation of cost, margin, price, or approval.

The workflow therefore separates three responsibilities:

| Responsibility | Authority | Design intent |
|---|---|---|
| Cost, margin, minimum price, and compliance | Deterministic calculation logic | Reproducible, testable, and auditable |
| Explanation, rationale, and negotiation support | Bounded LLM | Helpful, but never authoritative |
| Final save, notification, external action, and approval | Human Approval | Accountable business control |

## Workflow at a glance

1. A synthetic L0/L1 RFQ is validated for required fields, permitted values, duplicate processing, and known product IDs.
2. The workflow reads the product master in BigQuery with read-only access.
3. Deterministic logic calculates material cost, labor cost, total cost, the CFO minimum price, and realized gross margin.
4. The LLM receives only approved L0/L1 context and produces a bounded explanation. It does not calculate or approve the quote.
5. The response is structurally validated. A maximum of three attempts is allowed.
6. Timeout, malformed output, failed validation, or attempt exhaustion triggers **fail-closed** behavior.
7. The workflow does not persist, notify, or externally send anything before Human Approval.

## What the LLM is not allowed to decide

| Decision | Controlled by | LLM role |
|---|---|---|
| Material and labor cost | Deterministic code | None |
| CFO minimum price | Deterministic code | None |
| Gross-margin compliance | Deterministic code | None |
| Approval or rejection | Human Approval | None |
| Explanation and negotiation context | Validated AI output | Bounded assistance only |

This boundary protects the business from plausible but unverified model output. It also makes the workflow easier to test, explain, and operate.

## Evidence from controlled synthetic tests

The acceptance tests used synthetic L0/L1 data only. They exercised the bounded-loop behavior without allowing the model to bypass the calculation or approval controls.

| Scenario | LLM calls | Prompt tokens | Output tokens | Latency | Outcome |
|---|---:|---:|---:|---:|---|
| First-attempt success | 1 | 412 | 167 | 7,144 ms | Validated explanation |
| Retry recovery | 2 | 887 | 261 | 9,876 ms | First response rejected; second response validated |
| Fail-closed | 3 | 1,369 | 357 | 12,025 ms | No fourth attempt; no approval, persistence, or external action |

The important result is not that every AI call succeeds. It is that a failed or untrusted call cannot weaken the financial or human-control boundary.

## Observability without unsafe content retention

The workflow sends redacted operational metadata to local self-hosted Langfuse through OTLP HTTP. It does **not** retain raw prompts or raw LLM output.

The observable fields include:

- business trace ID and derived OpenTelemetry trace ID
- workflow execution ID
- model and provider
- attempt number and maximum attempts
- input and output hashes
- token counts, latency, and cost
- validation status and validation errors
- retry decision and loop stop reason
- fail-closed reason
- Human Approval and persistence state

This makes the LLM layer inspectable without treating sensitive content as observability data.

## What I designed and implemented

- A rebuildable dbt and BigQuery data foundation with tested models and CFO-oriented reporting
- A deterministic RFQ calculation contract aligned with finance controls
- A safe n8n orchestration flow with input validation, idempotency, bounded retries, and Human Approval
- An LLM contract that limits the model to explanatory assistance
- A fail-closed control path for timeout, malformed output, failed validation, and attempt exhaustion
- Local Langfuse observability that captures redacted operational metadata instead of raw AI content
- Documentation, synthetic test plans, and evidence that make the design reviewable by technical and business stakeholders

## Transferable value

This project reflects the work required to connect manufacturing operations, finance, data platforms, and AI automation responsibly.

The value is not a claim that AI can replace accountable decision-making. It is the ability to identify which decisions must remain deterministic, which tasks can safely benefit from AI assistance, and how to make the complete workflow observable and auditable.

## Explore the technical evidence

- [Phase 2 scope and decisions](../../docs/phase2/01_scope_and_decisions.md)
- [Deterministic calculation specification](../../docs/phase2/02_deterministic_calculation_spec.md)
- [Human Approval and audit specification](../../docs/phase2/03_human_approval_and_audit_spec.md)
- [Bounded-loop engineering design](../../docs/phase2/08_bounded_loop_engineering_design.md)
- [Phase 2 demo evidence](../../docs/phase2/11_phase2_n8n_demo_evidence.md)
- [Langfuse observability design](../../docs/phase3/01_langfuse_observability_design.md)
- [Local integration evidence](../../docs/phase3/04_local_integration_evidence.md)

[Return to the operational dashboard](./)
