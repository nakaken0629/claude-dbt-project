select
    product_category_id,
    category_name,
    created_at,
    updated_at
from {{ source('raw_vending_machine_data', 'mst_product_category') }}