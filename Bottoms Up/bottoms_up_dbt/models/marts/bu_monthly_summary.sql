{{ config(alias='BU_MONTHLY_SUMMARY') }}

select
    billing_month,
    region,
    sum(units_sold) as units_sold,
    sum(billings) as billings,
    sum(billings_usd) as billings_usd
from {{ ref('bu_revenue') }}
group by billing_month, region
