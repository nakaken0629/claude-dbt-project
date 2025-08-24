# テスト戦略ドキュメント

## テスト戦略の概要

### 目的
データパイプラインの信頼性と品質を確保するための包括的なテスト戦略を定義します。

### テストレベル
1. **ユニットテスト**: 個別モデルの検証
2. **統合テスト**: モデル間の関係性検証
3. **エンドツーエンドテスト**: パイプライン全体の検証
4. **データ品質テスト**: ビジネスルールの検証

## dbt標準テスト

### 基本テスト（Generic Tests）

#### not_null
```yaml
# 必須フィールドのNULL値チェック
- name: customer_id
  tests:
    - not_null
```

#### unique
```yaml
# 主キーや一意制約のチェック
- name: customer_id
  tests:
    - unique
```

#### accepted_values
```yaml
# 許可された値のリストチェック
- name: status
  tests:
    - accepted_values:
        values: ['active', 'inactive', 'suspended']
```

#### relationships
```yaml
# 外部キー制約チェック
- name: customer_id
  tests:
    - relationships:
        to: ref('dim_customers')
        field: customer_id
```

### 組み合わせテスト
```yaml
version: 2

models:
  - name: dim_customers
    description: "顧客ディメンション"
    tests:
      # 複数カラムの組み合わせ一意性
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - first_name
            - last_name
            - email
    columns:
      - name: customer_id
        tests:
          - not_null
          - unique
      
      - name: email
        tests:
          - not_null
          - unique
          - dbt_utils.not_constant
      
      - name: registration_date
        tests:
          - not_null
          - dbt_utils.not_constant
      
      - name: status
        tests:
          - accepted_values:
              values: ['active', 'inactive']
```

## カスタムテスト

### データ品質カスタムテスト

#### 正の値チェック
```sql
-- tests/assert_positive_order_amounts.sql
-- 注文金額が正の値であることを確認
select order_id, total_amount
from {{ ref('fct_orders') }}
where total_amount <= 0
```

#### 日付範囲チェック
```sql
-- tests/assert_valid_order_dates.sql
-- 注文日が有効範囲内であることを確認
select order_id, order_date
from {{ ref('fct_orders') }}
where order_date > current_date
   or order_date < '2020-01-01'
```

#### メール形式チェック
```sql
-- tests/assert_valid_email_format.sql
-- メールアドレス形式の検証
select customer_id, email
from {{ ref('dim_customers') }}
where email is not null
  and not regexp_matches(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
```

### ビジネスルールテスト

#### 顧客注文整合性
```sql
-- tests/assert_customer_order_consistency.sql
-- すべての注文に対応する顧客が存在することを確認
select o.order_id, o.customer_id
from {{ ref('fct_orders') }} o
left join {{ ref('dim_customers') }} c 
  on o.customer_id = c.customer_id
where c.customer_id is null
```

#### 在庫論理チェック
```sql
-- tests/assert_stock_logic.sql
-- 在庫数が負でないことを確認
select product_id, stock_quantity
from {{ ref('dim_products') }}
where stock_quantity < 0
```

#### 集計値整合性
```sql
-- tests/assert_summary_totals.sql
-- 顧客サマリーの整合性チェック
with order_totals as (
  select 
    customer_id,
    count(*) as actual_order_count,
    sum(total_amount) as actual_total_amount
  from {{ ref('fct_orders') }}
  group by customer_id
),

summary_totals as (
  select 
    customer_id,
    total_orders,
    total_amount
  from {{ ref('fct_customer_summary') }}
)

select 
  o.customer_id,
  o.actual_order_count,
  s.total_orders,
  o.actual_total_amount,
  s.total_amount
from order_totals o
join summary_totals s on o.customer_id = s.customer_id
where o.actual_order_count != s.total_orders
   or abs(o.actual_total_amount - s.total_amount) > 0.01
```

## dbt-utilsテスト活用

### インストールと設定
```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```

### 便利なdbt-utilsテスト

#### equal_rowcount
```yaml
# 2つのテーブルの行数が等しいことを確認
- name: stg_orders
  tests:
    - dbt_utils.equal_rowcount:
        compare_model: source('raw', 'orders')
```

#### expression_is_true
```yaml
# 複雑な条件式テスト
- name: fct_orders
  tests:
    - dbt_utils.expression_is_true:
        expression: "total_amount >= 0"
```

#### mutually_exclusive_ranges
```yaml
# 日付範囲の重複チェック
- name: customer_segments
  tests:
    - dbt_utils.mutually_exclusive_ranges:
        lower_bound_column: start_date
        upper_bound_column: end_date
        partition_by: customer_id
```

## テスト実行戦略

### 開発時テスト
```bash
# モデル作成後の基本チェック
dbt run --select model_name
dbt test --select model_name

# 関連モデル含むテスト
dbt test --select model_name+
```

### CI/CDパイプライン
```bash
#!/bin/bash
# CI/CDテストスクリプト

# 依存関係チェック
dbt deps

# モデル実行
dbt run --target ci

# 全テスト実行
dbt test --target ci

# テスト結果チェック
if [ $? -eq 0 ]; then
    echo "All tests passed!"
else
    echo "Tests failed!"
    exit 1
fi
```

### 本番前チェックリスト
- [ ] すべての標準テストが通過
- [ ] カスタムテストが通過
- [ ] データ量チェック
- [ ] パフォーマンステスト
- [ ] セキュリティチェック

## テスト環境管理

### 環境別テスト設定
```yaml
# dbt_project.yml
vars:
  # 開発環境での小さなデータセット
  start_date: '2024-01-01'
  
# プロファイル設定での環境切り替え
test:
  start_date: '2023-01-01'  # より多くのデータでテスト

prod:
  start_date: '2020-01-01'  # 全データ
```

### テストデータ管理
```sql
-- seeds/test_customers.csv を使用
-- テスト用の既知データセット
customer_id,first_name,last_name,email,status
1,Test,User,test@example.com,active
2,Invalid,User,invalid-email,active
```

## テスト結果の監視

### テスト失敗時の対応手順
1. **エラー内容確認**: ログの詳細分析
2. **データ調査**: 失敗したレコードの特定
3. **根本原因分析**: データソースまたはロジックの問題特定
4. **修正**: モデルまたはテストの修正
5. **再実行**: 修正後の検証

### メトリクス収集
```sql
-- テスト結果サマリー
select 
  test_name,
  model_name,
  status,
  error_count,
  execution_time,
  run_date
from test_execution_log
where run_date >= current_date - interval '7 days'
```

## パフォーマンステスト

### 実行時間テスト
```sql
-- tests/assert_model_performance.sql
-- モデル実行時間が許容範囲内であることを確認
with execution_times as (
  select 
    model_name,
    execution_time_seconds
  from dbt_run_results
  where model_name = '{{ this.name }}'
    and run_date >= current_date
)

select *
from execution_times
where execution_time_seconds > 300  -- 5分以上の場合は失敗
```

### データ量テスト
```sql
-- tests/assert_reasonable_row_count.sql
-- 異常なデータ量増加の検出
select count(*)
from {{ ref('fct_orders') }}
having count(*) > (
  select count(*) * 1.5  -- 50%以上の増加でアラート
  from {{ ref('fct_orders') }}
  -- 前日データとの比較ロジック
)
```

## テスト文書化

### テスト仕様書
各テストについて以下を文書化：
- **目的**: なぜこのテストが必要か
- **期待値**: どのような結果を期待するか
- **失敗時の影響**: テスト失敗時のビジネス影響
- **対応手順**: 失敗時の対応方法

### テストカバレッジ
```yaml
# テストカバレッジ目標
coverage_targets:
  - staging_models: 100%      # 基本テスト必須
  - mart_models: 100%         # ビジネスルールテスト含む
  - custom_logic: 90%         # 複雑なロジックのテスト
  - edge_cases: 80%          # エッジケースの考慮
```