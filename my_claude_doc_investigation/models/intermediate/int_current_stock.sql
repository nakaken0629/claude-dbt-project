{{ config(materialized='table') }}

with latest_replenishments as (
    select
        vending_machine_id,
        product_id,
        max(replenishment_datetime) as last_replenishment_datetime
    from {{ ref('stg_replenishments') }}
    group by vending_machine_id, product_id
),

latest_stock as (
    select
        r.vending_machine_id,
        r.product_id,
        r.stock_after as current_stock,
        r.replenishment_datetime as last_replenishment_datetime
    from {{ ref('stg_replenishments') }} r
    inner join latest_replenishments lr
        on r.vending_machine_id = lr.vending_machine_id
        and r.product_id = lr.product_id
        and r.replenishment_datetime = lr.last_replenishment_datetime
),

sales_after_replenishment as (
    select
        s.vending_machine_id,
        s.product_id,
        coalesce(ls.last_replenishment_datetime, '1900-01-01'::timestamp) as last_replenishment_datetime,
        count(s.sales_id) as sales_since_replenishment
    from {{ ref('stg_sales') }} s
    left join latest_stock ls
        on s.vending_machine_id = ls.vending_machine_id
        and s.product_id = ls.product_id
    where s.purchase_datetime > coalesce(ls.last_replenishment_datetime, '1900-01-01'::timestamp)
    group by
        s.vending_machine_id,
        s.product_id,
        ls.last_replenishment_datetime
)

select
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    p.category_name,
    coalesce(ls.current_stock, 0) - coalesce(sar.sales_since_replenishment, 0) as current_stock,
    ls.last_replenishment_datetime
from {{ ref('stg_vending_machines') }} vm
cross join {{ ref('stg_products') }} p
left join latest_stock ls
    on vm.vending_machine_id = ls.vending_machine_id
    and p.product_id = ls.product_id
left join sales_after_replenishment sar
    on vm.vending_machine_id = sar.vending_machine_id
    and p.product_id = sar.product_id