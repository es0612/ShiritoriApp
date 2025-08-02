# 技術スタック

## 開発環境
- **言語**: Swift
- **UIフレームワーク**: SwiftUI
- **最小対応OS**: iOS 17.0+, macOS 14.0+
- **IDE**: Xcode
- **システム**: Darwin (macOS)

## フレームワーク・ライブラリ
- **データ永続化**: SwiftData (`@Model`マクロ使用)
- **テストフレームワーク**: Swift Testing (`import Testing`)
- **UIテスト**: ViewInspector (0.10.2)
- **ロギング**: os.Logger + カスタムAppLoggerクラス
- **音声認識**: Speech framework
- **アーキテクチャ**: Clean Architecture準拠

## プロジェクト構造
```
ShiritoriApp/
├── app/
│   ├── Package.swift (SwiftPackage管理)
│   ├── ShiritoriApp/ (メインアプリケーション)
│   ├── Sources/ShiritoriCore/ (コアライブラリ)
│   └── Tests/ShiritoriCoreTests/ (テストコード)
├── CLAUDE.md (開発ガイドライン)
└── SPECIFICATIONS.md (仕様書)
```

## コアモジュール構成
- **Models**: Player, GameSession, Word, AppSettings, TutorialState
- **Game**: GameState, ShiritoriRuleEngine, GameSetupModels
- **UI**: SwiftUIビューコンポーネント群
- **Services**: WordDictionaryService, SettingsManager, SoundManager
- **Utils**: HiraganaConverter, WordValidator, ShiritoriWordNormalizer
- **Logging**: AppLogger (高度なロギング機構)