{{ config(materialized='table') }}

with final as (
    select
        product_category_id,
        category_name,
        created_at,
        updated_at
    from {{ ref('stg_product_categories') }}
)

select * from final