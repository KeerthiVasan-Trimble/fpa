select
    region_id,
    upper(region_code) as region_code,
    region_name,
    country_id
from {{ source('general', 'regions') }}
where upper(coalesce(status, 'ACTIVE')) = 'ACTIVE'
