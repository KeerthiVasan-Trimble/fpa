-- Fails if BILLINGS <> UNIT_PRICE x UNITS_SOLD, or if a row has no units sold
select revenue_code, unit_price, units_sold, billings
from {{ ref('bu_revenue') }}
where billings <> unit_price * units_sold
   or units_sold is null
