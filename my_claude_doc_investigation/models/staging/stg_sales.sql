{{ config(materialized='view') }}

select
    s.sales_id,
    s.vending_machine_id,
    s.product_id,
    s.purchase_datetime,
    date(s.purchase_datetime) as purchase_date,
    s.payment_method_id,
    s.input_amount,
    s.change_amount,
    (s.input_amount - s.change_amount) as sales_amount,
    s.created_at,
    pm.payment_method_name
from {{ source('raw_vending_machine_data', 'fact_sales') }} s
left join {{ source('raw_vending_machine_data', 'mst_payment_method') }} pm
    on s.payment_method_id = pm.payment_method_id