{{ config(materialized='view') }}

with source as (
    select * from {{ source('vending_machine_raw', 'product_master') }}
),

renamed as (
    select
        id as product_id,
        商品カテゴリid as product_category_id,
        商品名 as product_name,
        値段 as price,
        current_timestamp as created_at,
        current_timestamp as updated_at
    
    from source
)

select * from renamed