-- Fails if any telemetry row's ts falls strictly between a meter's 'offline'
-- event and its next 'online' event. Validates a real invariant of
-- meter_simulator.py: Meter.maybe_transition() runs before Meter.step() each
-- tick, so a meter that just went offline produces no reading that same tick,
-- and none until it recovers.
with offline_windows as (
    select
        o.meter_id,
        o.ts as offline_ts,
        coalesce(
            min(r.ts) filter (where r.ts > o.ts),
            timestamptz '9999-12-31'
        ) as recovered_ts
    from {{ ref('stg_meter_events') }} o
    left join {{ ref('stg_meter_events') }} r
        on r.meter_id = o.meter_id
       and r.event_type = 'online'
       and r.ts > o.ts
    where o.event_type = 'offline'
    group by o.meter_id, o.ts
)

select t.*
from {{ ref('stg_meter_telemetry') }} t
join offline_windows w
    on t.meter_id = w.meter_id
   and t.ts > w.offline_ts
   and t.ts < w.recovered_ts
