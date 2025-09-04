{{ config(materialized='incremental', unique_key='replenishment_id') }}

with final as (
    select
        replenishment_id,
        vending_machine_id,
        product_id,
        replenishment_datetime,
        replenishment_quantity,
        stock_before,
        stock_after,
        staff_id,
        created_at
    from {{ ref('stg_replenishments') }}
    
    {% if is_incremental() %}
        -- 増分処理：最新の作成日時以降のレコードのみを処理
        where created_at > (select max(created_at) from {{ this }})
    {% endif %}
)

select * from final