{{ config(materialized='view') }}

with source as (
    select * from {{ source('vending_machine_raw', 'sales_data') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['自動販売機id', '商品id', '購入日時']) }} as sales_id,
        自動販売機id as vending_machine_id,
        商品id as product_id,
        購入日時 as purchase_datetime,
        決済方法id as payment_method_id,
        投入金額 as input_amount,
        お釣り as change_amount,
        current_timestamp as created_at
    
    from source
)

select * from renamed