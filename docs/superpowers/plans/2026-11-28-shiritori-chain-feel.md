# しりとりらしさの改善（M1.5）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** アプリが聞き取った言葉を言い返し、言葉のつながりを画面に残し、判定と聞き取りの記録を端末に残す。

**Architecture:** つながり（出た言葉の列）は値型 `ShiritoriSession` が持ち、取り消しは既存のスナップショットでそのまま戻る。言い返しは `PlayViewModel` が判定の反応を組み立てるときに頭に付ける。記録は `os.Logger` のレベルを `info` に上げ、話し終わりの理由は `EndOfSpeechDetector` が返す。

**Tech Stack:** Swift 6 / SwiftUI / Swift Testing / Speech（`SFSpeechRecognizer`）/ `os.Logger`

**Spec:** `docs/superpowers/specs/2026-11-28-shiritori-chain-feel-design.md`（親: `docs/superpowers/specs/2026-11-23-shiritori-v1-redesign-design.md`）

## Global Constraints

- 認識エンジンを差し替えない。聞き取りの数値（話し終わり 1.2 秒・最長 6 秒・最終結果待ち 1.5 秒・ヒント最大 100 語）を変えない。
- 言い返しは「○かいめ！」の**置き換え**。1 往復で言う台詞を増やさない。
- 台詞と画面の文字はすべてひらがな（数字と記号は可）。言い返しには認識の生の文字列（漢字のことがある）ではなく、読み（`heardReading`）を使う。
- つながりの表示は直近 3 つまで。
- 子供の声そのものは記録しない。文字列だけ、`privacy: .public` で記録する。
- `info` に上げるのは「聞き取りの終わり」「判定」「アプリの番」の 3 つだけ。状態遷移などは `debug` のまま。
- ViewModel で `DispatchQueue.asyncAfter` と `Timer` を使わない。外部パッケージを足さない。
- すべての操作できる UI 部品と、新しく出す文字に `accessibilityLabel` を付ける。
- テスト: `cd app && swift test`。ビルド確認: `cd app && xcodebuild build -project ShiritoriApp.xcodeproj -scheme ShiritoriApp -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`。
- コミットはパスを指定して stage する（`git add -A` を使わない）。push・PR・マージは Task 5 だけ。

## Review Focus

設計書が明示していないが、使う人が踏みそうな場面。各行のテストは右のタスクに入れてある。

1. **認識が漢字で返った（「車」）ときの言い返し** → 「くるま？ 『ご』から だよ」のように、ひらがなの読みで言い返す。「車？」とは言わない。（Task 2: `mic_echoesReadingNotRawText`）
2. **「ちがうよ」で取り消した** → つながりから、取り消した子供の言葉と、そのあとアプリが返した言葉が消える。（Task 1: `chain_undo_restoresPreviousChain` / Task 3: `recentChain_undo_removesChildWordAndReply`）
3. **言い直し（最初の文字が違う・「ん」で終わる・既に出た・読めない）** → その言葉はつながりに入らない。（Task 1: `chain_rejected_isUnchanged`）
4. **「まいった！」で別の文字から再開** → つながりは新しい言葉 1 つから始め直す。（Task 1: `chain_giveUp_restartsFromNewWord` / Task 3: `recentChain_afterGiveUp_startsOver`）
5. **辞書を使い切って終わる** → つながりは直前のまま変わらない（落ちない・空にならない）。（Task 1: `chain_outOfWords_isUnchanged`）

---

### Task 1: つながりを `ShiritoriSession` に持たせる

**Files:**
- Modify: `app/Sources/ShiritoriCore/Session/ShiritoriSession.swift`
- Test: `app/Tests/ShiritoriCoreTests/ShiritoriSessionTests.swift`

**Interfaces:**
- Produces: `ShiritoriSession.chain: [String]`（`public var`、読み取りのみ）。最後の `start` または「まいった」以降に出た言葉の読みを、出た順に全部持つ。子供の言葉は `submit` が `.accepted` のときだけ足す。

- [ ] **Step 1: 失敗するテストを書く**（`ShiritoriSessionTests` に追加。既存の `started()` と `bank` を使う）

```swift
@Test func chain_start_hasFirstWord() {
    let (session, _) = started()
    #expect(session.chain == ["りんご"])
}

@Test func chain_acceptedAndReply_appendsInOrder() {
    var (session, rng) = started()
    _ = session.submit(reading: "ごりら")
    #expect(session.chain == ["りんご", "ごりら"])
    _ = session.appTurn(using: &rng)
    #expect(session.chain == ["りんご", "ごりら", "らっぱ"])
}

@Test(arguments: ["らっぱ", "ごはん", "りんご", nil] as [String?])
func chain_rejected_isUnchanged(reading: String?) {
    var (session, _) = started()
    _ = session.submit(reading: reading)
    #expect(session.chain == ["りんご"])
}

@Test func chain_undo_restoresPreviousChain() {
    var (session, rng) = started()
    _ = session.submit(reading: "ごりら")
    _ = session.appTurn(using: &rng)
    session.undoLast()
    #expect(session.chain == ["りんご"])
}

@Test func chain_giveUp_restartsFromNewWord() throws {
    // 「ぱせり」の「り」で始まる言葉が辞書に無いので「まいった」になる
    var (session, rng) = started()
    _ = session.submit(reading: "ごりら")
    _ = session.appTurn(using: &rng)                 // らっぱ
    _ = session.submit(reading: "ぱせり")
    guard case .giveUp(let word) = session.appTurn(using: &rng) else { Issue.record("まいったにならない"); return }
    #expect(session.chain == [word.reading])
}

@Test func chain_outOfWords_isUnchanged() {
    var (session, rng) = started(bank: WordBank(words: [Word(reading: "りんご")]))
    _ = session.submit(reading: "ごりら")
    #expect(session.appTurn(using: &rng) == .outOfWords)
    #expect(session.chain == ["りんご", "ごりら"])
}

@Test func chain_startAgain_resets() {
    var (session, rng) = started()
    _ = session.submit(reading: "ごりら")
    _ = session.start(using: &rng)
    #expect(session.chain.count == 1)
}
```

- [ ] **Step 2: 失敗を確かめる** — Run: `cd app && swift test --filter ShiritoriSessionTests` / Expected: `chain` が無いのでコンパイルエラー
- [ ] **Step 3: 実装する** — `Snapshot` に `var chain: [String]` を足す（取り消しは既存の `checkpoint` でそのまま戻る）。`start` で空にし、`place(_:)` で読みを足し、`submit` の `.accepted` で子供の読みを足す。`appTurn` の「まいった」の分岐では、`place` の前に `chain` を空にする。
- [ ] **Step 4: 通ることを確かめる** — Run: `cd app && swift test` / Expected: 全件成功
- [ ] **Step 5: コミット**

```bash
git add app/Sources/ShiritoriCore/Session/ShiritoriSession.swift app/Tests/ShiritoriCoreTests/ShiritoriSessionTests.swift
git commit -m "feat: あそびの状態に言葉のつながりを持たせる"
```

---

### Task 2: 聞き取った言葉を言い返す

**Files:**
- Modify: `app/Sources/ShiritoriCore/Play/Phrases.swift`
- Modify: `app/Sources/ShiritoriCore/Play/PlayViewModel.swift:144,217-225`
- Modify: `docs/superpowers/specs/2026-11-23-shiritori-v1-redesign-design.md`（§5.3 の表の順 5 の反応の行に「→ M1.5 で言い返しに変更（2026-11-28-shiritori-chain-feel-design.md）」と書き足す）
- Test: `app/Tests/ShiritoriCoreTests/PlayViewModelTests.swift`

**Interfaces:**
- Produces: `Phrases.accepted(_ reading: String) -> String`（`"\(reading)！"`。引数が回数から読みに変わる）、`Phrases.echoed(_ reading: String, _ reaction: String) -> String`（`"\(reading)？ \(reaction)"`）。

- [ ] **Step 1: 既存テストの期待を書き換え、新しいテストを足す**（`PlayViewModelTests`）
  - `mic_accepted_countsAndAppReplies`: `#expect(speaker.spoken == ["りんご", "ごりら！", "らっぱ"])`
  - `mic_wrongHead_saysHintAndKeepsCount`: `#expect(speaker.spoken.last == "らっぱ？ 「ご」から だよ")`
  - `mic_endsWithN_asksToTryAgain`: `#expect(speaker.spoken.last == "ごはん？ 「ん」が ついちゃった！ もういっかい")`
  - `mic_alreadyUsed_saysSo`: `#expect(speaker.spoken.last == "ごご？ それ もう いったよ")`
  - `mic_whenNothingHeard_asksAgain` は変えない（言い返す言葉が無い）
  - ほかに `"1かいめ！"` や `Phrases.accepted(` を期待しているテストがあれば、`grep -n 'かいめ\|Phrases.accepted' app/Tests` で探して同じ形に直す（コメントの中の「1かいめ！」も「ごりら！」に直す）
  - 新規:

```swift
@Test func mic_echoesReadingNotRawText() async {
    // 認識は「車」と漢字で返すことがある。言い返しはひらがなの読みで言う
    let viewModel = await startedViewModel()
    listener.results = [.success(["車"])]
    await viewModel.micTapped()
    #expect(speaker.spoken.last == "くるま？ 「ご」から だよ")
}
```

- [ ] **Step 2: 失敗を確かめる** — Run: `cd app && swift test --filter PlayViewModelTests` / Expected: 上の 5 件が FAIL
- [ ] **Step 3: 実装する** — `Phrases.accepted` の引数を読みに変え、`Phrases.echoed` を足す。`PlayViewModel.phrase(for:)` を `phrase(for verdict: Verdict, reading: String?) -> String` に変える：`.unreadable` は `askAgain`、`.accepted` は `accepted(reading)`、順 2〜4 は `echoed(reading, <今の反応>)`。`reading` が nil のときは今の反応をそのまま返す（`.accepted` と順 2〜4 は読みがあるときしか出ないが、落とさないため）。
- [ ] **Step 4: 通ることを確かめる** — Run: `cd app && swift test` / Expected: 全件成功
- [ ] **Step 5: コミット**

```bash
git add app/Sources/ShiritoriCore/Play/Phrases.swift app/Sources/ShiritoriCore/Play/PlayViewModel.swift app/Tests/ShiritoriCoreTests/PlayViewModelTests.swift docs/superpowers/specs/2026-11-23-shiritori-v1-redesign-design.md
git commit -m "feat: 聞き取った言葉を言い返してから続ける"
```

---

### Task 3: つながりを画面に出す

**Files:**
- Modify: `app/Sources/ShiritoriCore/Play/PlayViewModel.swift`（`syncFromSession`）
- Modify: `app/Sources/ShiritoriCore/Play/PlayView.swift`
- Modify: `docs/superpowers/specs/2026-11-23-shiritori-v1-redesign-design.md`（§5.1 の画面の図の下に「M1.5 でつながりの行を足した（2026-11-28-shiritori-chain-feel-design.md）」と 1 行）
- Test: `app/Tests/ShiritoriCoreTests/PlayViewModelTests.swift`

**Interfaces:**
- Consumes: `ShiritoriSession.chain`（Task 1）
- Produces: `PlayViewModel.recentChain: [String]`（`public private(set) var`。`session.chain` の末尾 3 つ）

- [ ] **Step 1: 失敗するテストを書く**

```swift
@Test func recentChain_showsUpToLastThreeWords() async {
    let viewModel = await startedViewModel()
    #expect(viewModel.recentChain == ["りんご"])
    listener.results = [.success(["ゴリラ"])]
    await viewModel.micTapped()
    #expect(viewModel.recentChain == ["りんご", "ごりら", "らっぱ"])
}

@Test func recentChain_undo_removesChildWordAndReply() async {
    let viewModel = await startedViewModel()
    listener.results = [.success(["ゴリラ"])]
    await viewModel.micTapped()
    viewModel.undoTapped()
    #expect(viewModel.recentChain == ["りんご"])
}

@Test func recentChain_afterGiveUp_startsOver() async {
    let viewModel = await startedViewModel()
    listener.results = [.success(["ゴリラ"]), .success(["ぱせり"])]
    await viewModel.micTapped()
    await viewModel.micTapped()
    #expect(viewModel.recentChain == [viewModel.appWord?.reading ?? ""])
}
```

- [ ] **Step 2: 失敗を確かめる** — Run: `cd app && swift test --filter PlayViewModelTests` / Expected: `recentChain` が無いのでコンパイルエラー
- [ ] **Step 3: 実装する** — `recentChain` を足し、`syncFromSession()` で `Array(session.chain.suffix(3))` を写す。`PlayView` の `header` の下に 1 行足す：`recentChain.joined(separator: " → ")`、`.lineLimit(1)`・`.minimumScaleFactor(0.5)`、ほかの文字と同じ `.rounded` の書体で 22pt 前後、`.accessibilityLabel(recentChain.joined(separator: "、"))`。
- [ ] **Step 4: 通ることを確かめる** — Run: `cd app && swift test` のあと、Global Constraints のビルド確認のコマンド / Expected: 全件成功・`BUILD SUCCEEDED`
- [ ] **Step 5: コミット**

```bash
git add app/Sources/ShiritoriCore/Play/PlayViewModel.swift app/Sources/ShiritoriCore/Play/PlayView.swift app/Tests/ShiritoriCoreTests/PlayViewModelTests.swift docs/superpowers/specs/2026-11-23-shiritori-v1-redesign-design.md
git commit -m "feat: 言葉のつながりを画面に出す"
```

---

### Task 4: 判定と聞き取りの記録を端末に残す

**Files:**
- Modify: `app/Sources/ShiritoriCore/Speech/EndOfSpeechDetector.swift`
- Modify: `app/Sources/ShiritoriCore/Speech/OnDeviceSpeechListener.swift:104-133`
- Modify: `app/Sources/ShiritoriCore/Play/PlayViewModel.swift:142,191`
- Modify: `CLAUDE.md`（§4 ロギングの「レベル」の行のあとに例外を 1 行）
- Test: `app/Tests/ShiritoriCoreTests/EndOfSpeechDetectorTests.swift`

**Interfaces:**
- Produces: `EndOfSpeechDetector.FinishReason`（`public enum FinishReason: String, Sendable { case silence, maximum }`）と `func finishReason(at time: TimeInterval) -> FinishReason?`。`shouldFinish(at:)` は `finishReason(at:) != nil` を返すように残す（既存テストをそのまま通す）。

- [ ] **Step 1: 失敗するテストを書く**（`EndOfSpeechDetectorTests`）

```swift
@Test func finishReason_isSilenceAfterPause() {
    var detector = EndOfSpeechDetector(startedAt: 0)
    detector.textChanged("ごりら", at: 1.0)
    #expect(detector.finishReason(at: 2.1) == nil)
    #expect(detector.finishReason(at: 2.2) == .silence)
}

@Test func finishReason_isMaximumWhileStillTalking() {
    var detector = EndOfSpeechDetector(startedAt: 0)
    detector.textChanged("ご", at: 5.5)
    #expect(detector.finishReason(at: 6.0) == .maximum)
}

@Test func finishReason_isNilBeforeAnythingHeard() {
    let detector = EndOfSpeechDetector(startedAt: 0)
    #expect(detector.finishReason(at: 3.0) == nil)
}
```

- [ ] **Step 2: 失敗を確かめる** — Run: `cd app && swift test --filter EndOfSpeechDetectorTests` / Expected: `finishReason` が無いのでコンパイルエラー
- [ ] **Step 3: 実装する**
  - `EndOfSpeechDetector`: `finishReason(at:)` を足す（最長の判定を先に見る。今の `shouldFinish` と同じ順）。
  - `OnDeviceSpeechListener.listen`: 抜けた理由を 1 つ持つ（`最終結果` / `話し終わり` / `最長` / `最終結果待ちの打ち切り` / `エラー`。話し終わりと最長は `finishReason` から）。最終結果だったかも持つ。最後の `debug` を `AppLog.speech.info("聞き取り終了: 理由=… 最終=… 候補=[…]")` にする（候補はすべて、`privacy: .public`）。
  - `PlayViewModel.micTapped` の判定ログ（142 行目）を `info` にし、次に使える文字（`heads`）・候補すべて・採用した候補の順位（`candidates.firstIndex(of: best.heard)`、採用なしは「なし」）・読み・判定を 1 行で出す。
  - `PlayViewModel.appTurn` のログ（191 行目）を `info` にする。
  - `CLAUDE.md` §4：「判定・聞き取りの終わり・アプリの番の 3 つは、後から仮説を確かめるために `info` で出す（2026-11-28、M1.5）。集め方は `sudo log collect --device`」を足す。
- [ ] **Step 4: 通ることを確かめる** — Run: `cd app && swift test` のあと、ビルド確認のコマンド / Expected: 全件成功・`BUILD SUCCEEDED`
- [ ] **Step 5: コミット**

```bash
git add app/Sources/ShiritoriCore/Speech/EndOfSpeechDetector.swift app/Sources/ShiritoriCore/Speech/OnDeviceSpeechListener.swift app/Sources/ShiritoriCore/Play/PlayViewModel.swift app/Tests/ShiritoriCoreTests/EndOfSpeechDetectorTests.swift CLAUDE.md
git commit -m "feat: 判定と聞き取りの記録を端末に残す"
```

---

### Task 5: 確かめて、TestFlight に届けて、オーナーに渡す

- [ ] **Step 1: 全体を確かめる** — `cd app && swift test`（全件成功。件数を記録）、ビルド確認のコマンド、Release の Archive（CLAUDE.md §7）：`cd app && xcodebuild archive -project ShiritoriApp.xcodeproj -scheme ShiritoriApp -configuration Release -destination 'generic/platform=iOS' -archivePath "$TMPDIR/ShiritoriApp.xcarchive" CODE_SIGNING_ALLOWED=NO` が `ARCHIVE SUCCEEDED`。`git diff origin/main --stat` で意図しないファイルが無いこと、`git diff origin/main | cat -e` で触っていない行の行末が変わっていないこと。
- [ ] **Step 2: PR を作る** — ブランチ `docs/chain-feel-design`（設計書・計画書・実装を 1 本の PR に）。本文は「何をしたか／確かめたこと／未確認（「？」の抑揚、ログの集め方）」。`Refs #11`（`Closes` は書かない）。`claude-review` の結果を読む。
- [ ] **Step 3: マージしてビルドを読む** — マージはオーナーの承認を得てから（closed 質問。承認の選択肢に「Claude が 1 回試す」を含める）。`gh pr view <N> --json state,mergedAt` で `MERGED` を確かめる。ASC のグループ `shinya` の「ビルド」タブで、新しいビルドが「テスト中」になったことを読む。
- [ ] **Step 4: 【人の判断】オーナーに渡す** — ビルド番号と、見てほしいこと（#11 の表に 1 行／「続きになっていない」と感じた場面で「ちがうよ」を押せたか／「すいか？」の言い方が自然か）を、スマホで答えられる形で 1 回にまとめて伝える。遊んだあと、iPhone を Mac につないで `! sudo log collect --device --last 1h --output ~/Desktop/shiritori.logarchive` を打ってもらう（`sudo` のパスワードが要るため人の手順）。
- [ ] **Step 5: 記録を読んで #11 に書く** — `log show ~/Desktop/shiritori.logarchive --predicate 'subsystem == "com.asapapalab.ShiritoriApp"' --info` で読み、第 1 候補以外を採った回数（H1）と、「話し終わり」で終わり候補が言いかけに見える回数（H2）を数えて #11 にコメントする。次に直すもの（案 B の中身）を closed 質問でオーナーに確認する。
