-- 補充業務インサイト用データマート
select
    vending_machine_id,
    location_name,
    product_id,
    product_name,
    category_name,
    replenishment_count,
    total_replenishment_quantity,
    avg_replenishment_quantity,
    first_replenishment_datetime,
    last_replenishment_datetime,
    unique_staff_count,
    -- 補充効率指標
    case 
        when replenishment_count = 0 then 'No Data'
        when avg_replenishment_quantity >= 20 then 'Efficient'
        when avg_replenishment_quantity >= 10 then 'Moderate'
        else 'Frequent'
    end as replenishment_efficiency
from {{ ref('int_replenishment_analysis') }}