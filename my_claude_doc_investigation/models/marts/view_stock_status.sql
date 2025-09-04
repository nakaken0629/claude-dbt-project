{{ config(materialized='view') }}

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
    from {{ ref('fact_replenishment') }}
    where stock_after is not null
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

final as (
    select 
        vm.vending_machine_id,
        vm.location_name,
        p.product_id,
        p.product_name,
        pc.category_name,
        coalesce(lr.stock_after, 0) as current_stock,
        lr.replenishment_datetime as last_replenishment_datetime
    from vending_machines vm
    cross join products p
    inner join product_categories pc on p.product_category_id = pc.product_category_id
    left join latest_replenishment lr on vm.vending_machine_id = lr.vending_machine_id 
        and p.product_id = lr.product_id 
        and lr.rn = 1
)

select * from final