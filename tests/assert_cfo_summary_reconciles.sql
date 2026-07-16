/*
This test verifies that the CFO summary reconciles with
the quote-level fact table and known governance totals.
*/

with fact_totals as (

    select
        count(*) as total_quotes,
        countif(is_won) as won_quotes,
        countif(not is_won) as lost_quotes,
        countif(calculated_is_margin_violated) as margin_violations,
        countif(
            calculated_is_margin_violated
            and is_won
        ) as won_margin_violations,
        round(sum(revenue_leak_usd), 2) as revenue_leak_usd

    from {{ ref('fct_quotation_performance') }}

),

summary_totals as (

    select
        sum(total_quotes) as total_quotes,
        sum(won_quotes) as won_quotes,
        sum(lost_quotes) as lost_quotes,
        sum(margin_violation_quotes) as margin_violations,
        sum(won_margin_violation_deals) as won_margin_violations,
        round(sum(revenue_leak_usd), 2) as revenue_leak_usd

    from {{ ref('mart_cfo_quote_summary') }}

)

select
    fact.total_quotes as fact_total_quotes,
    summary.total_quotes as summary_total_quotes,
    fact.won_quotes as fact_won_quotes,
    summary.won_quotes as summary_won_quotes,
    fact.lost_quotes as fact_lost_quotes,
    summary.lost_quotes as summary_lost_quotes,
    fact.margin_violations as fact_margin_violations,
    summary.margin_violations as summary_margin_violations,
    fact.won_margin_violations as fact_won_margin_violations,
    summary.won_margin_violations as summary_won_margin_violations,
    fact.revenue_leak_usd as fact_revenue_leak_usd,
    summary.revenue_leak_usd as summary_revenue_leak_usd

from fact_totals as fact
cross join summary_totals as summary

where
    fact.total_quotes != summary.total_quotes
    or fact.won_quotes != summary.won_quotes
    or fact.lost_quotes != summary.lost_quotes
    or fact.margin_violations != summary.margin_violations
    or fact.won_margin_violations != summary.won_margin_violations
    or abs(fact.revenue_leak_usd - summary.revenue_leak_usd) > 0.01
    or summary.total_quotes != 1000
    or summary.margin_violations != 18
    or summary.won_margin_violations != 5