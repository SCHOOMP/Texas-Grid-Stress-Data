-- avg_temp_c is null for hours with no matching raw.weather row (weather is a
-- one-shot seed job, not a standing service like meters - re-run `make
-- seed-weather` periodically to keep this current for recent hours).
select
    time_bucket('1 hour', t.ts) as hour,
    t.city,
    time_bucket('1 hour', t.ts)::text || '|' || t.city as demand_weather_id,
    avg(t.power_kw)                             as avg_power_kw,
    avg(w.temperature_c)                        as avg_temp_c
from {{ ref('stg_meter_telemetry') }} t
left join {{ ref('stg_weather') }} w
    on w.city = t.city
   and w.ts >= time_bucket('1 hour', t.ts)
   and w.ts <  time_bucket('1 hour', t.ts) + interval '1 hour'
group by 1, 2
