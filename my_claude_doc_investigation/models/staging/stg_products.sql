select
    p.product_id,
    p.product_category_id,
    p.product_name,
    p.price,
    p.created_at,
    p.updated_at,
    pc.category_name
from {{ source('raw_vending_machine_data', 'mst_product') }} p
left join {{ source('raw_vending_machine_data', 'mst_product_category') }} pc
    on p.product_category_id = pc.product_category_id