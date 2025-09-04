{{ config(materialized='table') }}

with final as (
    select
        payment_method_id,
        payment_method_name,
        created_at,
        updated_at
    from {{ ref('stg_payment_methods') }}
)

select * from final