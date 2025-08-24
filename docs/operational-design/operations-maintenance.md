# 運用・メンテナンスガイド

## 日次運用

### 毎日の確認事項
- [ ] dbt実行ジョブの成功/失敗確認
- [ ] テスト実行結果の確認
- [ ] データ更新量の確認
- [ ] エラーログの監視
- [ ] パフォーマンス指標の確認

### 日次実行スクリプト
```bash
#!/bin/bash
# daily_run.sh

LOG_DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/daily_run_${LOG_DATE}.log"

echo "=== dbt Daily Run Started at $(date) ===" >> $LOG_FILE

# 1. 依存関係更新
echo "Updating dependencies..." >> $LOG_FILE
dbt deps --target prod >> $LOG_FILE 2>&1

# 2. シードデータ更新（必要時のみ）
echo "Loading seed data..." >> $LOG_FILE
dbt seed --target prod >> $LOG_FILE 2>&1

# 3. モデル実行
echo "Running models..." >> $LOG_FILE
dbt run --target prod >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Models executed successfully" >> $LOG_FILE
else
    echo "❌ Model execution failed" >> $LOG_FILE
    # アラート送信
    echo "dbt run failed on $(date)" | mail -s "dbt Alert" admin@company.com
    exit 1
fi

# 4. テスト実行
echo "Running tests..." >> $LOG_FILE
dbt test --target prod >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "✅ All tests passed" >> $LOG_FILE
else
    echo "❌ Some tests failed" >> $LOG_FILE
    # テスト失敗の詳細をメール送信
    dbt test --target prod --store-failures 2>&1 | mail -s "dbt Test Failures" admin@company.com
fi

# 5. ドキュメント生成
echo "Generating documentation..." >> $LOG_FILE
dbt docs generate --target prod >> $LOG_FILE 2>&1

echo "=== dbt Daily Run Completed at $(date) ===" >> $LOG_FILE
```

## 週次・月次メンテナンス

### 週次タスク
- [ ] データ品質レポート作成
- [ ] パフォーマンスメトリクス分析
- [ ] ディスク使用量確認
- [ ] バックアップファイル整理
- [ ] 依存関係パッケージ更新確認

### 月次タスク
- [ ] データリネージ図更新
- [ ] ドキュメント全体レビュー
- [ ] セキュリティ設定確認
- [ ] 容量計画見直し
- [ ] ベストプラクティス適用状況確認

## 監視とアラート

### 監視対象メトリクス

#### 実行メトリクス
```sql
-- 実行時間監視クエリ
select 
    model_name,
    target_name,
    status,
    total_time,
    run_started_at,
    run_completed_at
from dbt_run_results
where run_started_at >= current_date - interval '7 days'
order by total_time desc
```

#### データ品質メトリクス
```sql
-- テスト失敗率監視
select 
    date_trunc('day', run_started_at) as run_date,
    count(*) as total_tests,
    count(case when status = 'pass' then 1 end) as passed_tests,
    count(case when status = 'fail' then 1 end) as failed_tests,
    round(
        count(case when status = 'fail' then 1 end)::float / 
        count(*)::float * 100, 2
    ) as failure_rate_pct
from dbt_test_results
where run_started_at >= current_date - interval '30 days'
group by date_trunc('day', run_started_at)
order by run_date desc
```

### アラート設定

#### 重要度レベル
- **Critical**: dbt実行失敗、データ破損
- **Warning**: テスト失敗、パフォーマンス低下
- **Info**: 完了通知、統計情報

#### 通知チャネル
- **メール**: 管理者向け詳細レポート
- **Slack**: チーム向けリアルタイム通知
- **ログ**: トレーサビリティ用詳細記録

## トラブルシューティング

### よくある問題と解決方法

#### dbt実行失敗
```bash
# エラー詳細確認
dbt run --debug

# 特定モデルのみ実行
dbt run --select model_name

# 依存関係確認
dbt deps --upgrade
```

#### メモリ不足エラー
```yaml
# dbt_project.yml
models:
  my_claude_doc_investigation:
    +pre-hook: "set work_mem = '512MB'"
    large_models:
      +materialized: table
      +post-hook: "analyze {{ this }}"
```

#### DuckDBロックエラー
```bash
# DuckDBファイルロック解除
lsof data/dbt_dev.duckdb
kill -9 <PID>

# または新しいファイルで再実行
rm data/dbt_dev.duckdb
dbt run
```

### ログ分析

#### 実行ログの確認
```bash
# 最新のログファイル確認
tail -f logs/dbt.log

# エラーのみ抽出
grep -i error logs/dbt.log

# 実行時間の長いモデル特定
grep "completed after" logs/dbt.log | sort -k5 -nr
```

## データバックアップ戦略

### バックアップ対象
1. **DuckDBファイル**: `data/*.duckdb`
2. **ソースデータ**: `sources/*.csv`
3. **設定ファイル**: `profiles.yml`, `dbt_project.yml`
4. **カスタムマクロ**: `macros/*.sql`

### バックアップスクリプト
```bash
#!/bin/bash
# backup.sh

BACKUP_DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/dbt_project_${BACKUP_DATE}"

mkdir -p $BACKUP_DIR

# DuckDBファイルバックアップ
cp -r data/ $BACKUP_DIR/
echo "DuckDB files backed up"

# ソースデータバックアップ
cp -r sources/ $BACKUP_DIR/
echo "Source data backed up"

# 設定ファイルバックアップ
cp profiles.yml dbt_project.yml $BACKUP_DIR/
cp -r my_claude_doc_investigation/ $BACKUP_DIR/
echo "Configuration backed up"

# 古いバックアップ削除（30日以上）
find /backup -name "dbt_project_*" -mtime +30 -exec rm -rf {} \;
echo "Old backups cleaned up"

# バックアップサイズ確認
du -sh $BACKUP_DIR
```

## パフォーマンス最適化

### 定期最適化タスク

#### DuckDB最適化
```sql
-- データベース最適化
VACUUM;
ANALYZE;

-- インデックス再構築
REINDEX;
```

#### モデル最適化レビュー
```sql
-- 実行時間の長いモデル特定
select 
    name,
    materialization,
    execution_time_seconds,
    rows_affected
from dbt_run_results
where execution_time_seconds > 60
order by execution_time_seconds desc
limit 10;
```

### 容量管理
```bash
# ディスク使用量監視
df -h data/
du -sh data/*.duckdb

# 不要ファイル削除
dbt clean

# ログローテーション
logrotate /etc/logrotate.d/dbt
```

## セキュリティメンテナンス

### 定期セキュリティチェック
- [ ] 依存関係パッケージの脆弱性スキャン
- [ ] アクセス権限レビュー
- [ ] 機密データアクセス監査
- [ ] ログファイルの機密情報チェック

### セキュリティ更新
```bash
# パッケージセキュリティ更新
pip audit
uv audit

# 依存関係更新
dbt deps --upgrade
```

## ドキュメント管理

### ドキュメント更新プロセス
1. **変更時**: モデル変更時にschema.yml更新
2. **週次**: 全体的な文書レビュー
3. **リリース時**: バージョン管理とタグ付け

### 自動ドキュメント生成
```bash
#!/bin/bash
# generate_docs.sh

# ドキュメント生成
dbt docs generate --target prod

# 静的サイト更新
cp -r target/. /var/www/dbt-docs/

# 通知
echo "Documentation updated at $(date)" | \
mail -s "dbt Docs Updated" team@company.com
```

## 災害復旧計画

### 復旧手順
1. **バックアップからの復元**: データとメタデータの復元
2. **設定ファイル復元**: プロファイルとプロジェクト設定
3. **依存関係復元**: `dbt deps`で外部パッケージ復元
4. **データ整合性チェック**: `dbt test`で全テスト実行
5. **本番切り替え**: 段階的な本番復旧

### 復旧時間目標（RTO）
- **軽微な障害**: 1時間以内
- **データベース障害**: 4時間以内
- **完全システム障害**: 24時間以内

### 連絡体制
```yaml
emergency_contacts:
  primary: "admin@company.com"
  secondary: "backup-admin@company.com"
  escalation: "manager@company.com"

notification_channels:
  - email
  - slack: "#data-alerts"
  - phone: "+81-xx-xxxx-xxxx"
```