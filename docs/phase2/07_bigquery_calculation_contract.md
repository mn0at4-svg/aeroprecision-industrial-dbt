# Phase 2 BigQuery calculation contract

`operations/sql/phase2_calculate_quote.sql` is the proposed deterministic calculation query for the n8n BigQuery read path.

## Alignment with dbt

The query deliberately preserves the exact formulas in `int_quote_margin_analysis.sql`:

- material cost = raw material cost × (1 + surcharge)
- labor cost = labor hours × labor rate
- total cost = unit cost × quantity
- CFO minimum = `SAFE_DIVIDE(total cost, 1 - CFO target margin)`
- realized margin = `SAFE_DIVIDE(proposed price - total cost, proposed price)`
- margin compliance tolerance = `0.000001`

It adds only Phase 2 policy handling around that dbt-aligned calculation:

- RFQ schema limits for quantity, surcharge, and requested discount
- product-not-found and null values as `FAILED_CLOSED`
- quantity 501+ and nonzero discount as human-review states
- the approved baseline `proposed_quote_price_usd = minimum_cfo_approved_price_usd`

## Company-PC validation required later

1. Bind parameters from the n8n schema-validation output; never concatenate RFQ text into SQL.
2. Run synthetic fixture inputs against the query and compare its numeric output with dbt.
3. Confirm the source-table numeric types and BigQuery parameter types before production use.
4. Give the n8n runtime read-only access to `raw_manufacturing.src_products` for this step.
5. Do not grant a write role until the reviewed post-human-approval transaction is implemented.

This query has no DDL, no DML, no notification, and no external-send operation.
