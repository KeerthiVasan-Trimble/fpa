{{ config(alias='BU_UNIT_PRICE') }}

select
    fg_id || '_' || region_id || '_' || fiscal_month as unit_price_code,
    fg_id,
    fg_name,
    region_id,
    region_code,
    region_name,
    fiscal_month,
    fiscal_month_code,
    fg_asp as unit_price,
    currency
from {{ ref('int_bu_fg_region_month') }}
