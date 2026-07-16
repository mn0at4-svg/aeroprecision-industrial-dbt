{{
    config(
        materialized='table',
        cluster_by=[
            'quote_method',
            'status',
            'category'
        ]
    )
}}

with quote_margin_analysis as (

    select *
    from {{ ref('int_quote_margin_analysis') }}

)

select
    quote_id,
    created_at,
    date(created_at) as quote_date,
    date_trunc(date(created_at), month) as quote_month,

    customer_name,
    product_id,
    product_name,
    category,
    base_material,

    requested_quantity,
    quote_method,
    created_by,
    quote_lead_time_days,
    response_speed_band,

    status,
    status = 'Won' as is_won,

    spot_material_surcharge_pct,
    raw_material_cost_usd,
    estimated_labor_hours,
    labor_rate_hourly_usd,
    standard_unit_cost_usd,
    actual_unit_cost_usd,
    estimated_total_cost_usd,

    quoted_price_usd,
    minimum_cfo_approved_price_usd,

    cfo_target_gross_margin_pct,
    actual_gross_margin_pct,
    margin_variance_pct,

    calculated_is_margin_violated,
    is_violation_flag_consistent,
    margin_governance_status,
    revenue_leak_usd

from quote_margin_analysis