select
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name,
    count(s.sales_id) as total_sales_count,
    sum(p.price) as total_revenue,
    avg(p.price) as avg_price,
    min(s.purchase_datetime) as first_sale_datetime,
    max(s.purchase_datetime) as last_sale_datetime
from {{ ref('stg_sales') }} s
inner join {{ ref('stg_vending_machines') }} vm
    on s.vending_machine_id = vm.vending_machine_id
inner join {{ ref('stg_products') }} p
    on s.product_id = p.product_id
group by
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name