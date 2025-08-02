# 開発用コマンド一覧

## テスト実行
```bash
# プロジェクトルートから（appディレクトリ内で実行）
cd app && swift test
```

## ビルド実行
```bash
# Xcode CLIでのビルド
xcodebuild build -project ShiritoriApp.xcodeproj -scheme ShiritoriApp

# Xcodeでプロジェクトを開く
open app/ShiritoriApp.xcodeproj
```

## Swift Package管理
```bash
# パッケージ依存関係の更新
cd app && swift package update

# パッケージ解決状況の確認
cd app && swift package show-dependencies
```

## プロジェクト情報確認
```bash
# Xcodeプロジェクト構成表示
xcodebuild -list

# ターゲット・スキーム一覧
xcodebuild -showBuildSettings
```

## ファイル検索・操作
```bash
# Swiftファイル検索
find . -name "*.swift" -not -path "./.build/*"

# プロジェクト構造表示
tree -I '.build|.git'

# Git操作
git status
git add .
git commit -m "メッセージ"
```

## Swiftフォーマット・リント
```bash
# ※ プロジェクトにはswift-formatやSwiftLintの設定は確認されていません
# 必要に応じて追加設定が必要
```