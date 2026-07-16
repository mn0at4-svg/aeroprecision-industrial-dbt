/*
This test fails if the CFO summary contains duplicate rows
for the same reporting grain.
*/

select
    quote_month,
    quote_method,
    response_speed_band,
    category,
    count(*) as duplicate_count

from {{ ref('mart_cfo_quote_summary') }}

group by
    quote_month,
    quote_method,
    response_speed_band,
    category

having count(*) > 1