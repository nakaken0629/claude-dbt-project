select
    vending_machine_id,
    location_name,
    installation_date,
    created_at,
    updated_at
from {{ source('raw_vending_machine_data', 'mst_vending_machine') }}