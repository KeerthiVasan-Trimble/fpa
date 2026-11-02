-- One row per fiscal month; '2026-M01' -> '2026-01' to match BILLING_MONTH format
select
    replace(fiscal_month_code, '-M', '-') as fiscal_month,
    fiscal_month_code,
    fiscal_year,
    fiscal_month as fiscal_month_num,
    fiscal_quarter_code,
    min(fiscal_month_start) as fiscal_month_start,
    max(fiscal_month_end) as fiscal_month_end
from {{ source('architecture', 'fiscal_calendar') }}
group by 1, 2, 3, 4, 5
