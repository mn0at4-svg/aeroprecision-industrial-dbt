# Phase 2 deterministic calculation specification

Source of truth: `models/intermediate/int_quote_margin_analysis.sql` at commit `fb28346`.

## Units and inputs

All money values are USD. Percentages are decimal fractions: `0.08` means 8%, not 8. `requested_quantity` is a positive integer.

| Value | Source | Rule |
|---|---|---|
| `raw_material_cost_usd` | Product master | Required numeric value. |
| `estimated_labor_hours` | Product master | Required numeric value. |
| `labor_rate_hourly_usd` | Product master | Required numeric value. |
| `cfo_target_gross_margin_pct` | Product master | Required decimal fraction strictly below 1. |
| `spot_material_surcharge_pct` | RFQ | Decimal from `-0.05` to `0.15`, inclusive. |
| `requested_quantity` | RFQ | Integer from `1` to `100000`, inclusive. |
| `requested_discount_pct` | RFQ | Audit-only; it is never an automatic price input. |

## Exact dbt-aligned formulas

```text
material_cost_usd = raw_material_cost_usd × (1 + spot_material_surcharge_pct)
labor_cost_usd = estimated_labor_hours × labor_rate_hourly_usd
unit_cost_usd = material_cost_usd + labor_cost_usd
total_cost_usd = unit_cost_usd × requested_quantity
minimum_cfo_approved_price_usd = SAFE_DIVIDE(total_cost_usd, 1 - cfo_target_gross_margin_pct)
proposed_quote_price_usd = minimum_cfo_approved_price_usd
realized_gross_margin_pct = SAFE_DIVIDE(proposed_quote_price_usd - total_cost_usd, proposed_quote_price_usd)
```

`SAFE_DIVIDE` is the dbt/BigQuery behavior: a zero denominator returns `NULL`. Any `NULL`, non-finite value, or missing required input is `FAILED_CLOSED`.

The current dbt intermediate model does **not** round material cost, labor cost, unit cost, total cost, minimum price, or actual gross margin. Phase 2 retains full precision for policy checks. Amounts may be formatted to two decimals only after the policy checks; a formatted value is never reused as a calculation input.

## Deterministic decision code

The dbt source uses a tolerance of `0.000001`:

```text
is_margin_compliant = realized_gross_margin_pct >= cfo_target_gross_margin_pct - 0.000001
```

| Condition | decision_code |
|---|---|
| Schema, product lookup, calculation, audit, or security validation fails | `FAILED_CLOSED` |
| Price is below CFO minimum or margin is non-compliant | `REVIEW_REQUIRED_CFO_MARGIN` |
| Quantity is 501 or more | `REVIEW_REQUIRED_HIGH_QUANTITY` |
| Requested discount is greater than zero | `REVIEW_REQUIRED_DISCOUNT` |
| Numeric policy is compliant and no review flag exists | `PENDING_HUMAN_APPROVAL` |
| Human explicitly approves the exact payload | `APPROVED_BY_HUMAN` |
| Human rejects or approval expires | `REJECTED_BY_HUMAN` / `EXPIRED` |

An LLM response cannot change a decision code.
