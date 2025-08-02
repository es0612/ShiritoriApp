# コーディング規約・ガイドライン

## 開発手法
- **TDD (Test-Driven Development)**: Red-Green-Refactorサイクル
- **Swift Testing**を使用したユニットテスト駆動開発
- **BDD受け入れテスト**: 機能全体の振る舞い検証（CIまたは手動実行）

## アーキテクチャ原則
- **Clean Architecture準拠**
- **View責務分離**: ViewはPresentationLayerに位置、状態描画とイベント通知のみ
- **依存性注入**: ViewModelや状態は`@Environment`で注入
- **単一方向データフロー**: 状態変更を一方向に保つ

## SwiftUI開発ルール
- **小さなView**: 機能ごとにファイル分割、複雑なViewは小さなサブViewに分解
- **Observable活用**: `@Observable`マクロを使用した状態管理
- **Layout重視**: StackViewの組み合わせでレイアウト構築
- **Preview活用**: 様々な状態・デバイスサイズでの検証

## 命名規則
- **説明的な名前**: 役割が明確にわかる名前を使用 (`PlayerSelectionView`, `gameViewModel`)
- **Swiftベストプラクティス**: 最新のSwift機能を積極的に採用

## ロギング戦略
- **詳細ロギング**: バグ発見と問題特定のため細かいレベルでログ出力
- **レベル別**: debug, info, warning, error
- **出力形式**: `[レベル] [日時] [ファイル:行数] [関数名] - メッセージ`
- **本番対応**: 開発環境ではdebugまで、本番ではerror/warningのみ

## コメント方針
- **複雑なロジック**: 実装に至った「なぜ」を説明
- **ビジネスロジック**: しりとり判定、ゲーム進行の詳細説明