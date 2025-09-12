select
    staff_id,
    staff_name,
    created_at,
    updated_at
from {{ source('raw_vending_machine_data', 'mst_staff') }}