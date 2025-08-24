# データモデリング設計

## 設計原則

### 1. レイヤード アーキテクチャ
データ変換を以下の3層に分離：

- **Staging Layer**: 生データのクリーニングと標準化
- **Intermediate Layer**: ビジネスロジックの適用
- **Mart Layer**: 分析用最終データセット

### 2. 命名規則
- **Staging**: `stg_[source]_[table]`
- **Intermediate**: `int_[domain]_[description]`
- **Mart**: `dim_[entity]`, `fct_[process]`

### 3. マテリアライゼーション戦略
- **Staging**: View（ストレージ最小化）
- **Intermediate**: View or Table（計算コストに応じて）
- **Mart**: Table（パフォーマンス重視）

## データソース分析

### customers.csv
```
customer_id (PK)    - 顧客ID
first_name          - 名前
last_name           - 姓
email (UK)          - メールアドレス（一意）
registration_date   - 登録日
status              - ステータス (active/inactive)
```

**データ品質課題**：
- メール重複の可能性
- 無効な日付フォーマット
- ステータス値の標準化

### orders.csv
```
order_id (PK)       - 注文ID
customer_id (FK)    - 顧客ID（外部キー）
order_date          - 注文日
total_amount        - 合計金額
status              - ステータス (completed/pending/cancelled)
```

**データ品質課題**：
- 負の金額値
- 未来日付の注文
- 参照整合性（存在しない顧客ID）

### products.csv
```
product_id (PK)     - 商品ID
product_name        - 商品名
category            - カテゴリ
price               - 価格
stock_quantity      - 在庫数
```

**データ品質課題**：
- 負の価格・在庫
- 商品名重複
- カテゴリ標準化

## 提案データモデル

### Staging Layer

#### stg_customers
```sql
-- 顧客データの基本クリーニング
- email正規化（小文字統一）
- status標準化
- 日付型変換
- NULL値ハンドリング
```

#### stg_orders
```sql
-- 注文データの基本クリーニング
- 日付型変換
- 金額値検証
- status標準化
- 外部キー検証
```

#### stg_products
```sql
-- 商品データの基本クリーニング
- 価格・在庫の数値検証
- カテゴリ標準化
- 商品名正規化
```

### Intermediate Layer

#### int_customer_orders
```sql
-- 顧客と注文の結合
- 顧客ごとの注文集計
- 初回/最終注文日
- 合計注文金額
- 注文件数
```

#### int_order_metrics
```sql
-- 注文メトリクス計算
- 月次注文トレンド
- 平均注文金額
- ステータス別集計
```

### Mart Layer

#### dim_customers
```sql
-- 顧客ディメンション
customer_key        - サロゲートキー
customer_id         - 自然キー
full_name          - 氏名結合
email              - メールアドレス
registration_date  - 登録日
status             - ステータス
customer_segment   - セグメント（派生項目）
```

#### dim_products
```sql
-- 商品ディメンション
product_key        - サロゲートキー
product_id         - 自然キー
product_name       - 商品名
category           - カテゴリ
current_price      - 現在価格
stock_status       - 在庫ステータス（派生項目）
```

#### fct_orders
```sql
-- 注文ファクト
order_key          - サロゲートキー
order_id           - 自然キー
customer_key       - 顧客キー（FK）
order_date         - 注文日
total_amount       - 合計金額
status             - ステータス
order_year         - 年（パーティション用）
order_month        - 月（パーティション用）
```

#### fct_customer_summary
```sql
-- 顧客サマリーファクト
customer_key       - 顧客キー（FK）
first_order_date   - 初回注文日
last_order_date    - 最終注文日
total_orders       - 総注文数
total_amount       - 総注文金額
avg_order_amount   - 平均注文金額
customer_ltv       - 顧客生涯価値
```

## データリネージ

```
sources/customers.csv → stg_customers → dim_customers
sources/orders.csv    → stg_orders ─┐
sources/products.csv  → stg_products → dim_products
                                    │
                      int_customer_orders → fct_orders
                                    │
                                    └─→ fct_customer_summary
```

## パフォーマンス考慮事項

### インデックス戦略
- 日付列にインデックス（order_date）
- 外部キーにインデックス（customer_id）
- よく使用される検索条件

### パーティション戦略
- 日付ベースパーティション（年月）
- 大きなファクトテーブルに適用

### 増分処理
- 新規/更新レコードのみ処理
- `incremental`マテリアライゼーション
- ウォーターマーク管理

## 拡張性への配慮

### 新データソース追加
- 統一的なstaging層パターン
- 標準的な命名規則
- 再利用可能なマクロ

### スケーラビリティ
- モジュール化された設計
- 依存関係の最小化
- 並列実行可能な構造