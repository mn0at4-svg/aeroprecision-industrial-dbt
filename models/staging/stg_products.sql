with source as (

    select *
    from {{ source('manufacturing_raw', 'src_products') }}

),

cleaned as (

    select
        cast(product_id as string) as product_id,
        nullif(trim(product_name), '') as product_name,
        nullif(trim(category), '') as category,
        nullif(trim(base_material), '') as base_material,

        safe_cast(raw_material_cost_usd as float64)
            as raw_material_cost_usd,

        safe_cast(estimated_labor_hours as float64)
            as estimated_labor_hours,

        safe_cast(labor_rate_hourly_usd as float64)
            as labor_rate_hourly_usd,

        safe_cast(cfo_target_gross_margin_pct as float64)
            as cfo_target_gross_margin_pct,

        round(
            safe_cast(raw_material_cost_usd as float64)
            + (
                safe_cast(estimated_labor_hours as float64)
                * safe_cast(labor_rate_hourly_usd as float64)
            ),
            2
        ) as standard_unit_cost_usd

    from source

)

select *
from cleaned