{{ config(materialized='view') }}

with source as (
    select * from {{ source('vending_machine_raw', 'vending_machine_master') }}
),

renamed as (
    select
        id as vending_machine_id,
        設置場所 as location_name,
        設置日 as installation_date,
        current_timestamp as created_at,
        current_timestamp as updated_at
    
    from source
)

select * from renamed