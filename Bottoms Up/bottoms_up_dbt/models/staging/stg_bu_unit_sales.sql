select
    fg_id,
    region_id,
    billing_month as fiscal_month,
    units_sold,
    entered_by,
    entered_at
from {{ source('general', 'unit_sales_input') }}
