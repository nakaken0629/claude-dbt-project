# Claude DBT プロジェクト

データ変換と分析のためのdbt（data build tool）プロジェクトです。

## プロジェクト構造

- `my_claude_doc_investigation/` - メインのdbtプロジェクトディレクトリ
- `profiles.yml.template` - dbtプロファイル設定のテンプレート
- `main.py` - Pythonエントリーポイント
- `logs/` - ログファイルディレクトリ

## 開始方法

1. `profiles.yml.template`を`profiles.yml`にコピーし、データベース接続を設定
2. `uv`または`pip`を使用して依存関係をインストール
3. dbtコマンドを実行してデータモデルを構築

## 依存関係

Pythonの依存関係は`pyproject.toml`でuvにより管理されています。