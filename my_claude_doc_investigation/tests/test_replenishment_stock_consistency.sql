-- 補充データの在庫数整合性テスト: 補充前在庫 + 補充数量 = 補充後在庫
with inconsistent_replenishment as (
    select 
        replenishment_id,
        stock_before,
        replenishment_quantity,
        stock_after,
        (stock_before + replenishment_quantity) as expected_stock_after
    from {{ ref('fact_replenishment') }}
    where stock_before is not null 
      and stock_after is not null
      and (stock_before + replenishment_quantity) != stock_after
)

select * from inconsistent_replenishment