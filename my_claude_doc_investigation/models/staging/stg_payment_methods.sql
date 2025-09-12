select
    payment_method_id,
    payment_method_name,
    created_at,
    updated_at
from {{ source('raw_vending_machine_data', 'mst_payment_method') }}