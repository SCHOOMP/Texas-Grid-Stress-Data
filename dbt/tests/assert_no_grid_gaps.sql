-- Fails if consecutive grid_conditions readings for the same region are more
-- than 20 minutes apart. Note: this correctly flags a real ~1 day 7 hour gap
-- between two separate ad-hoc ercot_load.py sessions (2026-07-11 ->
-- 2026-07-13), from before `seed-grid` was run on a schedule. severity=warn
-- so a known historical gap doesn't hard-block `dbt build` from materializing
-- downstream marts - a NEW gap appearing here should still get investigated.
{{ config(severity='warn') }}

with ordered as (
    select
        ts,
        region,
        lag(ts) over (partition by region order by ts) as prev_ts
    from {{ ref('stg_grid_conditions') }}
)

select *
from ordered
where prev_ts is not null
  and ts - prev_ts > interval '20 minutes'
