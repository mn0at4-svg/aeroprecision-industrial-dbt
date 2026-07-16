{{
    config(
        materialized='table',
        cluster_by=[
            'quote_method',
            'response_speed_band',
            'category'
        ]
    )
}}

with quotation_performance as (

    select *
    from {{ ref('fct_quotation_performance') }}

)

select
    quote_month,
    quote_method,
    response_speed_band,
    category,

    count(*) as total_quotes,
    countif(is_won) as won_quotes,
    countif(not is_won) as lost_quotes,

    safe_divide(
        countif(is_won),
        count(*)
    ) as win_rate,

    round(
        avg(quote_lead_time_days),
        2
    ) as avg_quote_lead_time_days,

    round(
        sum(quoted_price_usd),
        2
    ) as total_quoted_value_usd,

    round(
        sum(
            case
                when is_won then quoted_price_usd
                else 0
            end
        ),
        2
    ) as won_revenue_usd,

    round(
        sum(
            case
                when is_won
                    then quoted_price_usd - estimated_total_cost_usd
                else 0
            end
        ),
        2
    ) as won_gross_profit_usd,

    countif(calculated_is_margin_violated)
        as margin_violation_quotes,

    countif(
        calculated_is_margin_violated
        and is_won
    ) as won_margin_violation_deals,

    safe_divide(
        countif(not calculated_is_margin_violated),
        count(*)
    ) as margin_compliance_rate,

    round(
        sum(revenue_leak_usd),
        2
    ) as revenue_leak_usd,

    avg(cfo_target_gross_margin_pct)
        as avg_cfo_target_margin_pct,

    avg(actual_gross_margin_pct)
        as avg_actual_gross_margin_pct,

    avg(margin_variance_pct)
        as avg_margin_variance_pct

from quotation_performance

group by
    quote_month,
    quote_method,
    response_speed_band,
    category