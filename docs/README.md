# ドキュメント一覧

このディレクトリには、my_claude_doc_investigationプロジェクトの包括的なドキュメントが含まれています。

## 📖 ドキュメント構成

### 🎯 基本設計 (`basic-design/`)
プロジェクトの要件定義と全体アーキテクチャレベルの設計文書

- **[プロジェクト概要](./basic-design/project-overview.md)**
  - プロジェクトの目的と背景
  - 技術スタックと構成
  - データソースの説明
  - 開発フローと品質保証

- **[データモデリング設計](./basic-design/data-modeling-design.md)**
  - レイヤードアーキテクチャ設計
  - データソース分析と品質課題
  - 提案データモデル構造
  - パフォーマンス考慮事項

- **[生データスキーマ設計書](./basic-design/raw-data-schema.md)**
  - 自動販売機事業の全データソース定義
  - マスタデータとトランザクションデータの詳細スキーマ
  - mermaid形式のER図による関係性明示
  - データ品質考慮事項

### 🔧 詳細設計 (`detailed-design/`)
実装方針と開発手法レベルの設計文書

- **[dbtベストプラクティス](./detailed-design/dbt-best-practices.md)**
  - プロジェクト構造とファイル組織
  - SQLスタイルガイド
  - モデル設計原則
  - マクロの活用方法

- **[テスト戦略](./detailed-design/testing-strategy.md)**
  - 包括的なテストレベル定義
  - dbt標準テストとカスタムテスト
  - テスト実行戦略
  - パフォーマンステストとモニタリング

### ⚙️ 運用設計 (`operational-design/`)
環境構築と保守運用レベルの設計文書

- **[運用・メンテナンス](./operational-design/operations-maintenance.md)**
  - 日次・週次・月次の運用手順
  - 監視とアラート設定
  - トラブルシューティングガイド
  - バックアップと災害復旧計画

## 📚 ドキュメント利用ガイド

### 🔰 初回プロジェクト理解時
1. [プロジェクト概要](./basic-design/project-overview.md)
2. [生データスキーマ設計書](./basic-design/raw-data-schema.md)
3. [データモデリング設計](./basic-design/data-modeling-design.md)

### 📝 開発・実装時
1. [dbtベストプラクティス](./detailed-design/dbt-best-practices.md)
2. [テスト戦略](./detailed-design/testing-strategy.md)
3. [データモデリング設計](./basic-design/data-modeling-design.md)

### 🔧 運用・保守時
1. [運用・メンテナンス](./operational-design/operations-maintenance.md)
2. [テスト戦略](./detailed-design/testing-strategy.md)

## 🔄 ドキュメント更新方針

### 更新タイミング
- **即座に更新**: 設定変更、新機能追加時
- **週次レビュー**: 内容の正確性確認
- **月次更新**: 全体的な見直しと改善

### 品質基準
- **正確性**: 最新の実装状況を反映
- **完全性**: 必要な情報の網羅
- **明確性**: 理解しやすい説明
- **一貫性**: 用語とフォーマットの統一

## 🤝 貢献方法

### ドキュメント改善
1. 不正確な情報の発見・報告
2. 不足している情報の追加
3. 理解しにくい箇所の改善提案
4. 新しいベストプラクティスの共有

### レビュープロセス
1. 変更内容のプルリクエスト作成
2. チームメンバーによるレビュー
3. 承認後のマージとデプロイ

## 📞 サポート

ドキュメントに関する質問や改善提案は、以下の方法でお問い合わせください：

- **Issues**: GitHubリポジトリのIssue機能
- **Discord/Slack**: チームチャット
- **メール**: プロジェクト管理者まで

---

*このドキュメントは継続的に更新・改善されています。最新版は常にGitリポジトリで確認してください。*