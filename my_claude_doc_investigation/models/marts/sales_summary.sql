-- 基本設計書のview_sales_summaryに対応
select
    vending_machine_id,
    location_name,
    product_name,
    category_name,
    payment_method_name,
    purchase_date,
    sales_count,
    total_sales_amount,
    total_input_amount,
    total_change_amount
from {{ ref('int_daily_sales') }}