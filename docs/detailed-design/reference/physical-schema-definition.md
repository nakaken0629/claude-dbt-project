# 物理スキーマ定義書

## 概要

本ドキュメントは、my_claude_doc_investigationプロジェクトで使用する物理データベーススキーマの定義を記載します。実装に必要なテーブル構造、DDL、インデックス定義などの具体的なスキーマ情報を提供します。

## 物理テーブル定義

### マスタデータテーブル

#### 1. 自動販売機マスタ（mst_vending_machine）

##### テーブル構造
| 物理列名 | データ型 | NULL許可 | 制約 | デフォルト値 | 説明 |
|---------|---------|---------|------|-------------|------|
| vending_machine_id | VARCHAR | NOT NULL | PRIMARY KEY | - | 自動販売機ID |
| location_name | VARCHAR | NOT NULL | - | - | 設置場所 |
| installation_date | DATE | NOT NULL | - | - | 設置日 |
| created_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 更新日時 |

##### DDL定義
```sql
CREATE TABLE mst_vending_machine (
    vending_machine_id VARCHAR NOT NULL,
    location_name VARCHAR NOT NULL,
    installation_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_mst_vending_machine PRIMARY KEY (vending_machine_id)
);
```

##### インデックス定義
```sql
-- 設置日による検索用
CREATE INDEX idx_mst_vending_machine_installation_date 
ON mst_vending_machine(installation_date);

-- 設置場所による検索用（部分一致対応）
CREATE INDEX idx_mst_vending_machine_location 
ON mst_vending_machine(location_name);
```

#### 2. 商品カテゴリマスタ（mst_product_category）

##### テーブル構造
| 物理列名 | データ型 | NULL許可 | 制約 | デフォルト値 | 説明 |
|---------|---------|---------|------|-------------|------|
| product_category_id | VARCHAR | NOT NULL | PRIMARY KEY | - | 商品カテゴリID |
| category_name | VARCHAR | NOT NULL | UNIQUE | - | カテゴリ名 |
| created_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 更新日時 |

##### DDL定義
```sql
CREATE TABLE mst_product_category (
    product_category_id VARCHAR NOT NULL,
    category_name VARCHAR NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_mst_product_category PRIMARY KEY (product_category_id),
    CONSTRAINT uk_mst_product_category_name UNIQUE (category_name)
);
```

#### 3. 商品マスタ（mst_product）

##### テーブル構造
| 物理列名 | データ型 | NULL許可 | 制約 | デフォルト値 | 説明 |
|---------|---------|---------|------|-------------|------|
| product_id | VARCHAR | NOT NULL | PRIMARY KEY | - | 商品ID |
| product_category_id | VARCHAR | NOT NULL | FOREIGN KEY | - | 商品カテゴリID |
| product_name | VARCHAR | NOT NULL | - | - | 商品名 |
| price | DECIMAL(10,0) | NOT NULL | CHECK (price >= 0) | - | 販売価格（円） |
| created_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 更新日時 |

##### DDL定義
```sql
CREATE TABLE mst_product (
    product_id VARCHAR NOT NULL,
    product_category_id VARCHAR NOT NULL,
    product_name VARCHAR NOT NULL,
    price DECIMAL(10,0) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_mst_product PRIMARY KEY (product_id),
    CONSTRAINT fk_mst_product_category 
        FOREIGN KEY (product_category_id) 
        REFERENCES mst_product_category(product_category_id),
    CONSTRAINT chk_mst_product_price CHECK (price >= 0)
);
```

##### インデックス定義
```sql
-- カテゴリによる商品検索用
CREATE INDEX idx_mst_product_category 
ON mst_product(product_category_id);

-- 商品名による検索用
CREATE INDEX idx_mst_product_name 
ON mst_product(product_name);

-- 価格帯による検索用
CREATE INDEX idx_mst_product_price 
ON mst_product(price);
```

#### 4. 担当者マスタ（mst_staff）

##### テーブル構造
| 物理列名 | データ型 | NULL許可 | 制約 | デフォルト値 | 説明 |
|---------|---------|---------|------|-------------|------|
| staff_id | VARCHAR | NOT NULL | PRIMARY KEY | - | 担当者ID |
| staff_name | VARCHAR | NOT NULL | - | - | 担当者名 |
| created_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 更新日時 |

##### DDL定義
```sql
CREATE TABLE mst_staff (
    staff_id VARCHAR NOT NULL,
    staff_name VARCHAR NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_mst_staff PRIMARY KEY (staff_id)
);
```

#### 5. 決済方法マスタ（mst_payment_method）

##### テーブル構造
| 物理列名 | データ型 | NULL許可 | 制約 | デフォルト値 | 説明 |
|---------|---------|---------|------|-------------|------|
| payment_method_id | VARCHAR | NOT NULL | PRIMARY KEY | - | 決済方法ID |
| payment_method_name | VARCHAR | NOT NULL | UNIQUE | - | 決済方法名 |
| created_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 更新日時 |

##### DDL定義
```sql
CREATE TABLE mst_payment_method (
    payment_method_id VARCHAR NOT NULL,
    payment_method_name VARCHAR NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_mst_payment_method PRIMARY KEY (payment_method_id),
    CONSTRAINT uk_mst_payment_method_name UNIQUE (payment_method_name)
);
```

### トランザクションデータテーブル

#### 1. 売上ファクトテーブル（fact_sales）

##### テーブル構造
| 物理列名 | データ型 | NULL許可 | 制約 | デフォルト値 | 説明 |
|---------|---------|---------|------|-------------|------|
| sales_id | BIGINT | NOT NULL | PRIMARY KEY | - | 売上ID（サロゲートキー） |
| vending_machine_id | VARCHAR | NOT NULL | FOREIGN KEY | - | 自動販売機ID |
| product_id | VARCHAR | NOT NULL | FOREIGN KEY | - | 商品ID |
| purchase_datetime | TIMESTAMP | NOT NULL | - | - | 購入日時 |
| payment_method_id | VARCHAR | NOT NULL | FOREIGN KEY | - | 決済方法ID |
| input_amount | DECIMAL(10,0) | NOT NULL | CHECK (input_amount >= 0) | - | 投入金額（円） |
| change_amount | DECIMAL(10,0) | NOT NULL | CHECK (change_amount >= 0) | - | お釣り金額（円） |
| created_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 作成日時 |

##### DDL定義
```sql
CREATE TABLE fact_sales (
    sales_id BIGINT NOT NULL,
    vending_machine_id VARCHAR NOT NULL,
    product_id VARCHAR NOT NULL,
    purchase_datetime TIMESTAMP NOT NULL,
    payment_method_id VARCHAR NOT NULL,
    input_amount DECIMAL(10,0) NOT NULL,
    change_amount DECIMAL(10,0) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_fact_sales PRIMARY KEY (sales_id),
    CONSTRAINT fk_fact_sales_vending_machine 
        FOREIGN KEY (vending_machine_id) 
        REFERENCES mst_vending_machine(vending_machine_id),
    CONSTRAINT fk_fact_sales_product 
        FOREIGN KEY (product_id) 
        REFERENCES mst_product(product_id),
    CONSTRAINT fk_fact_sales_payment_method 
        FOREIGN KEY (payment_method_id) 
        REFERENCES mst_payment_method(payment_method_id),
    CONSTRAINT chk_fact_sales_input_amount CHECK (input_amount >= 0),
    CONSTRAINT chk_fact_sales_change_amount CHECK (change_amount >= 0)
);
```

##### インデックス定義
```sql
-- 購入日時による時系列検索用（最も重要）
CREATE INDEX idx_fact_sales_purchase_datetime 
ON fact_sales(purchase_datetime);

-- 自動販売機別売上集計用
CREATE INDEX idx_fact_sales_vending_machine 
ON fact_sales(vending_machine_id);

-- 商品別売上集計用
CREATE INDEX idx_fact_sales_product 
ON fact_sales(product_id);

-- 決済方法別売上集計用
CREATE INDEX idx_fact_sales_payment_method 
ON fact_sales(payment_method_id);

-- 日付×自動販売機の複合検索用
CREATE INDEX idx_fact_sales_date_vm 
ON fact_sales(purchase_datetime, vending_machine_id);

-- 自動販売機×商品の複合検索用
CREATE INDEX idx_fact_sales_vm_product 
ON fact_sales(vending_machine_id, product_id);
```

##### パーティション定義（Snowflake用）
```sql
-- 月次パーティション（Snowflake）
CREATE TABLE fact_sales (
    -- カラム定義は上記と同様
) 
PARTITION BY (DATE_TRUNC('MONTH', purchase_datetime));
```

#### 2. 商品補充ファクトテーブル（fact_replenishment）

##### テーブル構造
| 物理列名 | データ型 | NULL許可 | 制約 | デフォルト値 | 説明 |
|---------|---------|---------|------|-------------|------|
| replenishment_id | BIGINT | NOT NULL | PRIMARY KEY | - | 補充ID（サロゲートキー） |
| vending_machine_id | VARCHAR | NOT NULL | FOREIGN KEY | - | 自動販売機ID |
| product_id | VARCHAR | NOT NULL | FOREIGN KEY | - | 商品ID |
| replenishment_datetime | TIMESTAMP | NOT NULL | - | - | 補充日時 |
| replenishment_quantity | INTEGER | NOT NULL | CHECK (replenishment_quantity > 0) | - | 補充数量 |
| stock_before | INTEGER | NULL | CHECK (stock_before >= 0) | - | 補充前在庫数 |
| stock_after | INTEGER | NULL | CHECK (stock_after >= 0) | - | 補充後在庫数 |
| staff_id | VARCHAR | NULL | FOREIGN KEY | - | 補充担当者ID |
| created_at | TIMESTAMP | NOT NULL | - | CURRENT_TIMESTAMP | 作成日時 |

##### DDL定義
```sql
CREATE TABLE fact_replenishment (
    replenishment_id BIGINT NOT NULL,
    vending_machine_id VARCHAR NOT NULL,
    product_id VARCHAR NOT NULL,
    replenishment_datetime TIMESTAMP NOT NULL,
    replenishment_quantity INTEGER NOT NULL,
    stock_before INTEGER,
    stock_after INTEGER,
    staff_id VARCHAR,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_fact_replenishment PRIMARY KEY (replenishment_id),
    CONSTRAINT fk_fact_replenishment_vending_machine 
        FOREIGN KEY (vending_machine_id) 
        REFERENCES mst_vending_machine(vending_machine_id),
    CONSTRAINT fk_fact_replenishment_product 
        FOREIGN KEY (product_id) 
        REFERENCES mst_product(product_id),
    CONSTRAINT fk_fact_replenishment_staff 
        FOREIGN KEY (staff_id) 
        REFERENCES mst_staff(staff_id),
    CONSTRAINT chk_fact_replenishment_quantity CHECK (replenishment_quantity > 0),
    CONSTRAINT chk_fact_replenishment_stock_before CHECK (stock_before >= 0),
    CONSTRAINT chk_fact_replenishment_stock_after CHECK (stock_after >= 0)
);
```

##### インデックス定義
```sql
-- 補充日時による時系列検索用
CREATE INDEX idx_fact_replenishment_datetime 
ON fact_replenishment(replenishment_datetime);

-- 自動販売機別補充履歴検索用
CREATE INDEX idx_fact_replenishment_vending_machine 
ON fact_replenishment(vending_machine_id);

-- 商品別補充履歴検索用
CREATE INDEX idx_fact_replenishment_product 
ON fact_replenishment(product_id);

-- 担当者別作業履歴検索用
CREATE INDEX idx_fact_replenishment_staff 
ON fact_replenishment(staff_id);

-- 日付×自動販売機の複合検索用
CREATE INDEX idx_fact_replenishment_date_vm 
ON fact_replenishment(replenishment_datetime, vending_machine_id);
```

## シーケンス定義

### サロゲートキー用シーケンス

#### DuckDB用シーケンス
```sql
-- 売上ID用シーケンス
CREATE SEQUENCE seq_sales_id START 1 INCREMENT 1;

-- 補充ID用シーケンス  
CREATE SEQUENCE seq_replenishment_id START 1 INCREMENT 1;
```

#### Snowflake用自動連番
```sql
-- テーブル定義内でIDENTITYを使用
sales_id BIGINT NOT NULL IDENTITY(1,1),
replenishment_id BIGINT NOT NULL IDENTITY(1,1),
```

## ビュー定義

### 売上サマリビュー
```sql
CREATE VIEW view_sales_summary AS
SELECT 
    vm.vending_machine_id,
    vm.location_name,
    p.product_name,
    pc.category_name,
    pm.payment_method_name,
    DATE(s.purchase_datetime) as purchase_date,
    COUNT(*) as sales_count,
    SUM(p.price) as total_sales_amount,
    SUM(s.input_amount) as total_input_amount,
    SUM(s.change_amount) as total_change_amount
FROM fact_sales s
INNER JOIN mst_vending_machine vm ON s.vending_machine_id = vm.vending_machine_id
INNER JOIN mst_product p ON s.product_id = p.product_id
INNER JOIN mst_product_category pc ON p.product_category_id = pc.product_category_id
INNER JOIN mst_payment_method pm ON s.payment_method_id = pm.payment_method_id
GROUP BY 
    vm.vending_machine_id, vm.location_name,
    p.product_name, pc.category_name, 
    pm.payment_method_name, DATE(s.purchase_datetime);
```

### 在庫状況ビュー
```sql
CREATE VIEW view_stock_status AS
WITH latest_replenishment AS (
    SELECT 
        vending_machine_id,
        product_id,
        stock_after,
        replenishment_datetime,
        ROW_NUMBER() OVER (
            PARTITION BY vending_machine_id, product_id 
            ORDER BY replenishment_datetime DESC
        ) as rn
    FROM fact_replenishment
    WHERE stock_after IS NOT NULL
)
SELECT 
    vm.vending_machine_id,
    vm.location_name,
    p.product_id,
    p.product_name,
    pc.category_name,
    COALESCE(lr.stock_after, 0) as current_stock,
    lr.replenishment_datetime as last_replenishment_datetime
FROM mst_vending_machine vm
CROSS JOIN mst_product p
INNER JOIN mst_product_category pc ON p.product_category_id = pc.product_category_id
LEFT JOIN latest_replenishment lr ON vm.vending_machine_id = lr.vending_machine_id 
    AND p.product_id = lr.product_id 
    AND lr.rn = 1;
```

## データ品質チェック用テーブル

### データ品質ログテーブル
```sql
CREATE TABLE log_data_quality (
    log_id BIGINT NOT NULL,
    table_name VARCHAR NOT NULL,
    column_name VARCHAR,
    error_type VARCHAR NOT NULL,
    error_level VARCHAR NOT NULL,
    error_message VARCHAR NOT NULL,
    source_data VARCHAR,
    record_count INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_log_data_quality PRIMARY KEY (log_id),
    CONSTRAINT chk_log_data_quality_error_level 
        CHECK (error_level IN ('FATAL', 'ERROR', 'WARNING', 'INFO'))
);
```

### データ品質メトリクステーブル
```sql
CREATE TABLE mst_data_quality_metrics (
    metric_id VARCHAR NOT NULL,
    table_name VARCHAR NOT NULL,
    metric_name VARCHAR NOT NULL,
    metric_description VARCHAR,
    threshold_value DECIMAL(10,4),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_mst_data_quality_metrics PRIMARY KEY (metric_id)
);
```

## 実行権限設定

### ロール定義
```sql
-- 読み取り専用ロール
CREATE ROLE role_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_readonly;

-- データ投入ロール
CREATE ROLE role_data_loader;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO role_data_loader;

-- 管理者ロール
CREATE ROLE role_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO role_admin;
```

---

**最終更新日**: 2024年8月24日  
**バージョン**: 1.0  
**承認者**: プロジェクトチーム  
**関連ドキュメント**: 
- [スキーマ設計ルール](./schema-design-rules.md)
- [基本設計書 - 生データスキーマ設計書](../basic-design/raw-data-schema.md)