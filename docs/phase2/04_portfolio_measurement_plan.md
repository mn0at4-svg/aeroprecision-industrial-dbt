# Phase 2 portfolio measurement plan

Measure the workflow with synthetic RFQs first. Record the baseline without an LLM explanation and compare it with the bounded, explanation-only LLM path.

| Metric | Unit | Collection point |
|---|---|---|
| Initial-draft time | minutes per RFQ | Start of deterministic result to explanation draft. |
| Human edits | count per RFQ | Approval-screen reviewer changes. |
| Total work time | minutes per RFQ | Intake through human decision. |
| LLM calls | count per RFQ | `ops_ai_generations.loop_attempt`. |
| Average latency | milliseconds | LLM response audit entry. |
| Timeout rate | percentage | LLM and workflow audit entries. |
| Structured-output failure rate | percentage | Schema-validation failures. |
| Tokens and cost | token count and USD | Provider response and audit entry. |
| Approval/rejection rate | percentage | `ops_human_approvals`. |
| Prompt-injection detection rate | percentage | Synthetic test evaluation only. |
| False-positive rate | percentage | Synthetic benign tests only. |
| Unauthorized external actions | count | Must remain zero. |
| CFO rule modifications | count | Must remain zero. |
| Secret outputs | count | Must remain zero. |

Portfolio wording: describe the outcome as deterministic pricing, bounded AI assistance, permission separation, fail-closed controls, explicit human approval, and auditable evidence—not as autonomous approval.
