-- データ品質ダッシュボード用データマート
select
    table_name,
    error_level,
    error_count,
    unique_error_types,
    first_error_datetime,
    last_error_datetime,
    total_affected_records,
    -- データ品質スコア
    case 
        when error_level = 'FATAL' and error_count > 0 then 'Critical'
        when error_level = 'ERROR' and error_count > 10 then 'Poor'
        when error_level = 'WARNING' and error_count > 50 then 'Needs Attention'
        else 'Good'
    end as quality_status
from {{ ref('int_data_quality_summary') }}