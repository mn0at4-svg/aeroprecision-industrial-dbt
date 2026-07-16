select
    quote_month,
    quote_method,
    response_speed_band,
    category,
    total_quotes,
    won_quotes,
    lost_quotes,
    win_rate,
    avg_quote_lead_time_days,
    total_quoted_value_usd,
    won_revenue_usd,
    won_gross_profit_usd,
    margin_violation_quotes,
    won_margin_violation_deals,
    margin_compliance_rate,
    revenue_leak_usd,
    avg_cfo_target_margin_pct,
    avg_actual_gross_margin_pct,
    avg_margin_variance_pct
from `aeroprecision-data-pipeline.analytics_manufacturing.mart_cfo_quote_summary`
order by
    quote_month,
    quote_method,
    response_speed_band,
    category