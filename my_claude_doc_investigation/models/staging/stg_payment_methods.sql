{{ config(materialized='view') }}

with source as (
    select * from {{ source('vending_machine_raw', 'payment_method_master') }}
),

renamed as (
    select
        id as payment_method_id,
        決済方法名 as payment_method_name,
        current_timestamp as created_at,
        current_timestamp as updated_at
    
    from source
)

select * from renamed