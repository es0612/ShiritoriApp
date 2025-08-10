# しりとりアプリプロジェクト概要

## プロジェクト構造
- **メインアプリ**: `app/` ディレクトリ
- **コアライブラリ**: `app/Sources/ShiritoriCore/` - SwiftパッケージとしてShiritoriCoreライブラリを実装
- **テスト**: `app/Tests/ShiritoriCoreTests/` - Swift Testingを使用した包括的テスト

## アーキテクチャ
- **UI Framework**: SwiftUI + Swift 6の最新機能
- **状態管理**: @Observable マクロを活用
- **データ永続化**: SwiftData
- **テストフレームワーク**: Swift Testing (`import Testing`)
- **Clean Architecture**: プレゼンテーション、ビジネスロジック、インフラの分離

## 主要コンポーネント

### Models
- `Player.swift` - プレイヤー情報管理
- `Word.swift` - 単語管理
- `GameSession.swift` - ゲームセッション管理
- `AppSettings.swift` - アプリ設定

### Game Engine
- `GameState.swift` - ゲーム状態管理
- `ShiritoriRuleEngine.swift` - しりとりルール処理
- `GameSetupModels.swift` - ゲーム設定関連
- `GameResultsModels.swift` - 結果管理

### Services
- `SpeechRecognitionManager.swift` - 音声認識
- `WordDictionaryService.swift` - 辞書サービス
- `SoundManager.swift` - 音声・効果音
- `SettingsManager.swift` - 設定管理

### UI Components
- 再利用可能なコンポーネント群
- デザインシステム (`DesignSystem.swift`)
- アニメーション (`Animation/`)
- 設定画面 (`Settings/`)
- チュートリアル (`Tutorial/`)

### Utils
- `HiraganaConverter.swift` - ひらがな変換
- `ShiritoriWordNormalizer.swift` - 単語正規化
- `WordValidator.swift` - 単語検証

### Logging
- `AppLogger.swift` - 高度なロギングシステム（デバッグ、エラー追跡、パフォーマンス監視）

## 開発方針
- **TDD中心**: ユニットテストを軸とした高速開発サイクル
- **BDD補完**: 受け入れテストでユーザーシナリオ全体を保証
- **Clean Code**: 小さなコンポーネント、単一責任、依存性注入
- **細かなロギング**: バグ発見と問題特定を最優先とした詳細ログ

## 対象ユーザー
- 幼児から小学生低学年
- 1人〜5人でプレイ（人間+コンピュータ混在可能）
- 音声入力メインのUI/UX