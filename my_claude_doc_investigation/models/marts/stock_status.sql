{{ config(materialized='table') }}

select
    vending_machine_id,
    location_name,
    product_id,
    product_name,
    category_name,
    current_stock,
    last_replenishment_datetime
from {{ ref('int_current_stock') }}