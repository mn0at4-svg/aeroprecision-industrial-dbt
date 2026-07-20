# Phase 2 loop experiment runbook

Run this only on the company PC after the LLM credential is registered and the workflow is restricted to L0/L1 synthetic data.

1. Run a fixed synthetic RFQ set with the loop disabled: one explanation call, no retries.
2. Run the same set with the bounded loop enabled.
3. For each RFQ, record initial draft time, human edit count, total handling time, calls, latency, tokens, cost, timeout, structured-output outcome, stop reason, and final human decision.
4. Record `0` for unauthorized external actions, CFO rule modifications, and secret outputs. Any nonzero result is a failed security test, not a success metric.
5. Compare results only after reviewing both cost and quality. More iterations are not automatically better.

Do not use real customer text, credentials, production RFQs, or external tools during the experiment.
