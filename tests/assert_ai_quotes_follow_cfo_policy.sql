select
    quote_id,
    created_by,
    quote_lead_time_days,
    actual_gross_margin_pct,
    cfo_target_gross_margin_pct,
    calculated_is_margin_violated

from {{ ref('int_quote_margin_analysis') }}

where
    quote_method = 'AI-Automated'
    and (
        created_by != 'AI_Autonomous_Ops'
        or quote_lead_time_days != 0.0
        or calculated_is_margin_violated = true
        or abs(
            actual_gross_margin_pct
            - cfo_target_gross_margin_pct
        ) > 0.000001
    )