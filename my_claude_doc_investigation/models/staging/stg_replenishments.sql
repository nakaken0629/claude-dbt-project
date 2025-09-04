{{ config(materialized='view') }}

with source as (
    select * from {{ source('vending_machine_raw', 'replenishment_records') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['自動販売機id', '商品id', '補充日時']) }} as replenishment_id,
        自動販売機id as vending_machine_id,
        商品id as product_id,
        補充日時 as replenishment_datetime,
        補充数量 as replenishment_quantity,
        補充前在庫数 as stock_before,
        補充後在庫数 as stock_after,
        補充担当者id as staff_id,
        current_timestamp as created_at
    
    from source
)

select * from renamed