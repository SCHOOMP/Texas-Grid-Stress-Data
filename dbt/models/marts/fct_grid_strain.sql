-- Thresholds tuned against real data (2026-07-20): with 0.75/0.90, the full
-- history splits ~32% NORMAL / ~65% ELEVATED / ~2% CRITICAL. capacity_mw is
-- itself an approximation (day_peak * 1.15, see ercot_load.py TODO), so
-- strain_ratio is bounded near ~0.87 by construction most of the time -
-- ELEVATED dominating summer ERCOT data is realistic, not a threshold bug.
with strain as (
    select
        time_bucket('5 minutes', g.ts) as bucket,
        avg(g.load_mw)                 as load_mw,
        avg(g.strain_ratio)            as strain_ratio
    from {{ ref('stg_grid_conditions') }} g
    group by 1
)

select
    s.bucket,
    s.load_mw,
    s.strain_ratio,
    case
        when s.strain_ratio >= 0.90 then 'CRITICAL'
        when s.strain_ratio >= 0.75 then 'ELEVATED'
        else 'NORMAL'
    end as strain_level,
    (select avg(temperature_c) from {{ ref('stg_weather') }} w
      where w.ts >= s.bucket
        and w.ts <  s.bucket + interval '1 hour') as statewide_temp_c
from strain s
