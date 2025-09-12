select
    log_id,
    table_name,
    column_name,
    error_type,
    error_level,
    error_message,
    source_data,
    record_count,
    created_at
from {{ source('raw_vending_machine_data', 'log_data_quality') }}