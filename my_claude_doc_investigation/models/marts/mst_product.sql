{{ config(materialized='table') }}

with final as (
    select
        product_id,
        product_category_id,
        product_name,
        price,
        created_at,
        updated_at
    from {{ ref('stg_products') }}
)

select * from final