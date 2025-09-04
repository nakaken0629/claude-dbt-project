{{ config(materialized='table') }}

with final as (
    select
        vending_machine_id,
        location_name,
        installation_date,
        created_at,
        updated_at
    from {{ ref('stg_vending_machines') }}
)

select * from final