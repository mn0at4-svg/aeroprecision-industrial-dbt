{{ config(materialized='view') }}

with transactions as (

    select *
    from {{ ref('stg_transactions') }}

),

products as (

    select *
    from {{ ref('stg_products') }}

),

joined as (

    select
        transactions.*,

        products.product_name,
        products.category,
        products.base_material,
        products.raw_material_cost_usd,
        products.estimated_labor_hours,
        products.labor_rate_hourly_usd,
        products.cfo_target_gross_margin_pct,
        products.standard_unit_cost_usd,

        (
            products.raw_material_cost_usd
            * (1 + transactions.spot_material_surcharge_pct)
        )
        + (
            products.estimated_labor_hours
            * products.labor_rate_hourly_usd
        ) as actual_unit_cost_usd

    from transactions

    inner join products
        on transactions.product_id = products.product_id

),

cost_calculations as (

    select
        *,

        actual_unit_cost_usd
            * requested_quantity
            as estimated_total_cost_usd,

        safe_divide(
            actual_unit_cost_usd * requested_quantity,
            1 - cfo_target_gross_margin_pct
        ) as minimum_cfo_approved_price_usd

    from joined

),

margin_calculations as (

    select
        *,

        safe_divide(
            quoted_price_usd - estimated_total_cost_usd,
            quoted_price_usd
        ) as actual_gross_margin_pct

    from cost_calculations

)

select
    *,

    actual_gross_margin_pct
        - cfo_target_gross_margin_pct
        as margin_variance_pct,

    actual_gross_margin_pct
        < cfo_target_gross_margin_pct - 0.000001
        as calculated_is_margin_violated,

    is_margin_violated = (
        actual_gross_margin_pct
        < cfo_target_gross_margin_pct - 0.000001
    ) as is_violation_flag_consistent,

    case
        when actual_gross_margin_pct
            < cfo_target_gross_margin_pct - 0.000001
            then 'Violation'

        when actual_gross_margin_pct
            < cfo_target_gross_margin_pct + 0.02
            then 'At Target'

        else 'Above Target'
    end as margin_governance_status,

    case
        when
            status = 'Won'
            and actual_gross_margin_pct
                < cfo_target_gross_margin_pct - 0.000001
        then round(
            greatest(
                minimum_cfo_approved_price_usd - quoted_price_usd,
                0
            ),
            2
        )
        else 0
    end as revenue_leak_usd

from margin_calculations