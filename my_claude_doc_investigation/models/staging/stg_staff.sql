{{ config(materialized='view') }}

with source as (
    select * from {{ source('vending_machine_raw', 'staff_master') }}
),

renamed as (
    select
        id as staff_id,
        担当者名 as staff_name,
        current_timestamp as created_at,
        current_timestamp as updated_at
    
    from source
)

select * from renamed