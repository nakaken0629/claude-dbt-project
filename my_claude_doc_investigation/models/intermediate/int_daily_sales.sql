{{ config(materialized='table') }}

select
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name,
    s.payment_method_name,
    s.purchase_date,
    count(s.sales_id) as sales_count,
    sum(s.sales_amount) as total_sales_amount,
    sum(s.input_amount) as total_input_amount,
    sum(s.change_amount) as total_change_amount
from {{ ref('stg_sales') }} s
left join {{ ref('stg_vending_machines') }} vm
    on s.vending_machine_id = vm.vending_machine_id
left join {{ ref('stg_products') }} p
    on s.product_id = p.product_id
group by
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name,
    s.payment_method_name,
    s.purchase_date