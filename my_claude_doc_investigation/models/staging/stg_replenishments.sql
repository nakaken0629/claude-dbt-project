select
    r.replenishment_id,
    r.vending_machine_id,
    r.product_id,
    r.replenishment_datetime,
    date(r.replenishment_datetime) as replenishment_date,
    r.replenishment_quantity,
    r.stock_before,
    r.stock_after,
    r.staff_id,
    r.created_at,
    s.staff_name
from {{ source('raw_vending_machine_data', 'fact_replenishment') }} r
left join {{ source('raw_vending_machine_data', 'mst_staff') }} s
    on r.staff_id = s.staff_id