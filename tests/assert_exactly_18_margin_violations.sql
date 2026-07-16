with violation_summary as (

    select
        countif(calculated_is_margin_violated) as violation_count

    from {{ ref('int_quote_margin_analysis') }}

)

select
    violation_count

from violation_summary

where violation_count != 18