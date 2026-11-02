select
    fg_id,
    fg_name,
    fg_asp,
    fg_status,
    upper(coalesce(currency, 'USD')) as currency
from {{ source('general', 'forecasting_group') }}
