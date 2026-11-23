# 音声しりとり v1（M0 土台 + M1 話す往復）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 旧コードをしまって新しい土台を作り、子供がアプリと声でしりとりを往復できる最小のアプリを TestFlight に届ける。

**Architecture:** Swift パッケージ `ShiritoriCore`（`app/` 直下）に、純粋なルール（`Rules`）・辞書（`WordBank`）・1回のあそびの状態（`Session`）・聞く話す（`Speech`）・画面（`Play`）を機能別フォルダで置く。画面の状態は `PlayViewModel` が持つ列挙型1つ。聞く・話すはプロトコル越しに呼び、テストでは即座に返る偽物を使う。

**Tech Stack:** Swift 6 言語モード / SwiftUI / `@Observable` / Swift Testing（ツールチェーン同梱）/ Speech（`SFSpeechRecognizer` 端末内認識）/ AVFoundation（`AVSpeechSynthesizer`）/ `os.Logger`。外部パッケージなし。

**Spec:** `docs/superpowers/specs/2026-11-23-shiritori-v1-redesign-design.md`（実行者はこの計画と併せて読む。台詞・判定順・つなぎ方の正本は spec の §5）

## Global Constraints

- 対応 OS: iOS 18.0 以上。パッケージの `platforms` は `.iOS(.v18), .macOS(.v15)`（macOS は `swift test` を速く回すためだけに入れる）。
- Swift 6 言語モード。ViewModel と画面は `@MainActor`。
- 外部パッケージを足さない。`ViewInspector` と `swift-testing` パッケージは外す。
- ViewModel で `DispatchQueue.asyncAfter` と `Timer` を使わない。待つ処理はプロトコル越し。
- 画面に出す文字と台詞はすべてひらがな（数字と記号は可）。
- 音声認識は `requiresOnDeviceRecognition = true`。ネットワーク通信をしない。
- 辞書に「ん」で終わる語、1文字の語、子供向けでない語（例: びーる）を入れない。
- 回数は「子供が正しく言えた回数」。言い直しで減らさない。
- ログは `os.Logger`。状態遷移・判定・聞き取りの開始と結果・エラーだけ。
- すべての操作できる UI 部品に `accessibilityLabel` を付ける。
- テストの実行: `cd app && swift test`。アプリのビルド確認: `cd app && xcodebuild build -project ShiritoriApp.xcodeproj -scheme ShiritoriApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`。
- コミットはパスを指定して stage する（`git add -A` を使わない）。push と PR のマージは Task 1・Task 11 の指定箇所だけ。
- spec からの変更1点: iPad は全方向に対応する（iPhone は縦のみ）。iPad の縦固定には全画面指定が要り、App Store の要件に触れるため。Task 1 で spec §3 の1行を直す。

## Review Focus

spec が明示していないが、使う人が踏みそうな場面。各行のテストは、右に書いたタスクに入れてある。

1. **マイクか音声認識の許可を拒否した／端末内認識に非対応の端末** → 落ちずに「あそべない」画面を出す。あそぶ画面には進まない。（Task 9: `start_whenDenied_showsUnavailable` / `start_whenUnsupported_showsUnavailable`）
2. **無音・雑音で認識候補が空** → 「もういちど いってね」。回数は変えず、聞き取れずの数を1増やし、子供を待つ状態に戻る。（Task 9: `mic_whenNothingHeard_asksAgain`）
3. **聞き取り中に失敗する（電話の割り込み、音声エンジンの起動失敗）** → 2 と同じ扱いで待つ状態に戻る。聞いている状態のまま固まらない。（Task 9: `mic_whenListenThrows_returnsToWaiting`）
4. **マイクボタンの連打、アプリが話している最中の操作** → 子供を待つ状態以外では何もしない。聞き取りが二重に始まらない。（Task 9: `mic_whenNotWaiting_isIgnored`）
5. **辞書を使い切った** → 「まいった」でも出す言葉が無いときは、「ことばが なくなっちゃった！」と言っておわりの表示へ進む。落ちない・無限に待たない。（Task 6: `appTurn_whenBankExhausted_returnsOutOfWords` / Task 9: `appTurn_whenOutOfWords_finishes`）

---

## File Structure

```
app/
  Package.swift                         （書き直し）
  Sources/ShiritoriCore/
    Logging/AppLog.swift                os.Logger の包み
    Rules/Kana.swift                    かなの正規化
    Rules/ShiritoriRules.swift          つなぎ方と判定
    WordBank/Word.swift                 辞書の1語
    WordBank/WordBank.swift             読み込みと言葉選び
    WordBank/Resources/words.json       辞書
    Session/ShiritoriSession.swift      1回のあそびの状態
    Speech/ReadingExtractor.swift       認識結果 → 読み
    Speech/SpeechProtocols.swift        聞く・話すのプロトコル
    Speech/EndOfSpeechDetector.swift    話し終わりの判定（純粋）
    Speech/OnDeviceSpeechListener.swift SFSpeechRecognizer 実装
    Speech/SystemSpeaker.swift          AVSpeechSynthesizer 実装
    Play/Phrases.swift                  台詞
    Play/PlayViewModel.swift            画面の状態
    Play/TitleView.swift / PlayView.swift / FinishOverlay.swift / UnavailableView.swift / RootView.swift
  Tests/ShiritoriCoreTests/             上と同じ名前 + Tests.swift
  ShiritoriApp/ShiritoriAppApp.swift    起動だけ（書き直し）
docs/archive/2025/                      旧資料
```

---

## M0 土台

### Task 1: 旧コードをしまい、新しい骨組みにする

**Files:**
- Delete: `app/Sources/ShiritoriCore/` 配下すべて、`app/Tests/ShiritoriCoreTests/` 配下すべて、`app/ShiritoriApp/{GameSetupView,MainAppView,PlayerManagementView,TitleView}.swift`、`app/Package.resolved`
- Move → `docs/archive/2025/`: `SPECIFICATIONS.md`, `RELEASE_CHECKLIST.md`, `STITCH_PROMPT.md`, `GEMINI.md`, `icon-creator.html`, `image.png`
- Create: `docs/archive/2025/README.md`, `app/Sources/ShiritoriCore/Logging/AppLog.swift`, `app/Sources/ShiritoriCore/Play/RootView.swift`, `app/Tests/ShiritoriCoreTests/SmokeTests.swift`
- Modify: `app/Package.swift`, `app/ShiritoriApp/ShiritoriAppApp.swift`, `app/ShiritoriApp.xcodeproj/project.pbxproj`, `CLAUDE.md`, `README.md`, spec §3

**Interfaces:**
- Produces: `public enum AppLog { public static let rules, session, speech, play: Logger }`（subsystem は `com.asapapalab.ShiritoriApp`）。`public struct RootView: View { public init() }`（この時点ではアプリ名のテキストだけ）。

- [ ] **Step 1: タグを打つ** — `git tag legacy-2025 origin/main && git push origin legacy-2025`。`git ls-remote --tags origin legacy-2025` に1行出ることを確かめる。
- [ ] **Step 2: 旧資料を移す** — `git mv` で6点を `docs/archive/2025/` へ。`README.md` に「2025年版の資料。現行の仕様は `docs/superpowers/specs/` を見る。旧コードは `legacy-2025` タグにある」と書く。
- [ ] **Step 3: 失敗するテストを書く** — `SmokeTests.swift`:
  ```swift
  import Testing
  @testable import ShiritoriCore
  @Test func packageBuildsAndLogsExist() { _ = AppLog.rules; _ = AppLog.session; _ = AppLog.speech; _ = AppLog.play }
  ```
- [ ] **Step 4: 旧ソース・旧テストを消し、`Package.swift` を書き直す** — `// swift-tools-version: 6.0`、`platforms: [.iOS(.v18), .macOS(.v15)]`、依存なし、target `ShiritoriCore`（`path: "Sources/ShiritoriCore"`, `resources: [.process("WordBank/Resources")]` は Task 5 で足す）、testTarget `ShiritoriCoreTests`。
- [ ] **Step 5: `swift test` が失敗することを確かめる** — Expected: `cannot find 'AppLog'`。
- [ ] **Step 6: `AppLog` と `RootView` を実装し、`ShiritoriAppApp.swift` を `WindowGroup { RootView() }` だけにする**（SwiftData の記述は消す）。
- [ ] **Step 7: `project.pbxproj` を直す** — (a) `ViewInspector` の `XCRemoteSwiftPackageReference` と、それを指す `packageReferences` の行・`XCSwiftPackageProductDependency`・テストターゲットの `packageProductDependencies` の行を消す。(b) 全ターゲットの `SWIFT_VERSION = 5.0` → `6.0`。(c) `IPHONEOS_DEPLOYMENT_TARGET = 18.5` → `18.0`。(d) `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` を `UIInterfaceOrientationPortrait` だけにする。`ShiritoriApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` と `ShiritoriApp.xcworkspace/xcshareddata/swiftpm/Package.resolved` は消す。
- [ ] **Step 8: 確かめる** — `swift test` → `1 test passed`。Global Constraints のビルドコマンド → `** BUILD SUCCEEDED **`。`xcodebuild archive ... -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO` → `** ARCHIVE SUCCEEDED **`。ビルドログの warning に `SFSpeech` が含まれないことを見る（spec §12 の確認。この時点では Speech を使っていないので、Task 8 でもう一度見る）。
- [ ] **Step 9: `CLAUDE.md` を spec に合わせる** — §3.2.1 の「Interactor」「AppState」の記述を「View ↔ `@Observable` ViewModel ↔ 純粋な型とプロトコル」に直す。§4 を「`os.Logger` で、状態遷移・判定・聞き取りの開始と結果・エラーを記録する。全タップ・アニメーション・レイアウトは記録しない」に置き換える。§5 を「v1 は `UserDefaults`。SwiftData は履歴を持つ段階で入れる」に直す。冒頭に spec へのリンクを足す。`README.md` に概要3行と spec・計画へのリンクを書く。spec §3 の「iPhone と iPad、縦向きのみ」を「iPhone は縦向きのみ。iPad は全方向」に直す。
- [ ] **Step 10: コミット → PR → マージ → クラウドのビルド確認** — ブランチ `feat/m0-foundation`。マージはオーナーの承認を得てから行い、`gh pr view <N> --json state,mergedAt` で `MERGED` を確かめる。PR 本文に issue #6 への `Refs #6` を書く。マージ後、ASC の Xcode Cloud で main のビルドが成功したことを Chrome で読み、成功したら issue #6 に経緯（旧版は `legacy-2025`、再設計は spec）をコメントして閉じる。このとき、ビルドが内部テスターのグループ `shinya` に割り当たっているかも読む（spec §12。割り当たっていなければ Task 11 で扱う）。

---

## M1 話す往復

### Task 2: かなの正規化（`Rules/Kana.swift`）

**Interfaces:**
- Produces:
  ```swift
  public enum Kana {
      /// 空白・句読点・記号を除き、カタカナをひらがなにする。長音「ー」は残す
      public static func normalize(_ text: String) -> String
      /// ひらがなと「ー」だけでできていて、空でないか
      public static func isHiraganaWord(_ text: String) -> Bool
      /// ゃゅょっぁぃぅぇぉ → やゆよつあいうえお。それ以外はそのまま
      public static func large(_ character: Character) -> Character
      public static func isSmall(_ character: Character) -> Bool
      /// その文字の段の母音（か→あ、ぎ→い、しゅ の ゅ→う）。ん・ー・かな以外は nil
      public static func vowel(of character: Character) -> Character?
  }
  ```

- [ ] **Step 1: テストを書く**（`KanaTests.swift`）
  ```swift
  @Test func normalize_convertsKatakanaAndStripsPunctuation() {
      #expect(Kana.normalize("ケーキ") == "けーき")
      #expect(Kana.normalize("りんご。") == "りんご")
      #expect(Kana.normalize(" ゴ リ ラ ") == "ごりら")
  }
  @Test func isHiraganaWord() {
      #expect(Kana.isHiraganaWord("けーき"))
      #expect(!Kana.isHiraganaWord("")); #expect(!Kana.isHiraganaWord("りんご1")); #expect(!Kana.isHiraganaWord("林檎"))
  }
  @Test func largeAndVowel() {
      #expect(Kana.large("ゃ") == "や"); #expect(Kana.large("っ") == "つ"); #expect(Kana.large("か") == "か")
      #expect(Kana.vowel(of: "か") == "あ"); #expect(Kana.vowel(of: "ぎ") == "い"); #expect(Kana.vowel(of: "ゅ") == "う")
      #expect(Kana.vowel(of: "ぽ") == "お"); #expect(Kana.vowel(of: "ん") == nil); #expect(Kana.vowel(of: "ー") == nil)
  }
  ```
- [ ] **Step 2: `swift test --filter KanaTests` が失敗することを確かめる**
- [ ] **Step 3: 実装する** — カタカナ → ひらがなは文字コードを 0x60 引く（0x30A1...0x30F6）。OS の `applyingTransform` は「ー」を母音に変えるので使わない。
- [ ] **Step 4: テストが通ることを確かめる**
- [ ] **Step 5: コミット**

### Task 3: つなぎ方（`Rules/ShiritoriRules.swift` 前半）

**Interfaces:**
- Consumes: `Kana`
- Produces:
  ```swift
  public enum ShiritoriRules {
      /// その言葉のあとに使える「最初の文字」。先頭がアプリの返事に使う候補。決められないときは空
      public static func nextHeads(after reading: String) -> [String]
      public static func starts(_ reading: String, withAnyOf heads: [String]) -> Bool
      public static func endsWithN(_ reading: String) -> Bool
  }
  ```

- [ ] **Step 1: テストを書く**（`ShiritoriRulesConnectionTests.swift`。値は spec §5.4）
  ```swift
  @Test(arguments: [
      ("りんご", ["ご"]), ("ぜりー", ["り", "い"]), ("でんしゃ", ["や", "しゃ"]),
      ("こーひー", ["ひ", "い"]), ("しちゅー", ["ゆ", "ちゅ", "う"]),
      ("はなぢ", ["ぢ", "じ"]), ("かんづ", ["づ", "ず"]), ("を", ["を", "お"]),
      ("ぶた", ["た"]), ("め", ["め"]), ("ー", []), ("", []),
  ])
  func nextHeads(reading: String, expected: [String]) { #expect(ShiritoriRules.nextHeads(after: reading) == expected) }

  @Test func starts() {
      #expect(ShiritoriRules.starts("ごりら", withAnyOf: ["ご"]))
      #expect(ShiritoriRules.starts("しゃしん", withAnyOf: ["や", "しゃ"]))
      #expect(ShiritoriRules.starts("やま", withAnyOf: ["や", "しゃ"]))
      #expect(!ShiritoriRules.starts("だんご", withAnyOf: ["た"]))   // 濁点は区別
      #expect(!ShiritoriRules.starts("ごりら", withAnyOf: []))
  }
  @Test func endsWithN() { #expect(ShiritoriRules.endsWithN("きりん")); #expect(!ShiritoriRules.endsWithN("りんご")); #expect(!ShiritoriRules.endsWithN("")) }
  ```
  末尾が「っ」の場合（`["つ"]`）の1ケースも足す。
- [ ] **Step 2: 失敗を確かめる**
- [ ] **Step 3: 実装する** — 手順: 末尾の「ー」をすべて外す（外したかを覚える）→ 残りの最後の文字 `c` を見る → `c` が小さい文字なら `[large(c)]` に、ゃゅょ のときは直前の文字 + `c`（拗音）を足す。そうでなければ `[c]`、`c` が ぢ・づ・を なら じ・ず・お を足す → 「ー」を外していたら `vowel(of: c)` を末尾に足す → 重複を除く。
- [ ] **Step 4: 通ることを確かめる** / **Step 5: コミット**

### Task 4: 判定（`Rules/ShiritoriRules.swift` 後半）

**Interfaces:**
- Produces:
  ```swift
  public enum Verdict: Equatable, Sendable {
      case unreadable                 // 順1
      case wrongHead(expected: String) // 順2。expected は heads の先頭
      case endsWithN                  // 順3
      case alreadyUsed                // 順4
      case accepted                   // 順5
  }
  extension ShiritoriRules {
      /// reading は正規化済みの読み。取れなかったときは nil
      public static func judge(reading: String?, heads: [String], used: Set<String>) -> Verdict
  }
  ```

- [ ] **Step 1: テストを書く**（`ShiritoriRulesJudgeTests.swift`。順は spec §5.3）
  ```swift
  let heads = ["ご"]; let used: Set = ["ごま"]
  @Test func judge_order() {
      #expect(ShiritoriRules.judge(reading: nil, heads: heads, used: used) == .unreadable)
      #expect(ShiritoriRules.judge(reading: "", heads: heads, used: used) == .unreadable)
      #expect(ShiritoriRules.judge(reading: "ごりら1", heads: heads, used: used) == .unreadable)
      #expect(ShiritoriRules.judge(reading: "ー", heads: heads, used: used) == .unreadable)        // 次の文字を決められない
      #expect(ShiritoriRules.judge(reading: "らっぱ", heads: heads, used: used) == .wrongHead(expected: "ご"))
      #expect(ShiritoriRules.judge(reading: "ごはん", heads: heads, used: used) == .endsWithN)
      #expect(ShiritoriRules.judge(reading: "ごま", heads: heads, used: used) == .alreadyUsed)
      #expect(ShiritoriRules.judge(reading: "ごりら", heads: heads, used: used) == .accepted)
      #expect(ShiritoriRules.judge(reading: "ご", heads: heads, used: used) == .accepted)          // 1文字も可
      #expect(ShiritoriRules.judge(reading: "ぱんつくったん", heads: heads, used: used) == .wrongHead(expected: "ご")) // 順2 が 順3 より先
  }
  ```
- [ ] **Step 2〜5: 失敗確認 → 実装 → 成功確認 → コミット** — unreadable の条件は「nil、`!Kana.isHiraganaWord`、`endsWithN` でなく `nextHeads` が空」。

### Task 5: 辞書（`WordBank/`）

**Files:** Create `Word.swift`, `WordBank.swift`, `Resources/words.json`, `WordBankTests.swift`, `BundledWordsTests.swift`。Modify `Package.swift`（`resources` を足す）。

**Interfaces:**
- Consumes: `ShiritoriRules`
- Produces:
  ```swift
  public struct Word: Codable, Equatable, Hashable, Sendable { public let reading: String; public let emoji: String? }
  public struct WordBank: Sendable {
      public init(words: [Word])
      public static func bundled() throws -> WordBank           // Bundle.module の words.json
      public var words: [Word] { get }
      /// heads の先頭の文字で始まる、まだ出ていない言葉を選ぶ。行き止まりの言葉は、ほかに候補があれば避ける
      public func pick<R: RandomNumberGenerator>(heads: [String], used: Set<String>, using rng: inout R) -> Word?
      /// 文字を問わず、まだ出ていない言葉を選ぶ（最初の言葉と「まいった」用）。行き止まりを避けるのは pick と同じ
      public func pickAny<R: RandomNumberGenerator>(used: Set<String>, using rng: inout R) -> Word?
      /// 認識エンジンへ渡すヒント。heads のどれかで始まる読みを最大100語
      public func hints(for heads: [String]) -> [String]
  }
  ```
  「行き止まり」= その言葉の `nextHeads` の先頭で始まる語が、辞書全体に5語未満（spec §5.6）。JSON の形は `[{"reading":"りんご","emoji":"🍎"}, ...]`（`emoji` は省略可）。

- [ ] **Step 1: テストを書く**（`WordBankTests.swift`、小さな手作りの辞書で）
  - `pick_returnsUnusedWordStartingWithFirstHead`: heads `["や","しゃ"]` → 「や」で始まる語だけが返る。
  - `pick_skipsUsed` / `pick_returnsNilWhenNoCandidate`
  - `pick_avoidsDeadEndWhenAlternativeExists`: 「ご」で始まる語が ごりら（→ら は6語ある）と ごーる（→る は1語）のとき、何度引いても ごりら。
  - `pick_returnsDeadEndWhenOnlyChoice`
  - `pickAny_returnsNilWhenAllUsed`
  - `hints_capsAt100AndMatchesAnyHead`
  乱数は、シードを固定した自作の `SeededGenerator: RandomNumberGenerator` をテスト用ヘルパーに置く。
- [ ] **Step 2: 失敗確認 → Step 3: 実装 → Step 4: 成功確認**
- [ ] **Step 5: `words.json` を作る** — `git show legacy-2025:app/Sources/ShiritoriCore/Dictionary/WordDictionaryService.swift` の easy / normal / hard の語を重複なしで集める（299語）。「ん」で終わる語（36語）、1文字の語、子供向けでない語（びーる、その他 酒・たばこ・暴力・賭け事にあたる語）、言葉として怪しい語（例: ろばた、ろっく、ここ、もの）を除く。絵文字は付けなくてよい。
- [ ] **Step 6: 同梱辞書を守るテストを書いて通す**（`BundledWordsTests.swift`）
  ```swift
  @Test func bundledWords_followTheRules() throws {
      let words = try WordBank.bundled().words
      #expect(words.count >= 240)
      #expect(Set(words.map(\.reading)).count == words.count)                       // 重複なし
      #expect(words.allSatisfy { Kana.isHiraganaWord($0.reading) })
      #expect(words.allSatisfy { !ShiritoriRules.endsWithN($0.reading) })
      #expect(words.allSatisfy { $0.reading.count >= 2 })
      #expect(!words.contains { $0.reading == "びーる" })
  }
  ```
- [ ] **Step 7: コミット**

### Task 6: 1回のあそびの状態（`Session/ShiritoriSession.swift`）

**Interfaces:**
- Consumes: `ShiritoriRules`, `Verdict`, `WordBank`, `Word`
- Produces:
  ```swift
  public struct SessionStats: Equatable, Sendable { public var corrections = 0; public var unheard = 0; public var retries = 0 }
  public enum AppMove: Equatable, Sendable { case reply(Word); case giveUp(Word); case outOfWords }
  public struct ShiritoriSession: Sendable {
      public init(bank: WordBank)
      public private(set) var heads: [String]          // 子供が次に使える最初の文字
      public private(set) var used: Set<String>
      public private(set) var chainCount: Int          // 子供が正しく言えた回数
      public private(set) var stats: SessionStats
      public private(set) var lastAppWord: Word?
      public var canUndo: Bool { get }
      /// 最初の言葉を選んで場に出す。辞書が空なら nil
      public mutating func start<R: RandomNumberGenerator>(using rng: inout R) -> Word?
      /// 子供の言葉を判定して状態を進める。accepted のときだけ chainCount と used と heads が変わる
      public mutating func submit(reading: String?) -> Verdict
      /// アプリの番。reply: 続きの言葉 / giveUp: 「まいった」で別の文字から再開する言葉 / outOfWords: 辞書を使い切った
      public mutating func appTurn<R: RandomNumberGenerator>(using rng: inout R) -> AppMove
      /// 直前の submit（と、それに続いた appTurn）を無かったことにし、corrections を1増やす
      public mutating func undoLast()
  }
  ```
  統計の増やし方: `unreadable` → `unheard += 1`。`wrongHead` / `endsWithN` / `alreadyUsed` → `retries += 1`。`undoLast` → `corrections += 1`（取り消した submit が増やした `unheard` / `retries` は元に戻す）。取り消しは、`submit` の直前の状態を1つ覚えておいて戻す。`canUndo` は覚えた状態があるとき true。`start` で消える。

- [ ] **Step 1: テストを書く**（`ShiritoriSessionTests.swift`、手作りの辞書と `SeededGenerator`）
  - `start_putsFirstWordAndSetsHeads`: 返った語の `nextHeads` が `heads` と一致、`used` にその読みが入る、`chainCount == 0`、`canUndo == false`。
  - `submit_accepted_incrementsChainAndMovesHeads`: `heads` が子供の言葉の `nextHeads` になる。
  - `submit_rejected_changesOnlyStats`（`wrongHead` / `endsWithN` / `alreadyUsed` で `retries == 1`、`unreadable` で `unheard == 1`、`chainCount`・`used`・`heads` は不変）。
  - `appTurn_reply_usesFirstHeadAndMovesHeads`
  - `appTurn_giveUp_whenNoCandidate_keepsChain`: 続きが無い → `.giveUp(word)`、`chainCount` は不変、`heads` は新しい語の `nextHeads`。
  - `appTurn_whenBankExhausted_returnsOutOfWords`【Review Focus 5】: 全語が `used` のとき `.outOfWords`。状態は不変。
  - `undo_afterAcceptedAndReply_restoresEverything`: `chainCount`・`used`（子供の語もアプリの返事も外れる）・`heads`・`lastAppWord` が submit 前に戻り、`corrections == 1`、`canUndo == false`。
  - `undo_afterRejected_restoresStatsAndCountsCorrection`: `retries` が戻り `corrections == 1`。
  - `undo_whenNothingToUndo_doesNothing`
- [ ] **Step 2〜5: 失敗確認 → 実装 → 成功確認 → コミット**

### Task 7: 認識結果から読みを取る（`Speech/ReadingExtractor.swift`）

**Interfaces:**
- Consumes: `Kana`, `ShiritoriRules`
- Produces:
  ```swift
  public enum ReadingExtractor {
      /// 漢字・カタカナまじりの認識結果を読み（ひらがな）にする。ひらがなにできなければ nil
      public static func reading(of text: String) -> String?
      /// 候補の中から採用する1つを選ぶ。heads で始まる候補を優先し、無ければ読みが取れた最初の候補。1つも取れなければ nil
      public static func best(from candidates: [String], heads: [String]) -> (heard: String, reading: String)?
  }
  ```

- [ ] **Step 1: テストを書く**（`ReadingExtractorTests.swift`。前半は試作ビルド 43 で実機が返した文字列）
  ```swift
  @Test(arguments: [("りんご","りんご"),("ゴリラ","ごりら"),("ラッパ","らっぱ"),("牛乳","ぎゅうにゅう"),("車","くるま"),
                    ("ケーキ","けーき"),("新幹線","しんかんせん"),("猫","ねこ"),("キリン","きりん"),("りんご。","りんご")])
  func reading(text: String, expected: String) { #expect(ReadingExtractor.reading(of: text) == expected) }
  @Test func reading_returnsNilForUnreadable() {
      #expect(ReadingExtractor.reading(of: "") == nil); #expect(ReadingExtractor.reading(of: "ABC") == nil); #expect(ReadingExtractor.reading(of: "123") == nil)
  }
  @Test func best_prefersCandidateMatchingHead() {
      let r = ReadingExtractor.best(from: ["車", "ごま"], heads: ["ご"]); #expect(r?.reading == "ごま"); #expect(r?.heard == "ごま")
  }
  @Test func best_fallsBackToFirstReadable() { #expect(ReadingExtractor.best(from: ["ABC", "車"], heads: ["ご"])?.reading == "くるま") }
  @Test func best_returnsNilWhenNothingReadable() { #expect(ReadingExtractor.best(from: [], heads: ["ご"]) == nil); #expect(ReadingExtractor.best(from: ["ABC"], heads: ["ご"]) == nil) }
  ```
- [ ] **Step 2: 失敗確認**
- [ ] **Step 3: 実装する** — `Kana.normalize` したあと、すでに `isHiraganaWord` ならそれを返す。そうでなければ `CFStringTokenizer`（単位は単語、ロケール `ja`）で各トークンの `kCFStringTokenizerAttributeLatinTranscription` を取り、`kCFStringTransformLatinHiragana` でひらがなにしてつなぐ。結果が `isHiraganaWord` でなければ nil。手本は `git show origin/spike/speech-compare:app/ShiritoriApp/Spike/SpeechEngines.swift` の `SpikeKana.reading`。
- [ ] **Step 4: 成功確認**（`swift test` は macOS で走る。読みが実機と違うケースが出たら、そのケースを残したまま報告する） / **Step 5: コミット**

### Task 8: 聞く・話す（`Speech/` の残り）

**Interfaces:**
- Produces:
  ```swift
  public enum ListeningAvailability: Equatable, Sendable { case ready, denied, unsupported }
  public protocol SpeechListening: Sendable {
      /// 許可を求め、端末内認識が使えるかを返す
      func prepare() async -> ListeningAvailability
      /// 聞き始め、話し終わりを検知したら認識候補（第1候補が先頭）を返す。何も聞こえなければ空
      func listen(hints: [String]) async throws -> [String]
  }
  @MainActor public protocol SpeechSpeaking: AnyObject {
      /// 言い終わるか stop されるまで待つ
      func speak(_ text: String) async
      func stop()
  }
  public struct EndOfSpeechDetector: Sendable {
      public init(silence: TimeInterval = 1.2, maximum: TimeInterval = 6.0, startedAt: TimeInterval)
      /// 途中結果が変わったときに呼ぶ
      public mutating func textChanged(_ text: String, at time: TimeInterval)
      /// 話し終わりとみなすか。何か聞こえてから silence 秒変化が無い、または開始から maximum 秒
      public func shouldFinish(at time: TimeInterval) -> Bool
  }
  public final class OnDeviceSpeechListener: SpeechListening { public init() }
  @MainActor public final class SystemSpeaker: NSObject, SpeechSpeaking { public override init() }
  ```

- [ ] **Step 1: `EndOfSpeechDetector` のテストを書く**（`EndOfSpeechDetectorTests.swift`。数値は spec §5.5）
  ```swift
  @Test func finishesAfterSilenceOnceSomethingWasHeard() {
      var d = EndOfSpeechDetector(startedAt: 0)
      #expect(!d.shouldFinish(at: 3.0))                 // まだ何も聞こえていない
      d.textChanged("ご", at: 1.0); d.textChanged("ごりら", at: 1.5)
      #expect(!d.shouldFinish(at: 2.6)); #expect(d.shouldFinish(at: 2.7))
  }
  @Test func sameTextDoesNotExtendSilence() { var d = EndOfSpeechDetector(startedAt: 0); d.textChanged("ご", at: 1.0); d.textChanged("ご", at: 2.0); #expect(d.shouldFinish(at: 2.2)) }
  @Test func finishesAtMaximumEvenWithoutSpeech() { let d = EndOfSpeechDetector(startedAt: 0); #expect(!d.shouldFinish(at: 5.9)); #expect(d.shouldFinish(at: 6.0)) }
  ```
- [ ] **Step 2: 失敗確認 → 実装 → 成功確認 → コミット**
- [ ] **Step 3: `OnDeviceSpeechListener` を実装する**（単体テストなし。実機で確かめる）
  - `prepare`: `SFSpeechRecognizer.requestAuthorization` と `AVAudioApplication.requestRecordPermission`。どちらか拒否 → `.denied`。`SFSpeechRecognizer(locale: ja-JP)` が nil、または `supportsOnDeviceRecognition == false` → `.unsupported`。
  - `listen`: `AVAudioSession` を `.playAndRecord`（mode `.default`、options `.defaultToSpeaker`）にする。`SFSpeechAudioBufferRecognitionRequest` に `requiresOnDeviceRecognition = true`、`shouldReportPartialResults = true`、`addsPunctuation = false`、`contextualStrings = hints`。`AVAudioEngine` の入力に tap を付けてバッファを渡す。途中結果を `EndOfSpeechDetector` に渡し、0.1秒おきに `shouldFinish` を見て、true になったら `endAudio()`。最終結果の `transcriptions.map(\.formattedString)` を返す。終わるとき（成功・失敗・キャンセルのどれでも）必ず tap を外し、エンジンを止める。継続（continuation）の再開は1回だけ。
  - iOS 以外（`swift test` を回す macOS）でもコンパイルが通るよう、`AVAudioSession` を使う箇所は `#if os(iOS)` で囲む。
  - `Sendable` を満たすために `actor` にしてよい（プロトコルのメソッドは `async` なので呼び出し側は変わらない）。
  - 手本は `origin/spike/speech-compare` の `SpeechEngines.swift`（`legacy(url:hints:onDevice:)`）。あちらはファイル入力なので、マイク入力の部分は新しく書く。
- [ ] **Step 4: `SystemSpeaker` を実装する** — `AVSpeechSynthesizer`、`AVSpeechUtterance(string:)` の voice は `ja-JP`、`rate` は `AVSpeechUtteranceDefaultSpeechRate * 0.9`。`AVSpeechSynthesizerDelegate` の `didFinish` と `didCancel` で `speak` の待ちを解く。`stop()` は `stopSpeaking(at: .immediate)`。
- [ ] **Step 5: ビルドを確かめる** — `swift test`（全件成功）と Global Constraints のビルドコマンド。ビルドログの warning を `grep -i 'deprecated'` で見て、`SFSpeech` に関するものがあれば報告する（spec §12）。
- [ ] **Step 6: コミット**

### Task 9: 画面の状態（`Play/Phrases.swift`, `Play/PlayViewModel.swift`）

**Interfaces:**
- Consumes: `ShiritoriSession`, `AppMove`, `Verdict`, `SessionStats`, `WordBank`, `Word`, `ReadingExtractor`, `SpeechListening`, `SpeechSpeaking`, `ListeningAvailability`, `AppLog`
- Produces:
  ```swift
  public enum Phrases {
      public static func appWord(_ reading: String) -> String        // 読みそのまま
      public static func nextHead(_ head: String) -> String          // "つぎは 「ご」 から！"
      public static let askAgain = "もういちど いってね"
      public static func wrongHead(_ head: String) -> String         // "「ご」から だよ"
      public static let endsWithN = "「ん」が ついちゃった！ もういっかい"
      public static let alreadyUsed = "それ もう いったよ"
      public static func accepted(_ count: Int) -> String            // "7かいめ！"
      public static let giveUp = "まいった！"
      public static let outOfWords = "ことばが なくなっちゃった！"
      public static func finished(_ count: Int) -> String            // "7かい つながったね！"
  }
  @MainActor @Observable public final class PlayViewModel {
      public enum Phase: Equatable { case title, unavailable(ListeningAvailability), appSpeaking, waitingForChild, listening, finished }
      public init(bank: WordBank, listener: any SpeechListening, speaker: any SpeechSpeaking, randomSource: any RandomNumberGenerator = SystemRandomNumberGenerator())
      public private(set) var phase: Phase
      public private(set) var appWord: Word?            // いま場に出ているアプリの言葉
      public private(set) var headLabel: String         // 子供が次に使う文字（heads の先頭）
      public private(set) var heard: String?            // 「きこえた」に出す文字列
      public private(set) var lastVerdict: Verdict?
      public private(set) var chainCount: Int
      public private(set) var stats: SessionStats
      public private(set) var canUndo: Bool
      public func startTapped() async       // title / finished から。prepare → 最初の言葉を言う → waitingForChild
      public func micTapped() async         // waitingForChild のときだけ動く
      public func undoTapped() async        // canUndo のときだけ動く
      public func finishTapped()            // あそんでいる間いつでも。話していたら止める
      public func backToTitleTapped()
  }
  ```
  `micTapped` の流れ: `listening` → `listener.listen(hints: bank.hints(for: heads))` → `ReadingExtractor.best` → `session.submit` → `heard` と `lastVerdict` を更新 → `appSpeaking` で判定の台詞を言う → `accepted` なら `session.appTurn` → `reply`: 言葉を言う / `giveUp`: 「まいった！」のあと言葉を言う / `outOfWords`: 台詞を言って `finished` → `waitingForChild`。
  `undoTapped`: 話していたら `speaker.stop()` して進行中の流れを打ち切る → `session.undoLast()` → 表示を戻す → `waitingForChild`。
  `canUndo` は ViewModel が持つ旗。`session.submit` の直後に true、`undoTapped` のあと・次の `micTapped` の開始時・`startTapped` で false。
  `startTapped` で `session.start` が nil（辞書が空）のときは、`Phrases.outOfWords` を言って `finished` にする。
  乱数は `struct AnyRandom: RandomNumberGenerator`（中に `any RandomNumberGenerator` を持ち、`next()` を転送する）で包んで `session` に渡す。

- [ ] **Step 1: テスト用の偽物を書く**（`Tests/.../Fakes.swift`）— `FakeListener`（`availability` と、`listen` が順に返す `Result<[String], Error>` の列、呼ばれた回数と hints を記録）、`FakeSpeaker`（言った文を配列に記録。`holdNext()` で次の `speak` を `stop()` か `release()` まで待たせられる）。
- [ ] **Step 2: テストを書く**（`PlayViewModelTests.swift`、`@MainActor @Suite`。辞書は りんご・ごりら・らっぱ・ぱせり・りす・すいか・かめ・めだか など、行き先が決まる小さなもの。`SeededGenerator` で最初の言葉を固定）
  - `start_speaksFirstWordAndWaits`: `phase == .waitingForChild`、`speaker.spoken` の最後が最初の言葉、`headLabel` がその `nextHeads` の先頭。
  - `start_whenDenied_showsUnavailable` / `start_whenUnsupported_showsUnavailable`【RF1】: `phase == .unavailable(.denied)` / `.unavailable(.unsupported)`、`speaker.spoken.isEmpty`。
  - `mic_accepted_countsAndAppReplies`: `chainCount == 1`、`heard` が聞こえた文字列、`speaker.spoken` に `"1かいめ！"` とアプリの返事、最後は `waitingForChild`。
  - `mic_passesHintsForCurrentHeads`: `listener` が受けた hints がすべて `headLabel` で始まる。
  - `mic_wrongHead_saysHintAndKeepsCount`: `speaker.spoken` に `Phrases.wrongHead(headLabel)`、`chainCount == 0`、`stats.retries == 1`。`endsWithN`・`alreadyUsed` も同じ形で各1件。
  - `mic_whenNothingHeard_asksAgain`【RF2】: `listen` が `[]` → `Phrases.askAgain`、`chainCount == 0`、`stats.unheard == 1`、`phase == .waitingForChild`。
  - `mic_whenListenThrows_returnsToWaiting`【RF3】: `listen` が throw → 上と同じ結果。
  - `mic_whenNotWaiting_isIgnored`【RF4】: `phase` が `title` / `appSpeaking`（`FakeSpeaker.holdNext()` で作る）/ `finished` のとき `micTapped()` を呼んでも `listener.listenCount` が増えない。
  - `appTurn_whenNoCandidate_saysGiveUpAndContinues`: `speaker.spoken` に `Phrases.giveUp`、`chainCount` はそのまま、`waitingForChild`。
  - `appTurn_whenOutOfWords_finishes`【RF5】: 辞書を使い切る並びで `Phrases.outOfWords` を言い、`phase == .finished`。
  - `undo_afterAccepted_restoresCountAndHead`: `chainCount` が戻り、`headLabel` が前の文字、`stats.corrections == 1`、`canUndo == false`、`waitingForChild`。
  - `undo_whileAppIsSpeaking_stopsSpeech`: `holdNext()` で返事の途中にして `undoTapped()` → `speaker.stopCount == 1`、最後は `waitingForChild` で、打ち切られた流れがあとから状態を書き換えない。
  - `undo_isUnavailableAfterNextMicTap`
  - `finish_stopsSpeechAndShowsFinished` / `startTapped_fromFinished_resetsCountAndStats`
- [ ] **Step 3: 失敗確認 → Step 4: `Phrases` と `PlayViewModel` を実装 → Step 5: 成功確認** — 各状態遷移と判定を `AppLog.play` に `debug` で記録する。
- [ ] **Step 6: コミット**

### Task 10: 画面と起動（`Play/*View.swift`, `ShiritoriAppApp.swift`）

**Interfaces:**
- Consumes: `PlayViewModel`, `Phrases`, `WordBank.bundled()`, `OnDeviceSpeechListener`, `SystemSpeaker`
- Produces: `RootView`（Task 1 の仮実装を置き換え）。`RootView.init()` が本物の部品で `PlayViewModel` を組み立てる。`RootView.init(viewModel:)` はプレビュー用。

- [ ] **Step 1: 画面を実装する**（見た目は最小。色・書体は作り込まない）
  - `RootView`: `phase` が `.title` → `TitleView`、`.unavailable` → `UnavailableView`、それ以外 → `PlayView`。`.finished` のとき `PlayView` の上に `FinishOverlay`。
  - `TitleView`: アプリ名「おんせい しりとり」と「はじめる」ボタン。
  - `PlayView`: spec §5.1 の並び。上段に「⭐ ○かい つながった」と「おしまい」。中段にアプリの言葉（最後の文字を強調）と `Phrases.nextHead`。大きなマイクボタン（`waitingForChild` のときだけ有効。`listening` のときは「きいてるよ…」）。下段に「きこえた:『○○』」と「ちがうよ」（`canUndo` のときだけ表示）。
  - `FinishOverlay`: `Phrases.finished(chainCount)`、「もういっかい」「おわる」、その下に小さく「ちがうよ ○ / きこえなかった ○ / いいなおし ○」（spec §9。M3 で外す）。
  - `UnavailableView`: `.denied` → 「せっていで マイクと おんせいにんしきを ゆるしてね」と設定アプリを開くボタン。`.unsupported` → 「この たんまつでは あそべません」。設定アプリを開く処理は UIKit を使うので `#if canImport(UIKit)` で囲む（`swift test` は macOS で走る）。
  - すべてのボタンに `accessibilityLabel`。`#Preview` を各画面に1つ以上（偽物の listener / speaker で）。
- [ ] **Step 2: 確かめる** — `swift test` 全件成功。Global Constraints のビルドコマンド成功。シミュレータに入れて起動し、タイトルと、「はじめる」を押したあとの画面（許可ダイアログ）を `xcrun simctl io <UDID> screenshot` で撮って目で見る（手順は ios-simulator-app-verification スキル）。
- [ ] **Step 3: コミット**

### Task 11: TestFlight へ届けて、オーナーに渡す

- [ ] **Step 1: 全体を確かめる** — `swift test`（全件成功。件数を記録）、ビルドと Archive のコマンド成功、`git diff origin/main --stat` で意図しないファイルが無いこと。
- [ ] **Step 2: PR を作る** — ブランチ `feat/m1-talk-loop`。本文は「何をしたか／確かめたこと／未確認（子供の声・話し終わり検知・読みの誤判定）／副作用（main に入ると Default がビルドを作る）」。issue を閉じるキーワードは書かない。
- [ ] **Step 3: マージしてクラウドのビルドを読む** — マージはオーナーの承認を得てから。`gh pr view <N> --json state,mergedAt` で `MERGED` を確かめる。ASC の Xcode Cloud（Chrome）でビルドの成功と、TestFlight でそのビルドがグループ `shinya` に入り「テスト中」になっていることを読む。入っていなければ、`Default` に「TestFlight 内部テスト」のポストアクションを足す案を選択式でオーナーに確認する（勝手に設定を変えない）。
- [ ] **Step 4: 【人の判断】オーナーに渡す** — ビルド番号と、記録してほしい物差し（spec §9）を伝える: 手助けなしで続いた回数（目標10）、「ちがうよ」の数、「きこえなかった」の数、「いいなおし」の数。あわせて「話し終わりの検知は合っていたか」「読みの間違いで困った言葉」を聞く。
- [ ] **Step 5: 結果を受けて決める** — 聞き取り方式（spec §5.5）と認識エンジン（spec §4）を確定し、spec の該当箇所と §12 の表を更新する。目標に届かなければ、M2 に進まずに差し替えを先に計画する。
- [ ] **Step 6: 片付け** — M1 の移植が済んだので、`spike/speech-compare` ブランチの削除をオーナーに確認する。
