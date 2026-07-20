# Phase 2 AI prompt and output contract

The initial LLM interface is intentionally narrow:

- Input: L0/L1 synthetic, already-calculated explanation context only.
- Output: exactly four text fields defined by `phase2-ai-explanation.schema.json`.
- Authority: no price calculation, policy decision, approval, tool call, database write, notification, or external send.
- Validation: JSON shape, field lengths, security markers, URL rejection, control-character rejection, duplicate-output detection, token/cost cap, and loop time limit.

The n8n workflow must retain both `prompt_version` and `prompt_hash`. The LLM response is an untrusted draft; only deterministic checks and Human Approval can advance workflow state.

For a revision loop, n8n supplies only evaluator findings such as `internal_rationale below minimum length`. It never asks the model to reconsider numeric values or approval logic.
