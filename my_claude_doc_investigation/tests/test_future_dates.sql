-- 未来日付チェック：購入日時と補充日時が未来でないことを確認
with future_sales as (
    select 
        'sales' as table_name,
        sales_id as record_id,
        purchase_datetime as event_datetime
    from {{ ref('fact_sales') }}
    where purchase_datetime > current_timestamp
),

future_replenishments as (
    select 
        'replenishment' as table_name,
        replenishment_id as record_id,
        replenishment_datetime as event_datetime
    from {{ ref('fact_replenishment') }}
    where replenishment_datetime > current_timestamp
),

all_future_dates as (
    select * from future_sales
    union all
    select * from future_replenishments
)

select * from all_future_dates