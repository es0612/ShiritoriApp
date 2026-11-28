import Testing
@testable import ShiritoriCore

/// 1回のあそびの状態と、その進み方
@Suite struct ShiritoriSessionTests {
    /// 「ご」で始まる言葉が5語あるので、行き止まりでないのは「りんご」だけ。
    /// そのため最初の言葉は必ず「りんご」になる。
    static let bank = WordBank(words: ["りんご", "ごま", "ごみ", "ごぼう", "ごりら", "ごむ", "らっぱ"].map { Word(reading: $0) })

    private func started(bank: WordBank = ShiritoriSessionTests.bank) -> (ShiritoriSession, SeededGenerator) {
        var rng = SeededGenerator(seed: 7)
        var session = ShiritoriSession(bank: bank)
        _ = session.start(using: &rng)
        return (session, rng)
    }

    @Test func start_putsFirstWordAndSetsHeads() {
        var rng = SeededGenerator(seed: 7)
        var session = ShiritoriSession(bank: Self.bank)
        let first = session.start(using: &rng)
        #expect(first?.reading == "りんご")
        #expect(session.heads == ["ご"])
        #expect(session.used == ["りんご"])
        #expect(session.chainCount == 0)
        #expect(session.lastAppWord?.reading == "りんご")
        #expect(!session.canUndo)
    }

    @Test func start_withEmptyBank_returnsNil() {
        var rng = SeededGenerator(seed: 7)
        var session = ShiritoriSession(bank: WordBank(words: []))
        #expect(session.start(using: &rng) == nil)
    }

    @Test func submit_accepted_incrementsChainAndMovesHeads() {
        var (session, _) = started()
        #expect(session.submit(reading: "ごりら") == .accepted)
        #expect(session.chainCount == 1)
        #expect(session.heads == ["ら"])
        #expect(session.used == ["りんご", "ごりら"])
        #expect(session.canUndo)
    }

    @Test(arguments: [("らっぱ", Verdict.wrongHead(expected: "ご")), ("ごはん", .endsWithN), ("りんご", .wrongHead(expected: "ご"))])
    func submit_rejected_countsRetryAndChangesNothingElse(reading: String, expected: Verdict) {
        var (session, _) = started()
        #expect(session.submit(reading: reading) == expected)
        #expect(session.stats == SessionStats(corrections: 0, unheard: 0, retries: 1))
        #expect(session.chainCount == 0)
        #expect(session.heads == ["ご"])
        #expect(session.used == ["りんご"])
    }

    @Test func submit_alreadyUsed_countsRetry() {
        // 辞書が「ごご」だけなので、最初の言葉は「ごご」、次に使える文字は「ご」
        var (session, _) = started(bank: WordBank(words: [Word(reading: "ごご")]))
        #expect(session.submit(reading: "ごご") == .alreadyUsed)
        #expect(session.stats == SessionStats(corrections: 0, unheard: 0, retries: 1))
        #expect(session.chainCount == 0)
    }

    @Test func submit_unreadable_countsUnheard() {
        var (session, _) = started()
        #expect(session.submit(reading: nil) == .unreadable)
        #expect(session.stats == SessionStats(corrections: 0, unheard: 1, retries: 0))
        #expect(session.chainCount == 0)
    }

    @Test func appTurn_reply_usesFirstHeadAndMovesHeads() {
        var (session, rng) = started()
        _ = session.submit(reading: "ごりら")
        #expect(session.appTurn(using: &rng) == .reply(Word(reading: "らっぱ")))
        #expect(session.heads == ["ぱ"])
        #expect(session.used.contains("らっぱ"))
        #expect(session.lastAppWord?.reading == "らっぱ")
        #expect(session.chainCount == 1)
    }

    @Test func appTurn_giveUp_whenNoCandidate_keepsChain() throws {
        var (session, rng) = started()
        _ = session.submit(reading: "ごりら")
        _ = session.appTurn(using: &rng)             // らっぱ
        _ = session.submit(reading: "ぱせり")         // heads は「り」。りんご は使用済み
        let move = session.appTurn(using: &rng)
        guard case .giveUp(let word) = move else {
            Issue.record("giveUp のはずが \(move)")
            return
        }
        #expect(["ごま", "ごみ", "ごぼう", "ごむ"].contains(word.reading))
        #expect(session.heads == ShiritoriRules.nextHeads(after: word.reading))
        #expect(session.used.contains(word.reading))
        #expect(session.chainCount == 2)
    }

    @Test func appTurn_whenBankExhausted_returnsOutOfWords() {
        var (session, rng) = started(bank: WordBank(words: [Word(reading: "りんご")]))
        _ = session.submit(reading: "ごりら")
        #expect(session.appTurn(using: &rng) == .outOfWords)
        // 状態は変わらない
        #expect(session.heads == ["ら"])
        #expect(session.used == ["りんご", "ごりら"])
        #expect(session.chainCount == 1)
    }

    @Test func undo_afterAcceptedAndReply_restoresEverything() {
        var (session, rng) = started()
        _ = session.submit(reading: "ごりら")
        _ = session.appTurn(using: &rng)
        session.undoLast()
        #expect(session.chainCount == 0)
        #expect(session.used == ["りんご"])
        #expect(session.heads == ["ご"])
        #expect(session.lastAppWord?.reading == "りんご")
        #expect(session.stats == SessionStats(corrections: 1, unheard: 0, retries: 0))
        #expect(!session.canUndo)
    }

    @Test func undo_afterRejected_restoresStatsAndCountsCorrection() {
        var (session, _) = started()
        _ = session.submit(reading: "らっぱ")
        session.undoLast()
        #expect(session.stats == SessionStats(corrections: 1, unheard: 0, retries: 0))
    }

    @Test func undo_keepsEarlierCorrections() {
        var (session, _) = started()
        _ = session.submit(reading: "らっぱ"); session.undoLast()
        _ = session.submit(reading: nil); session.undoLast()
        #expect(session.stats == SessionStats(corrections: 2, unheard: 0, retries: 0))
    }

    @Test func undo_whenNothingToUndo_doesNothing() {
        var (session, _) = started()
        session.undoLast()
        #expect(session.stats == SessionStats())
        #expect(session.heads == ["ご"])
    }

    @Test func start_again_resetsEverything() {
        var (session, rng) = started()
        _ = session.submit(reading: "らっぱ")
        _ = session.submit(reading: "ごりら")
        _ = session.start(using: &rng)
        #expect(session.chainCount == 0)
        #expect(session.stats == SessionStats())
        #expect(session.used == ["りんご"])
        #expect(!session.canUndo)
    }

    // MARK: - つながり（画面に出す、出た言葉の並び）

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

    /// 言い直しになった言葉（最初の文字が違う・「ん」で終わる・既に出た・読めない）は並びに入れない
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

    @Test func chain_giveUp_restartsFromNewWord() {
        // 「ぱせり」の「り」で始まる、まだ出ていない言葉が辞書に無いので「まいった」になる
        var (session, rng) = started()
        _ = session.submit(reading: "ごりら")
        _ = session.appTurn(using: &rng)                 // らっぱ
        _ = session.submit(reading: "ぱせり")
        guard case .giveUp(let word) = session.appTurn(using: &rng) else {
            Issue.record("まいったにならない")
            return
        }
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
}
