import Testing
@testable import ShiritoriCore

/// あそぶ画面の状態。聞く・話すを偽物に差し替えて、操作の結果を外側から確かめる。
@MainActor
@Suite struct PlayViewModelTests {
    /// 最初の言葉が必ず「りんご」になる辞書（行き止まりでないのが「りんご」だけ）
    static let words = ["りんご", "ごま", "ごみ", "ごぼう", "ごりら", "ごむ", "らっぱ"]

    let listener = FakeListener()
    let speaker = FakeSpeaker()

    private func makeViewModel(words: [String] = PlayViewModelTests.words) -> PlayViewModel {
        PlayViewModel(
            bank: WordBank(words: words.map { Word(reading: $0) }),
            listener: listener,
            speaker: speaker,
            randomSource: SeededGenerator(seed: 7)
        )
    }

    /// 「はじめる」を押して、最初の言葉（りんご）が出たところまで進める
    private func startedViewModel(words: [String] = PlayViewModelTests.words) async -> PlayViewModel {
        let viewModel = makeViewModel(words: words)
        await viewModel.startTapped()
        return viewModel
    }

    // MARK: - はじまり

    @Test func initialPhaseIsTitle() {
        #expect(makeViewModel().phase == .title)
    }

    @Test func start_speaksFirstWordAndWaits() async {
        let viewModel = await startedViewModel()
        #expect(viewModel.phase == .waitingForChild)
        #expect(speaker.spoken == ["りんご"])
        #expect(viewModel.appWord?.reading == "りんご")
        #expect(viewModel.headLabel == "ご")
        #expect(viewModel.chainCount == 0)
        #expect(!viewModel.canUndo)
    }

    @Test func start_whenDenied_showsUnavailable() async {
        listener.availability = .denied
        let viewModel = await startedViewModel()
        #expect(viewModel.phase == .unavailable(.denied))
        #expect(speaker.spoken.isEmpty)
    }

    @Test func start_whenUnsupported_showsUnavailable() async {
        listener.availability = .unsupported
        let viewModel = await startedViewModel()
        #expect(viewModel.phase == .unavailable(.unsupported))
        #expect(speaker.spoken.isEmpty)
    }

    @Test func start_canRetryAfterPermissionIsGranted() async {
        listener.availability = .denied
        let viewModel = await startedViewModel()
        listener.availability = .ready
        await viewModel.startTapped()
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func start_withEmptyBank_finishesWithoutCrashing() async {
        let viewModel = await startedViewModel(words: [])
        #expect(viewModel.phase == .finished)
        #expect(speaker.spoken == [Phrases.outOfWords])
    }

    // MARK: - 子供の番

    @Test func mic_accepted_countsAndAppReplies() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ゴリラ"])]
        await viewModel.micTapped()
        #expect(viewModel.chainCount == 1)
        #expect(viewModel.heard == "ゴリラ")
        #expect(viewModel.lastVerdict == .accepted)
        #expect(speaker.spoken == ["りんご", "ごりら！", "らっぱ"])
        #expect(viewModel.appWord?.reading == "らっぱ")
        #expect(viewModel.headLabel == "ぱ")
        #expect(viewModel.phase == .waitingForChild)
        #expect(viewModel.canUndo)
    }

    @Test func mic_passesHintsForCurrentHeads() async {
        let viewModel = await startedViewModel()
        await viewModel.micTapped()
        let hints = listener.receivedHints.first ?? []
        #expect(!hints.isEmpty)
        #expect(hints.allSatisfy { $0.hasPrefix("ご") })
    }

    @Test func mic_prefersCandidateThatMatchesHead() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["車", "ごま"])]
        await viewModel.micTapped()
        #expect(viewModel.heard == "ごま")
        #expect(viewModel.lastVerdict == .accepted)
    }

    @Test func mic_exposesHeardWordInHiraganaForTheScreen() async {
        // 認識結果は「車」のように漢字で返ることがある。画面にはひらがなで出す
        let viewModel = await startedViewModel()
        listener.results = [.success(["車"])]
        await viewModel.micTapped()
        #expect(viewModel.heard == "車")
        #expect(viewModel.heardReading == "くるま")
        viewModel.undoTapped()
        #expect(viewModel.heardReading == nil)
    }

    @Test func mic_echoesReadingNotRawText() async {
        // 認識は「車」と漢字で返すことがある。言い返しはひらがなの読みで言う
        let viewModel = await startedViewModel()
        listener.results = [.success(["車"])]
        await viewModel.micTapped()
        #expect(speaker.spoken.last == "くるま？ 「ご」から だよ")
    }

    @Test func mic_wrongHead_saysHintAndKeepsCount() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ラッパ"])]
        await viewModel.micTapped()
        #expect(speaker.spoken.last == "らっぱ？ 「ご」から だよ")
        #expect(viewModel.lastVerdict == .wrongHead(expected: "ご"))
        #expect(viewModel.chainCount == 0)
        #expect(viewModel.stats.retries == 1)
        #expect(viewModel.headLabel == "ご")
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func mic_endsWithN_asksToTryAgain() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ごはん"])]
        await viewModel.micTapped()
        #expect(speaker.spoken.last == "ごはん？ 「ん」が ついちゃった！ もういっかい")
        #expect(viewModel.chainCount == 0)
        #expect(viewModel.stats.retries == 1)
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func mic_alreadyUsed_saysSo() async {
        // 辞書が「ごご」だけなので、最初の言葉は「ごご」、次に使える文字は「ご」
        let viewModel = await startedViewModel(words: ["ごご"])
        listener.results = [.success(["ごご"])]
        await viewModel.micTapped()
        #expect(speaker.spoken.last == "ごご？ それ もう いったよ")
        #expect(viewModel.lastVerdict == .alreadyUsed)
        #expect(viewModel.chainCount == 0)
        #expect(viewModel.stats.retries == 1)
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func mic_whenNothingHeard_asksAgain() async {
        let viewModel = await startedViewModel()
        listener.results = [.success([])]
        await viewModel.micTapped()
        #expect(speaker.spoken.last == Phrases.askAgain)
        #expect(viewModel.lastVerdict == .unreadable)
        #expect(viewModel.heard == nil)
        #expect(viewModel.chainCount == 0)
        #expect(viewModel.stats.unheard == 1)
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func mic_whenListenThrows_saysItCannotListenAndReturnsToWaiting() async {
        let viewModel = await startedViewModel()
        listener.results = [.failure(FakeListener.Failure())]
        await viewModel.micTapped()
        // 「聞こえなかった」とは区別する。子供のせいではなく、物差し（聞き取れずの数）も汚さない
        #expect(speaker.spoken.last == Phrases.cannotListen)
        #expect(viewModel.listenFailures == 1)
        #expect(viewModel.stats.unheard == 0)
        #expect(viewModel.chainCount == 0)
        #expect(!viewModel.canUndo)
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func mic_whileListening_secondTapIsIgnored() async {
        let viewModel = await startedViewModel()
        listener.holdNext()
        let flow = Task { await viewModel.micTapped() }
        await listener.waitUntilHolding()
        #expect(viewModel.phase == .listening)
        await viewModel.micTapped()                     // 連打
        #expect(listener.listenCount == 1)
        listener.release()
        await flow.value
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func mic_whenNotWaiting_isIgnored() async {
        // タイトル
        let viewModel = makeViewModel()
        await viewModel.micTapped()
        #expect(listener.listenCount == 0)

        // アプリが話している最中
        speaker.holdNext()
        let starting = Task { await viewModel.startTapped() }
        await speaker.waitUntilHolding()
        #expect(viewModel.phase == .appSpeaking)
        await viewModel.micTapped()
        #expect(listener.listenCount == 0)
        speaker.release()
        await starting.value

        // おわり
        viewModel.finishTapped()
        await viewModel.micTapped()
        #expect(listener.listenCount == 0)
    }

    // MARK: - アプリの番

    @Test func appTurn_whenNoCandidate_saysGiveUpAndContinues() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ゴリラ"]), .success(["ぱせり"])]
        await viewModel.micTapped()
        await viewModel.micTapped()
        #expect(speaker.spoken.contains(Phrases.giveUp))
        #expect(viewModel.chainCount == 2)
        #expect(viewModel.phase == .waitingForChild)
        // 「まいった！」のあとに新しい言葉を言い、その言葉から続ける
        #expect(speaker.spoken.last == viewModel.appWord?.reading)
        #expect(viewModel.appWord?.reading.hasPrefix("ご") == true)
    }

    @Test func appTurn_whenOutOfWords_finishes() async {
        let viewModel = await startedViewModel(words: ["りんご"])
        listener.results = [.success(["ゴリラ"])]
        await viewModel.micTapped()
        #expect(speaker.spoken.last == Phrases.outOfWords)
        #expect(viewModel.phase == .finished)
        #expect(viewModel.chainCount == 1)
    }

    // MARK: - つながりの表示

    @Test func recentChain_showsUpToLastThreeWords() async {
        let viewModel = await startedViewModel()
        #expect(viewModel.recentChain == ["りんご"])
        listener.results = [.success(["ゴリラ"])]
        await viewModel.micTapped()
        #expect(viewModel.recentChain == ["りんご", "ごりら", "らっぱ"])
        // 判定に辞書は使わないので「ぱご」も通る。5 語目のアプリの言葉まで出たら、直近 3 つだけを出す
        listener.results = [.success(["ぱご"])]
        await viewModel.micTapped()
        #expect(viewModel.recentChain == ["らっぱ", "ぱご", viewModel.appWord?.reading ?? ""])
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

    // MARK: - ちがうよ

    @Test func undo_afterAccepted_restoresCountAndHead() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ゴリラ"])]
        await viewModel.micTapped()
        viewModel.undoTapped()
        #expect(viewModel.chainCount == 0)
        #expect(viewModel.headLabel == "ご")
        #expect(viewModel.appWord?.reading == "りんご")
        #expect(viewModel.heard == nil)
        #expect(viewModel.stats.corrections == 1)
        #expect(!viewModel.canUndo)
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func undo_afterRejected_countsCorrection() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ラッパ"])]
        await viewModel.micTapped()
        #expect(viewModel.canUndo)
        viewModel.undoTapped()
        #expect(viewModel.stats == SessionStats(corrections: 1, unheard: 0, retries: 0))
    }

    @Test func undo_whileAppIsSpeaking_stopsSpeechAndAbandonsTheReply() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ゴリラ"])]
        speaker.holdNext()                              // 言い返しの「ごりら！」の途中で止まる
        let flow = Task { await viewModel.micTapped() }
        await speaker.waitUntilHolding()
        #expect(viewModel.phase == .appSpeaking)

        viewModel.undoTapped()
        await flow.value

        #expect(speaker.stopCount >= 1)
        #expect(viewModel.phase == .waitingForChild)
        #expect(viewModel.chainCount == 0)
        #expect(viewModel.headLabel == "ご")
        // 打ち切られた流れが、あとからアプリの返事を言ったり状態を書き換えたりしない
        #expect(!speaker.spoken.contains("らっぱ"))
        #expect(viewModel.appWord?.reading == "りんご")
    }

    @Test func undo_revertsOnlyTheLatestAttempt() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ラッパ"]), .success([])]
        await viewModel.micTapped()      // 最初の文字が違う → 言い直し 1
        await viewModel.micTapped()      // 聞き取れず 1
        viewModel.undoTapped()
        // 取り消されるのは直前の「聞き取れず」だけ
        #expect(viewModel.stats == SessionStats(corrections: 1, unheard: 0, retries: 1))
        #expect(!viewModel.canUndo)
    }

    @Test func undo_isUnavailableOnceTheNextListeningStarts() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ラッパ"])]
        await viewModel.micTapped()
        #expect(viewModel.canUndo)
        listener.holdNext()
        let flow = Task { await viewModel.micTapped() }
        await listener.waitUntilHolding()
        // 次の言葉を聞き始めたら、前の聞き取りは取り消せない
        #expect(!viewModel.canUndo)
        viewModel.undoTapped()
        #expect(viewModel.stats.corrections == 0)
        #expect(viewModel.phase == .listening)
        listener.release()
        await flow.value
    }

    @Test func undo_whenNothingToUndo_doesNothing() async {
        let viewModel = await startedViewModel()
        viewModel.undoTapped()
        #expect(viewModel.stats.corrections == 0)
        #expect(viewModel.phase == .waitingForChild)
    }

    // MARK: - おわり

    @Test func finish_stopsSpeechAndShowsFinished() async {
        let viewModel = await startedViewModel()
        viewModel.finishTapped()
        #expect(viewModel.phase == .finished)
        #expect(speaker.stopCount >= 1)
    }

    @Test func finish_whileAppIsSpeaking_abandonsTheFlow() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ゴリラ"])]
        speaker.holdNext()                              // 言い返しの「ごりら！」の途中で止まる
        let flow = Task { await viewModel.micTapped() }
        await speaker.waitUntilHolding()
        viewModel.finishTapped()
        await flow.value
        #expect(viewModel.phase == .finished)
        #expect(!speaker.spoken.contains("らっぱ"))
        // おわりの表示に出す回数は、止める前に正しく言えた分を含む
        #expect(viewModel.chainCount == 1)
    }

    @Test func finish_whileListening_stopsTheMicrophone() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ゴリラ"])]
        listener.holdNext()
        let flow = Task { await viewModel.micTapped() }
        await listener.waitUntilHolding()
        viewModel.finishTapped()
        await flow.value
        // おわりの表示の裏でマイクが開いたままにならない
        #expect(listener.cancelCount == 1)
        #expect(viewModel.phase == .finished)
        // 止めたあとに届いた聞き取り結果は使わない
        #expect(viewModel.chainCount == 0)
    }

    @Test func undoOrBackToTitle_whileListening_alsoStopsTheMicrophone() async {
        let viewModel = await startedViewModel()
        listener.holdNext()
        let flow = Task { await viewModel.micTapped() }
        await listener.waitUntilHolding()
        viewModel.backToTitleTapped()
        await flow.value
        #expect(listener.cancelCount == 1)
        #expect(viewModel.phase == .title)
    }

    @Test func startTapped_fromFinished_resetsCountAndStats() async {
        let viewModel = await startedViewModel()
        listener.results = [.success(["ゴリラ"]), .success(["ラッパ"])]
        await viewModel.micTapped()
        await viewModel.micTapped()
        viewModel.finishTapped()
        await viewModel.startTapped()
        #expect(viewModel.chainCount == 0)
        #expect(viewModel.stats == SessionStats())
        #expect(viewModel.listenFailures == 0)
        #expect(viewModel.heard == nil)
        #expect(viewModel.lastVerdict == nil)
        #expect(viewModel.phase == .waitingForChild)
    }

    @Test func backToTitle_returnsToTitle() async {
        let viewModel = await startedViewModel()
        viewModel.finishTapped()
        viewModel.backToTitleTapped()
        #expect(viewModel.phase == .title)
    }
}
