-- Every active forecasting group x every region (2 FG x 4 regions = 8 rows)
select
    fg.fg_id,
    fg.fg_name,
    r.region_id,
    r.region_code,
    r.region_name,
    fg.fg_asp,
    fg.currency
from {{ ref('stg_bu_forecasting_group') }} fg
cross join {{ ref('stg_bu_region') }} r
where upper(fg.fg_status) = 'ACTIVE'
