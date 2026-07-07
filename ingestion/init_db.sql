CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE IF NOT EXISTS raw.grid_conditions (
    ts timestamptz NOT NULL,
    region text NOT NULL DEFAULT 'ERCOT',
    load_mw numeric NOT NULL,
    capacity_mw numeric,
    wind_mw numeric,
    solar_mw numeric,
    ingested_at timestamptz DEFAULT now(),
    PRIMARY KEY (ts, region)
);
SELECT create_hypertable('raw.grid_conditions', 'ts', if_not_exists => TRUE);

CREATE TABLE IF NOT EXISTS raw.weather (
    ts timestamptz NOT NULL,
    city text NOT NULL,
    temperature_c numeric,
    humidity_pct numeric,
    wind_speed_kmh numeric,
    ingested_at timestamptz DEFAULT now(),
    PRIMARY KEY (ts, city)
);
SELECT create_hypertable('raw.weather', 'ts', if_not_exists => TRUE);

CREATE TABLE IF NOT EXISTS raw.meter_telemetry (
    ts timestamptz NOT NULL,
    meter_id text NOT NULL,
    city text NOT NULL,
    power_kw numeric NOT NULL,
    voltage_v numeric,
    ingested_at timestamptz DEFAULT now()
);
SELECT create_hypertable('raw.meter_telemetry', 'ts', if_not_exists => TRUE);
CREATE INDEX IF NOT EXISTS idx_meter ON raw.meter_telemetry (meter_id, ts DESC);

CREATE TABLE IF NOT EXISTS raw.meter_events (
    ts timestamptz NOT NULL,
    meter_id text NOT NULL,
    event_type text NOT NULL,
    detail text,
    ingested_at timestamptz DEFAULT now()
);
SELECT create_hypertable('raw.meter_events', 'ts', if_not_exists => TRUE);