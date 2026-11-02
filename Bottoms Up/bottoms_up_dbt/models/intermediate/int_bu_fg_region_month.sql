-- FG x Region expanded across the fiscal months that have unit-sales input
with months as (
    select distinct fm.*
    from {{ ref('stg_bu_fiscal_month') }} fm
    join {{ ref('stg_bu_unit_sales') }} us on us.fiscal_month = fm.fiscal_month
)

select
    fr.*,
    m.fiscal_month,
    m.fiscal_month_code,
    m.fiscal_year,
    m.fiscal_quarter_code
from {{ ref('int_bu_fg_region') }} fr
cross join months m
