-- Fails if any strain_ratio falls outside a sane [0, 1.5] guardrail.
-- Wide on purpose: strain_ratio is ~load/capacity and capacity_mw is itself
-- an approximation (see stg_grid_conditions), so this catches real pipeline
-- bugs (negative values, nulls-as-zero, unit errors) without being a tight
-- assertion on the exact theoretical range.
select *
from {{ ref('stg_grid_conditions') }}
where strain_ratio < 0 or strain_ratio > 1.5
