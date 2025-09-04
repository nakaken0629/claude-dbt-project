{{ config(materialized='view') }}

with sales_data as (
    select * from {{ ref('fact_sales') }}
),

vending_machines as (
    select * from {{ ref('mst_vending_machine') }}
),

products as (
    select * from {{ ref('mst_product') }}
),

product_categories as (
    select * from {{ ref('mst_product_category') }}
),

payment_methods as (
    select * from {{ ref('mst_payment_method') }}
),

final as (
    select 
        vm.vending_machine_id,
        vm.location_name,
        p.product_name,
        pc.category_name,
        pm.payment_method_name,
        date(s.purchase_datetime) as purchase_date,
        count(*) as sales_count,
        sum(p.price) as total_sales_amount,
        sum(s.input_amount) as total_input_amount,
        sum(s.change_amount) as total_change_amount
    from sales_data s
    inner join vending_machines vm on s.vending_machine_id = vm.vending_machine_id
    inner join products p on s.product_id = p.product_id
    inner join product_categories pc on p.product_category_id = pc.product_category_id
    inner join payment_methods pm on s.payment_method_id = pm.payment_method_id
    group by 
        vm.vending_machine_id, vm.location_name,
        p.product_name, pc.category_name, 
        pm.payment_method_name, date(s.purchase_datetime)
)

select * from final