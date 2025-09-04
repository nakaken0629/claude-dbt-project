# スキーマ設計ルール（詳細設計）

## 概要

本ドキュメントは、my_claude_doc_investigationプロジェクトで使用する物理データベーススキーマの設計ルールを定義します。命名規則、データ型マッピング、制約設計、品質管理など、スキーマ設計に関わる全ての標準化された規則を記載しています。

## 命名規則

### テーブル名命名規則

#### 基本ルール
- **形式**: `{type}_{entity}` 形式
- **文字種**: 英小文字のみ
- **区切り文字**: アンダースコア（_）を使用
- **長さ制限**: 最大63文字（PostgreSQL/DuckDB準拠）

#### 接頭辞規則
| データ種別 | 接頭辞 | 例 |
|-----------|-------|-----|
| マスタデータ | `mst_` | `mst_vending_machine` |
| トランザクションデータ | `fact_` | `fact_sales` |
| ディメンションテーブル | `dim_` | `dim_date` |
| 集計テーブル | `agg_` | `agg_daily_sales` |
| ワークテーブル | `wrk_` | `wrk_temp_data` |
| ログテーブル | `log_` | `log_data_quality` |

### カラム名命名規則

#### 基本ルール
- **形式**: スネークケース
- **文字種**: 英小文字のみ
- **区切り文字**: アンダースコア（_）を使用
- **長さ制限**: 最大63文字

#### 特殊カラム命名規則
| カラム種別 | 命名形式 | 例 |
|-----------|---------|-----|
| 主キー（ID列） | `{entity}_id` | `product_id`, `vending_machine_id` |
| 外部キー | `{referenced_entity}_id` | `product_category_id` |
| 日付列 | `{action}_date` | `installation_date`, `purchase_date` |
| 日時列 | `{action}_datetime` | `purchase_datetime`, `replenishment_datetime` |
| フラグ列 | `is_{condition}` | `is_active`, `is_deleted` |
| 数量・個数列 | `{item}_quantity` または `{item}_count` | `replenishment_quantity`, `stock_count` |
| 金額列 | `{item}_amount` | `input_amount`, `change_amount` |
| システム列 | 固定名 | `created_at`, `updated_at`, `version` |

#### 禁止事項
- SQL予約語の使用禁止
- 数字から始まるカラム名禁止
- 特殊文字（-、スペースなど）の使用禁止
- 大文字の使用禁止

## データ型マッピング規則

### DuckDBとSnowflake共通対応データ型

| 論理データ型 | DuckDB型 | Snowflake型 | 推奨用途 | 制約 |
|------------|----------|------------|---------|------|
| 短い文字列 | VARCHAR | VARCHAR | ID、名前、区分値 | 最大16MB |
| 長い文字列 | TEXT | VARCHAR | 説明文、備考 | 最大16MB |
| 小整数 | INTEGER | INTEGER | 個数、順序 | -2^31 ～ 2^31-1 |
| 大整数 | BIGINT | BIGINT | サロゲートキー | -2^63 ～ 2^63-1 |
| 金額 | DECIMAL(p,s) | NUMBER(p,s) | 通貨、金額 | 精度指定必須 |
| 日付 | DATE | DATE | 年月日のみ | YYYY-MM-DD |
| 日時 | TIMESTAMP | TIMESTAMP_NTZ | 日時情報 | タイムゾーンなし推奨 |
| 真偽値 | BOOLEAN | BOOLEAN | フラグ | TRUE/FALSE/NULL |

### データ型選択ガイドライン

#### 文字列型選択基準
| 最大長 | 推奨データ型 | 用途例 |
|-------|------------|--------|
| ～50文字 | VARCHAR | ID、コード、区分値 |
| 51～255文字 | VARCHAR | 名前、住所 |
| 256文字～ | TEXT | 説明文、コメント |

#### 数値型選択基準
| 値の範囲 | 推奨データ型 | 用途例 |
|---------|------------|--------|
| 0～999 | INTEGER | 個数、順序 |
| 1000～99,999,999 | INTEGER | 金額（円） |
| 100,000,000以上 | BIGINT | サロゲートキー、大金額 |

#### 金額型精度設定
| 通貨単位 | DECIMAL精度 | 例 |
|---------|------------|-----|
| 円（整数） | DECIMAL(10,0) | 価格、売上 |
| 円（小数） | DECIMAL(12,2) | 税額、割引額 |
| 外貨 | DECIMAL(15,4) | 為替レート考慮 |

## 制約設計規則

### 主キー制約

#### 設計原則
- すべてのテーブルに主キーを定義
- 単一列の主キーを推奨
- サロゲートキーの積極活用

#### サロゲートキー命名規則
- マスタテーブル: `{entity}_id`
- ファクトテーブル: `{entity}_id`
- 例: `product_id`, `sales_id`

### 外部キー制約

#### 参照整合性制約
```sql
-- 標準的な外部キー制約定義
CONSTRAINT fk_{table}_{column} 
FOREIGN KEY ({column_name}) 
REFERENCES {referenced_table}({referenced_column})
```

#### 削除時動作規則
| 参照関係 | ON DELETE | 理由 |
|---------|-----------|------|
| マスタ → ファクト | RESTRICT | データの整合性保持 |
| 親 → 子 | CASCADE | データの一貫性確保 |
| 履歴関係 | RESTRICT | 履歴データ保護 |

### チェック制約

#### 数値チェック制約
```sql
-- 非負値制約
CHECK ({column_name} >= 0)

-- 正値制約  
CHECK ({column_name} > 0)

-- 範囲制約
CHECK ({column_name} BETWEEN {min_value} AND {max_value})
```

#### 文字列チェック制約
```sql
-- 長さ制限
CHECK (LENGTH({column_name}) <= {max_length})

-- 形式チェック（正規表現）
CHECK ({column_name} ~ '^[A-Z]{3}[0-9]{3}$')  -- DuckDBの場合
```

### NOT NULL制約

#### NOT NULL適用基準
| カラム種別 | NOT NULL | 理由 |
|-----------|----------|------|
| 主キー | 必須 | 一意性保証のため |
| 外部キー | 原則必須 | 参照整合性のため |
| ビジネスキー | 必須 | 業務上必須項目 |
| システム列 | 必須 | システム制御のため |
| 任意項目 | 不要 | 業務仕様による |

## インデックス設計規則

### インデックス命名規則

#### 命名形式
```
idx_{table_name}_{column_name}[_{column_name}...]
```

#### インデックス種別接頭辞
| インデックス種別 | 接頭辞 | 例 |
|----------------|--------|-----|
| 単一列インデックス | `idx_` | `idx_sales_purchase_date` |
| 複合インデックス | `idx_` | `idx_sales_vm_product` |
| 一意インデックス | `uidx_` | `uidx_product_code` |
| 部分インデックス | `pidx_` | `pidx_sales_active` |

### インデックス設計基準

#### 必須インデックス
1. **主キー**: 自動作成されるため明示不要
2. **外部キー**: 参照整合性制約確認用
3. **検索頻度高**: SELECT文のWHERE句で頻繁に使用

#### 複合インデックス設計
- 選択性の高い列を先頭に配置
- WHERE句の条件順序を考慮
- 最大5列程度に制限

#### パフォーマンス考慮事項
- インデックス数は最小限に抑制
- INSERT/UPDATE性能への影響を考慮
- 定期的なインデックス使用状況監視

## データ品質管理規則

### データバリデーション階層

#### 1. スキーマレベル制約
- データ型制約
- NOT NULL制約
- CHECK制約
- 外部キー制約

#### 2. ビジネスルール制約
- 複数列間の整合性チェック
- 日時の論理的順序性
- 金額計算の正確性

#### 3. データ品質チェック
- 統計的異常値検出
- 重複データ検出
- データ形式統一性チェック

### エラーハンドリング規則

#### エラー分類
| エラーレベル | 処理方針 | 例 |
|------------|---------|-----|
| FATAL | 処理中断 | データ型不一致、主キー重複 |
| ERROR | レコード除外 | 外部キー制約違反 |
| WARNING | ログ記録 | ビジネスルール違反 |
| INFO | 監視 | データ形式の軽微な不備 |

#### エラーログ標準フォーマット
```json
{
  "timestamp": "2024-08-24T10:30:00Z",
  "table_name": "fact_sales",
  "error_level": "ERROR",
  "error_code": "FK_VIOLATION",
  "error_message": "参照先マスタに存在しないキー値",
  "source_data": "VM999",
  "affected_columns": ["vending_machine_id"]
}
```

## バージョン管理規則

### スキーマバージョン管理

#### バージョン番号体系
```
{major}.{minor}.{patch}
例: 1.2.3
```

#### バージョンアップ基準
| 変更種別 | バージョン | 例 |
|---------|-----------|-----|
| 破壊的変更 | Major | テーブル削除、カラム削除 |
| 機能追加 | Minor | テーブル追加、カラム追加 |
| バグ修正 | Patch | 制約修正、インデックス追加 |

### 変更管理プロセス

#### DDL変更フロー
1. 設計書更新
2. レビュー・承認
3. ステージング環境適用
4. テスト実行
5. 本番環境適用

#### ロールバック計画
- すべてのDDL変更にロールバックスクリプト作成
- データ移行を伴う場合はバックアップ取得必須

## 実装環境別考慮事項

### DuckDB固有事項
- シーケンス生成: `nextval('sequence_name')`
- 正規表現演算子: `~` 使用可能
- 配列型、構造体型サポート

### Snowflake固有事項
- 自動連番: `IDENTITY` 使用
- 関数呼び出し: 括弧必須（例: `CURRENT_TIMESTAMP()`）
- セミ構造化データ型（VARIANT、ARRAY、OBJECT）

### 共通実装ガイドライン
- ANSI SQL標準に準拠
- データベース固有機能の使用は最小限に
- 移植性を重視した設計

---

**最終更新日**: 2024年8月24日  
**バージョン**: 1.0  
**承認者**: プロジェクトチーム  
**関連ドキュメント**: 
- [物理スキーマ定義書](./physical-schema-definition.md)
- [基本設計書 - 生データスキーマ設計書](../basic-design/raw-data-schema.md)