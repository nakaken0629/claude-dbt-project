{{ config(materialized='view') }}

with source as (
    select * from {{ source('vending_machine_raw', 'product_category_master') }}
),

renamed as (
    select
        id as product_category_id,
        カテゴリ名 as category_name,
        current_timestamp as created_at,
        current_timestamp as updated_at
    
    from source
)

select * from renamed