# Phase 4 Visual Storyboard and Screenshot Selection

## Purpose

This document defines the small set of visuals used to explain the AeroPrecision Industrial portfolio. The objective is clarity, not volume: a hiring manager should understand the authority boundary before seeing detailed implementation screens.

Use only synthetic L0/L1 data. Do not add video files, raw prompts, raw LLM output, credentials, tokens, `.env` files, or generated Evidence build artifacts to Git.

## Visual hierarchy

| Priority | Visual | Primary message | Format |
|---:|---|---|---|
| 1 | Authority Boundary | Finance controls and Human Approval remain authoritative | Clean vector diagram |
| 2 | Bounded Retry and Fail-Closed | The LLM is limited to three attempts and cannot bypass control gates | Clean vector diagram |
| 3 | Observability Without Raw Content | Trace metadata is observable without retaining unsafe input/output | Clean vector diagram |
| 4 | n8n workflow overview | The orchestration exists and is structured around control boundaries | Redacted screenshot |
| 5 | Langfuse trace metadata | Retry, token, latency, validation, and stop reason are observable | Redacted screenshot |

## Figure 1 — Authority Boundary

**Working title:** `Deterministic Finance Controls, Bounded AI Assistance, Human Approval`

Show the sequence:

1. RFQ input validation
2. BigQuery product master — read only
3. Deterministic cost, margin, and CFO minimum-price calculation
4. Bounded LLM explanation
5. Deterministic output validation
6. Human Approval
7. Persistence or external action only after approval

Visually separate the three authority zones:

| Zone | Include | Exclude |
|---|---|---|
| Deterministic control zone | Costs, margins, CFO minimum price, compliance checks | LLM decision authority |
| Bounded AI zone | Explanation, rationale, negotiation support | Pricing, approval, finance calculations |
| Human-control zone | Approval, persistence, notification, external sending | Autonomous final action |

Use neutral technical colors and high contrast. The diagram should be a simple vector graphic, not AI-generated decorative imagery.

## Figure 2 — Bounded Retry and Fail-Closed

**Working title:** `Three Attempts Maximum — Then Stop Safely`

Show three possible paths:

| Path | Visual result |
|---|---|
| Valid first response | Validation passes → Human Approval |
| Invalid first response, valid second response | Retry once → validation passes → Human Approval |
| Three invalid or unavailable responses | Fail closed → no approval → no persistence or external action |

The fail-closed path must visually end before Human Approval. Do not use a fourth-attempt branch.

## Figure 3 — Observability Without Raw Content

**Working title:** `Observable AI Operations Without Retaining Raw Prompts or Outputs`

Show Langfuse receiving only redacted metadata:

- trace and workflow execution identifiers
- attempt count and maximum attempts
- token count, latency, and cost
- input/output hashes
- validation status
- retry decision and stop reason
- fail-closed reason
- approval and persistence state

Place a clear exclusion label outside the telemetry stream:

`No raw prompt • No raw LLM output • No credentials • L0/L1 synthetic data only`

## Screenshot 1 — n8n workflow overview

Capture only a clean, zoomed-out workflow overview. The screenshot must communicate the order of the stages, not node-level configuration.

Before capture:

- Use the inactive Phase 3 workflow only.
- Hide or crop the browser address bar, bookmarks, desktop notifications, and unrelated tabs.
- Do not open Credentials, node parameter panels, HTTP request bodies, code editors, or execution payloads.
- Ensure no node shows raw prompt text, raw LLM output, IDs, or secret values.
- Crop to the relevant control flow: deterministic calculation, bounded AI stage, validation, fail-closed path, and Human Approval boundary.

## Screenshot 2 — Langfuse trace metadata

Capture the trace timeline or metadata view only.

Before capture:

- Use synthetic L0/L1 test evidence only.
- Do not open Input or Output tabs.
- Do not show API keys, project settings, browser profile information, or local file paths.
- Crop the view to attempt count, token count, latency, validation, retry, and stop reason.
- Redact trace IDs if they are unnecessary to tell the story.

## Final visual QA

Before any visual is committed or recorded:

1. Verify that each visual reinforces one message only.
2. Inspect at 100% zoom for secrets, raw content, names, notifications, browser chrome, and unintended tabs.
3. Confirm that the fail-closed path visibly stops before approval or persistence.
4. Use captions that state the evidence is synthetic.
5. Keep MP4 files outside Git.
