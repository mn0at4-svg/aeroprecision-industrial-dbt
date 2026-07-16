select
    quote_id,
    status,
    calculated_is_margin_violated,
    minimum_cfo_approved_price_usd,
    quoted_price_usd,
    revenue_leak_usd

from {{ ref('int_quote_margin_analysis') }}

where
    (
        status = 'Won'
        and calculated_is_margin_violated = true
        and (
            revenue_leak_usd is null
            or revenue_leak_usd <= 0
        )
    )

    or

    (
        not (
            status = 'Won'
            and calculated_is_margin_violated = true
        )
        and revenue_leak_usd != 0
    )