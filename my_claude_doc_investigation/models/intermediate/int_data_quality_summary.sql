select
    dql.table_name,
    dql.error_level,
    count(dql.log_id) as error_count,
    count(distinct dql.error_type) as unique_error_types,
    min(dql.created_at) as first_error_datetime,
    max(dql.created_at) as last_error_datetime,
    sum(coalesce(dql.record_count, 0)) as total_affected_records
from {{ ref('stg_data_quality_logs') }} dql
group by
    dql.table_name,
    dql.error_level