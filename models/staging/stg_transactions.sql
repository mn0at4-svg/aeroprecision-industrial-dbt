with source as (

    select *
    from {{ source('manufacturing_raw', 'src_transactions') }}

),

cleaned as (

    select
        cast(quote_id as string) as quote_id,
        safe_cast(created_at as timestamp) as created_at,
        nullif(trim(customer_name), '') as customer_name,
        cast(product_id as string) as product_id,

        safe_cast(requested_quantity as int64)
            as requested_quantity,

        safe_cast(spot_material_surcharge_pct as float64)
            as spot_material_surcharge_pct,

        safe_cast(quote_lead_time_days as float64)
            as quote_lead_time_days,

        nullif(trim(created_by), '')
            as created_by,

        safe_cast(quoted_price_usd as float64)
            as quoted_price_usd,

        safe_cast(is_margin_violated as bool)
            as is_margin_violated,

        case
            when upper(trim(status)) = 'WON' then 'Won'
            when upper(trim(status)) = 'LOST' then 'Lost'
            else 'Unknown'
        end as status,

        case
            when trim(created_by) = 'AI_Autonomous_Ops'
                and safe_cast(quote_lead_time_days as float64) = 0.0
                then 'AI-Automated'
            else 'Manual'
        end as quote_method,

        case
            when safe_cast(quote_lead_time_days as float64) = 0.0
                then 'Instant'
            when safe_cast(quote_lead_time_days as float64) <= 3.0
                then '1.5-3.0 Days'
            else 'Over 3.0 Days'
        end as response_speed_band

    from source

)

select *
from cleaned