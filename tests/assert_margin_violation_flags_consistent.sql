select
    quote_id,
    is_margin_violated,
    calculated_is_margin_violated,
    actual_gross_margin_pct,
    cfo_target_gross_margin_pct

from {{ ref('int_quote_margin_analysis') }}

where
    is_violation_flag_consistent is null
    or is_violation_flag_consistent = false