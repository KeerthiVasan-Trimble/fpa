-- Rates convert 1 unit of CURRENCY_CODE into SOURCE_CURRENCY (USD)
select
    to_char(month, 'YYYY-MM') as fiscal_month,
    currency_code,
    source_currency,
    average_rate,
    end_rate
from {{ source('general', 'forex') }}
where upper(coalesce(status, 'ACTIVE')) = 'ACTIVE'
