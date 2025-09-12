with latest_replenishment as (
    select 
        vending_machine_id,
        product_id,
        stock_after,
        replenishment_datetime,
        row_number() over (
            partition by vending_machine_id, product_id 
            order by replenishment_datetime desc
        ) as rn
    from {{ ref('stg_replenishments') }}
    where stock_after is not null
)

select 
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name,
    coalesce(lr.stock_after, 0) as current_stock,
    lr.replenishment_datetime as last_replenishment_datetime
from {{ ref('stg_vending_machines') }} vm
cross join {{ ref('stg_products') }} p
left join latest_replenishment lr 
    on vm.vending_machine_id = lr.vending_machine_id 
    and p.product_id = lr.product_id 
    and lr.rn = 1