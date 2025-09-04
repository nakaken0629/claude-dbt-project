-- 売上データの金額整合性テスト: 投入金額 - お釣り = 商品価格
with sales_with_price as (
    select 
        s.sales_id,
        s.input_amount,
        s.change_amount,
        p.price,
        (s.input_amount - s.change_amount) as net_amount
    from {{ ref('fact_sales') }} s
    inner join {{ ref('mst_product') }} p on s.product_id = p.product_id
),

inconsistent_sales as (
    select *
    from sales_with_price
    where net_amount != price
)

select * from inconsistent_sales