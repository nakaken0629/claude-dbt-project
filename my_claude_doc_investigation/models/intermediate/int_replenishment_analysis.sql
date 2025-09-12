select
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name,
    count(r.replenishment_id) as replenishment_count,
    sum(r.replenishment_quantity) as total_replenishment_quantity,
    avg(r.replenishment_quantity) as avg_replenishment_quantity,
    min(r.replenishment_datetime) as first_replenishment_datetime,
    max(r.replenishment_datetime) as last_replenishment_datetime,
    count(distinct r.staff_id) as unique_staff_count
from {{ ref('stg_replenishments') }} r
inner join {{ ref('stg_vending_machines') }} vm
    on r.vending_machine_id = vm.vending_machine_id
inner join {{ ref('stg_products') }} p
    on r.product_id = p.product_id
group by
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name