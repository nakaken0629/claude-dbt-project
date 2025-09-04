{{ config(materialized='incremental', unique_key='sales_id') }}

with final as (
    select
        sales_id,
        vending_machine_id,
        product_id,
        purchase_datetime,
        payment_method_id,
        input_amount,
        change_amount,
        created_at
    from {{ ref('stg_sales') }}
    
    {% if is_incremental() %}
        -- 増分処理：最新の作成日時以降のレコードのみを処理
        where created_at > (select max(created_at) from {{ this }})
    {% endif %}
)

select * from final