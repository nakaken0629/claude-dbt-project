select
    metric_id,
    table_name,
    metric_name,
    metric_description,
    threshold_value,
    created_at,
    updated_at
from {{ source('raw_vending_machine_data', 'mst_data_quality_metrics') }}