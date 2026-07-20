# Phase 2 local calculation test procedure

Run the local-only check before implementing the n8n Code node or BigQuery calculation query:

```powershell
python .\tests\phase2\validate_calculation_parity.py
```

Expected result:

```text
PASS: Phase 2 deterministic calculation parity checks
```

The test verifies the design baseline:

- material, labor, unit cost, total cost, and CFO minimum formulas
- negative surcharge within the approved range
- no intermediate money rounding
- `SAFE_DIVIDE`-style zero-denominator handling as fail-closed
- dbt's margin tolerance of `0.000001`

It is not a replacement for the later company-PC comparison against the actual dbt model and BigQuery result set. It has no external side effects.
