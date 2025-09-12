-- 売上パフォーマンスダッシュボード用データマート
select
    vending_machine_id,
    location_name,
    product_id,
    product_name,
    category_name,
    total_sales_count,
    total_revenue,
    avg_price,
    first_sale_datetime,
    last_sale_datetime,
    -- パフォーマンス指標
    case 
        when total_sales_count >= 100 then 'High'
        when total_sales_count >= 50 then 'Medium'
        else 'Low'
    end as sales_performance_tier
from {{ ref('int_sales_performance') }}