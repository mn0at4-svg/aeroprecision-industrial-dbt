-- Phase 2 deterministic quotation calculation.
-- DESIGN ONLY: do not run until company-PC credentials, dataset permissions,
-- parameter binding, and the Human Approval boundary have been reviewed.
--
-- Bind parameters from the validated RFQ schema:
-- @rfq_id STRING
-- @customer_name STRING
-- @product_id STRING
-- @requested_quantity INT64
-- @spot_material_surcharge_pct FLOAT64
-- @requested_delivery_date DATE
-- @requested_discount_pct FLOAT64
-- @sales_rep STRING
-- @request_channel STRING

with request as (
    select
        @rfq_id as rfq_id,
        @customer_name as customer_name,
        @product_id as product_id,
        @requested_quantity as requested_quantity,
        @spot_material_surcharge_pct as spot_material_surcharge_pct,
        @requested_delivery_date as requested_delivery_date,
        @requested_discount_pct as requested_discount_pct,
        @sales_rep as sales_rep,
        @request_channel as request_channel
),

product_lookup as (
    select
        request.*,
        products.product_name,
        products.category,
        products.raw_material_cost_usd,
        products.estimated_labor_hours,
        products.labor_rate_hourly_usd,
        products.cfo_target_gross_margin_pct,
        products.product_id is not null as product_found
    from request
    left join `aeroprecision-data-pipeline.raw_manufacturing.src_products` as products
        on request.product_id = products.product_id
),

unit_cost as (
    select
        *,
        raw_material_cost_usd * (1 + spot_material_surcharge_pct) as material_cost_usd,
        estimated_labor_hours * labor_rate_hourly_usd as labor_cost_usd
    from product_lookup
),

quote_calculation as (
    select
        *,
        material_cost_usd + labor_cost_usd as unit_cost_usd,
        (material_cost_usd + labor_cost_usd) * requested_quantity as total_cost_usd
    from unit_cost
),

price_calculation as (
    select
        *,
        safe_divide(
            total_cost_usd,
            1 - cfo_target_gross_margin_pct
        ) as minimum_cfo_approved_price_usd
    from quote_calculation
),

margin_calculation as (
    select
        *,
        minimum_cfo_approved_price_usd as proposed_quote_price_usd,
        safe_divide(
            minimum_cfo_approved_price_usd - total_cost_usd,
            minimum_cfo_approved_price_usd
        ) as realized_gross_margin_pct
    from price_calculation
)

select
    *,

    realized_gross_margin_pct >= cfo_target_gross_margin_pct - 0.000001
        as is_margin_compliant,

    case
        when not product_found
            then 'FAILED_CLOSED'
        when requested_quantity < 1 or requested_quantity > 100000
            then 'FAILED_CLOSED'
        when spot_material_surcharge_pct < -0.05
            or spot_material_surcharge_pct > 0.15
            then 'FAILED_CLOSED'
        when requested_discount_pct < 0 or requested_discount_pct > 0.30
            then 'FAILED_CLOSED'
        when material_cost_usd is null
            or labor_cost_usd is null
            or total_cost_usd is null
            or minimum_cfo_approved_price_usd is null
            or realized_gross_margin_pct is null
            then 'FAILED_CLOSED'
        when realized_gross_margin_pct < cfo_target_gross_margin_pct - 0.000001
            then 'REVIEW_REQUIRED_CFO_MARGIN'
        when requested_quantity >= 501
            then 'REVIEW_REQUIRED_HIGH_QUANTITY'
        when requested_discount_pct > 0
            then 'REVIEW_REQUIRED_DISCOUNT'
        else 'PENDING_HUMAN_APPROVAL'
    end as decision_code,

    'phase2-calculation-v1' as calculation_version

from margin_calculation;
