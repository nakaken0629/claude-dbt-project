{{ config(materialized='table') }}

with final as (
    select
        staff_id,
        staff_name,
        created_at,
        updated_at
    from {{ ref('stg_staff') }}
)

select * from final