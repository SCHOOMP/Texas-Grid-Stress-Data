-- Caveat: reporting_rate is readings vs. wall-clock time since each meter's
-- first-ever reading, minus tracked offline_ts->online_ts windows. It does
-- NOT know about time the `meters` container itself wasn't running (image
-- rebuilds, `docker compose down`, etc.) - the in-memory `online` flag resets
-- fresh on every process restart, so infra downtime never emits an offline
-- event and will deflate this rate for long-lived meters. A true fix needs a
-- service-level heartbeat, which is out of scope here.
with readings as (
    select
        meter_id,
        count(*) as readings_count,
        min(ts)  as first_seen,
        max(ts)  as last_seen
    from {{ ref('stg_meter_telemetry') }}
    group by 1
),

offline_events as (
    select meter_id, ts as offline_ts
    from {{ ref('stg_meter_events') }}
    where event_type = 'offline'
),

online_events as (
    select meter_id, ts as online_ts
    from {{ ref('stg_meter_events') }}
    where event_type = 'online'
),

paired as (
    select
        o.meter_id,
        o.offline_ts,
        min(r.online_ts) as recovered_ts
    from offline_events o
    left join online_events r
        on r.meter_id = o.meter_id
       and r.online_ts > o.offline_ts
    group by 1, 2
),

offline_durations as (
    select
        meter_id,
        count(*)                                              as offline_events_count,
        sum(extract(epoch from (recovered_ts - offline_ts)))  as total_offline_seconds
    from paired
    where recovered_ts is not null
    group by 1
)

select
    r.meter_id,
    r.readings_count,
    r.last_seen,
    coalesce(d.offline_events_count, 0)  as offline_events_count,
    coalesce(d.total_offline_seconds, 0) as total_offline_seconds,
    greatest(
        extract(epoch from (r.last_seen - r.first_seen)) - coalesce(d.total_offline_seconds, 0),
        0
    ) / {{ var('telemetry_interval_seconds') }} + 1            as expected_readings,
    r.readings_count / nullif(
        greatest(
            extract(epoch from (r.last_seen - r.first_seen)) - coalesce(d.total_offline_seconds, 0),
            0
        ) / {{ var('telemetry_interval_seconds') }} + 1,
        0
    )                                                           as reporting_rate
from readings r
left join offline_durations d using (meter_id)
