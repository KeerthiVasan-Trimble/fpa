{{ config(alias='BU_UNIT_SALES') }}

-- Only FG x Region x Month combinations that have units sold
select
    g.fg_id || '_' || g.region_id || '_' || g.fiscal_month as unit_sales_code,
    g.fg_id,
    g.fg_name,
    g.region_id,
    g.region_code,
    g.region_name,
    g.fiscal_month,
    g.fiscal_month_code,
    us.units_sold,
    g.currency
from {{ ref('int_bu_fg_region_month') }} g
join {{ ref('stg_bu_unit_sales') }} us
    on us.fg_id = g.fg_id
   and us.region_id = g.region_id
   and us.fiscal_month = g.fiscal_month
where us.units_sold is not null
