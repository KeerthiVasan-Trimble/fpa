{{ config(alias='BU_REVENUE') }}

-- Billings = Unit Price x Units Sold; only months with units sold; FX to USD from FOREX
select
    s.fiscal_month as billing_month,
    s.unit_sales_code as revenue_code,
    s.fg_id,
    s.fg_name,
    s.region_id,
    s.region_code as region,
    p.unit_price,
    s.units_sold,
    p.unit_price * s.units_sold as billings,
    p.currency,
    case when p.currency = 'USD' then 1 else fx.average_rate end as fx_rate_to_usd,
    p.unit_price * s.units_sold
        * case when p.currency = 'USD' then 1 else fx.average_rate end as billings_usd
from {{ ref('bu_unit_sales') }} s
join {{ ref('bu_unit_price') }} p
    on p.unit_price_code = s.unit_sales_code
left join {{ ref('stg_bu_forex') }} fx
    on fx.currency_code = p.currency
   and fx.fiscal_month = s.fiscal_month
