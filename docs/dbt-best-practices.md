# dbtベストプラクティスガイド

## プロジェクト構造

### 推奨ディレクトリ構造
```
models/
├── staging/           # ソースデータの基本変換
│   ├── _stg__sources.yml
│   ├── stg_customers.sql
│   ├── stg_orders.sql
│   └── stg_products.sql
├── intermediate/      # ビジネスロジック適用
│   ├── int_customer_orders.sql
│   └── int_order_metrics.sql
├── marts/            # 分析用最終データセット
│   ├── core/         # コアビジネス指標
│   │   ├── dim_customers.sql
│   │   ├── dim_products.sql
│   │   └── fct_orders.sql
│   └── marketing/    # 部門別データマート
│       └── fct_customer_summary.sql
└── _models.yml       # 全モデル共通設定
```

## 命名規則

### ファイル命名
- **小文字とアンダースコア**: `dim_customers.sql`
- **レイヤー接頭辞**: `stg_`, `int_`, `dim_`, `fct_`
- **説明的な名前**: `int_customer_lifetime_value.sql`

### SQL内命名
- **テーブルエイリアス**: 短縮形を使用（`customers as c`）
- **カラム名**: スネークケース（`first_name`）
- **予約語回避**: バッククォートで囲む

```sql
-- ✅ 良い例
select
    customer_id,
    first_name,
    last_name,
    email as customer_email
from {{ ref('stg_customers') }} as c

-- ❌ 悪い例
SELECT customer_id,first_name,last_name,email
FROM stg_customers
```

## SQLスタイルガイド

### 基本フォーマット
```sql
-- ✅ 推奨フォーマット
select
    customer_id,
    first_name,
    last_name,
    case 
        when status = 'active' then 1 
        else 0 
    end as is_active,
    registration_date

from {{ ref('stg_customers') }}

where registration_date >= '2023-01-01'
    and status is not null

order by registration_date desc
```

### SELECT文のルール
1. **カラム毎に改行**
2. **カンマは行頭**
3. **インデントで階層表現**
4. **FROM句は改行**

### JOIN文のベストプラクティス
```sql
-- ✅ 明示的なJOIN
select
    c.customer_id,
    c.full_name,
    o.order_count,
    o.total_amount

from {{ ref('dim_customers') }} as c
left join {{ ref('fct_customer_summary') }} as o
    on c.customer_id = o.customer_id

-- ❌ 暗黙的なJOIN
select * 
from customers c, orders o 
where c.id = o.customer_id
```

## モデル設計原則

### 1. DRY原則（Don't Repeat Yourself）
- 共通ロジックはマクロ化
- 再利用可能なインターミディエットモデル
- 変数やマクロで設定値管理

### 2. 単一責任原則
- 1つのモデルは1つの目的
- 複雑な変換は段階的に分割
- レイヤー間の責任分離

### 3. テスタビリティ
- 各段階でテスト可能
- 期待値が明確
- エラー再現可能

## マクロの活用

### 基本マクロ例
```sql
-- macros/generate_schema_name.sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

### ユーティリティマクロ
```sql
-- macros/safe_divide.sql
{% macro safe_divide(numerator, denominator) %}
    case 
        when {{ denominator }} = 0 then null
        else {{ numerator }} / {{ denominator }}
    end
{% endmacro %}
```

## テストとドキュメント

### schema.ymlの構造
```yaml
version: 2

models:
  - name: dim_customers
    description: "顧客ディメンションテーブル"
    columns:
      - name: customer_id
        description: "顧客ID（主キー）"
        tests:
          - unique
          - not_null
      
      - name: email
        description: "顧客メールアドレス"
        tests:
          - unique
          - not_null
          - relationships:
              to: ref('stg_customers')
              field: email
```

### カスタムテスト
```sql
-- tests/assert_positive_amounts.sql
select *
from {{ ref('fct_orders') }}
where total_amount <= 0
```

## パフォーマンス最適化

### マテリアライゼーション選択指針

#### View
- **用途**: 小さなデータセット、リアルタイム要求
- **利点**: ストレージ不要、常に最新
- **欠点**: 実行時計算コスト

#### Table
- **用途**: 大きなデータセット、頻繁アクセス
- **利点**: 高速アクセス
- **欠点**: ストレージ使用、更新遅延

#### Incremental
- **用途**: 大容量で増加するデータ
- **利点**: 効率的更新
- **欠点**: 複雑な実装

```sql
-- models/fct_orders.sql
{{
  config(
    materialized='incremental',
    unique_key='order_id',
    on_schema_change='fail'
  )
}}

select * from {{ ref('stg_orders') }}

{% if is_incremental() %}
  where order_date > (select max(order_date) from {{ this }})
{% endif %}
```

## エラーハンドリング

### データ品質チェック
```sql
-- 無効データのハンドリング
select
    customer_id,
    case 
        when email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$' 
        then email
        else null 
    end as email_validated,
    coalesce(status, 'unknown') as status_clean

from {{ source('raw_data', 'customers') }}
```

### NULL値処理
```sql
-- 明示的なNULL処理
select
    customer_id,
    coalesce(first_name, 'Unknown') as first_name,
    coalesce(last_name, '') as last_name,
    nullif(trim(email), '') as email

from {{ ref('stg_customers') }}
```

## バージョン管理

### Git運用
1. **ブランチ戦略**: feature → develop → main
2. **コミットメッセージ**: 変更内容明記
3. **プルリクエスト**: レビュー必須

### 本番デプロイ
```bash
# 本番デプロイ手順
dbt deps                    # 依存関係更新
dbt seed                    # シードデータ投入
dbt run --target prod       # 本番実行
dbt test --target prod      # 本番テスト
dbt docs generate --target prod # ドキュメント生成
```

## 監視とメンテナンス

### 定期チェック項目
- [ ] テスト実行結果確認
- [ ] 実行時間モニタリング
- [ ] データ品質メトリクス
- [ ] ドキュメント更新状況

### パフォーマンス監視
```sql
-- 実行時間の長いモデル特定
select 
    model_name,
    avg(execution_time_seconds) as avg_execution_time
from dbt_run_results
group by model_name
order by avg_execution_time desc
```

## セキュリティ考慮事項

### 機密データ処理
- PII（個人情報）のマスキング
- アクセス制御の実装
- ログへの機密情報出力回避

```sql
-- PII マスキング例
select
    customer_id,
    left(first_name, 1) || '***' as first_name_masked,
    md5(email) as email_hash
from {{ ref('stg_customers') }}
```