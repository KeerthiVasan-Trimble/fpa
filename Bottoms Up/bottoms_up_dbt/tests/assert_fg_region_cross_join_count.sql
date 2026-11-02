-- Fails if FG x Region rows != (#active FGs) x (#active regions)
with expected as (
    select
        (select count(*) from {{ ref('stg_bu_forecasting_group') }}
          where upper(fg_status) = 'ACTIVE')
        * (select count(*) from {{ ref('stg_bu_region') }}) as n
),
actual as (
    select count(*) as n from {{ ref('int_bu_fg_region') }}
)
select e.n as expected_rows, a.n as actual_rows
from expected e cross join actual a
where e.n <> a.n
