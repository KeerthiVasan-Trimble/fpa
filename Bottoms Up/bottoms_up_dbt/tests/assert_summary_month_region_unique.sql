-- Fails if the monthly summary has duplicate month x region rows
select billing_month, region, count(*) as n
from {{ ref('bu_monthly_summary') }}
group by billing_month, region
having count(*) > 1
