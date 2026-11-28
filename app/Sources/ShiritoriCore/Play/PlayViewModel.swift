import Observation

/// あそぶ画面の状態と、操作に対する動き。
///
/// 旧版は状態が複数の管理クラスとタイマーに散らばり、「ターンが切り替わらない」などの
/// 不具合が収まらなかった。ここでは状態を `phase` 1つにまとめ、待つ処理（聞く・話す）は
/// プロトコル越しに呼ぶ。テストでは偽物を渡して、時間を待たずに全経路を確かめる。
@MainActor
@Observable
public final class PlayViewModel {
    public enum Phase: Equatable, Sendable {
        case title
        /// 許可が無い、または端末が非対応で、あそべない
        case unavailable(ListeningAvailability)
        case appSpeaking
        case waitingForChild
        case listening
        case finished
    }

    public private(set) var phase: Phase = .title
    /// いま場に出ているアプリの言葉
    public private(set) var appWord: Word?
    /// 子供が次に使う文字
    public private(set) var headLabel = ""
    /// 認識エンジンが返した文字列そのまま（「車」のように漢字のことがある）。ログと確認用
    public private(set) var heard: String?
    /// 「きこえた」として画面に出す読み（ひらがな）
    public private(set) var heardReading: String?
    public private(set) var lastVerdict: Verdict?
    public private(set) var chainCount = 0
    /// 画面に出す言葉のつながり（直近 3 つ）。親子が往復を目で追えるようにする（M1.5）
    public private(set) var recentChain: [String] = []
    public private(set) var stats = SessionStats()
    /// 聞き取りを始められなかった回数（通話中、音声エンジンの起動失敗など）。「聞こえなかった」とは分けて数える
    public private(set) var listenFailures = 0
    /// 「ちがうよ」を押せるか。直前の聞き取りがあり、次のマイクをまだ押していないとき
    public private(set) var canUndo = false

    private var session: ShiritoriSession
    private let bank: WordBank
    private let listener: any SpeechListening
    private let speaker: any SpeechSpeaking
    private var random: AnyRandom

    /// 進行中の流れの世代。「ちがうよ」「おしまい」などで流れを打ち切るたびに増やす。
    /// 待ち（聞く・話す）から戻ったとき、世代が変わっていたら、その流れは何も書き換えずに終わる。
    private var generation = 0
    /// 進行中の聞き取り。流れを打ち切るときにキャンセルして、マイクをすぐ離す
    private var listenTask: Task<[String], Error>?

    public init(
        bank: WordBank,
        listener: any SpeechListening,
        speaker: any SpeechSpeaking,
        randomSource: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.bank = bank
        self.listener = listener
        self.speaker = speaker
        self.session = ShiritoriSession(bank: bank)
        self.random = AnyRandom(base: randomSource)
    }

    // MARK: - 操作

    /// 「はじめる」「もういっかい」。許可を確かめ、最初の言葉を言って子供の番にする。
    public func startTapped() async {
        switch phase {
        case .title, .finished, .unavailable: break
        case .appSpeaking, .waitingForChild, .listening: return
        }
        let flow = beginFlow()

        let availability = await listener.prepare()
        guard isCurrent(flow) else { return }
        guard availability == .ready else {
            AppLog.play.info("あそべない: \(String(describing: availability), privacy: .public)")
            phase = .unavailable(availability)
            return
        }

        heard = nil
        heardReading = nil
        lastVerdict = nil
        canUndo = false
        listenFailures = 0
        guard let first = session.start(using: &random) else {
            // 辞書が空。同梱の辞書では起きないが、落とさずに終える
            syncFromSession()
            await say(Phrases.outOfWords)
            guard isCurrent(flow) else { return }
            setPhase(.finished)
            return
        }
        syncFromSession()
        await say(Phrases.appWord(first.reading))
        guard isCurrent(flow) else { return }
        setPhase(.waitingForChild)
    }

    /// マイクボタン。子供の番のときだけ動く（連打や、アプリが話している最中の操作は無視する）。
    public func micTapped() async {
        guard phase == .waitingForChild else { return }
        let flow = beginFlow()
        canUndo = false
        setPhase(.listening)

        let heads = session.heads
        // 聞き取りは別のタスクにして持っておく。「おしまい」などで流れを打ち切るときに
        // キャンセルできないと、画面を離れたあとも数秒マイクが開いたままになる
        let listener = self.listener
        let hints = bank.hints(for: heads)
        let task = Task { try await listener.listen(hints: hints) }
        listenTask = task
        let candidates: [String]
        do {
            candidates = try await task.value
        } catch {
            guard isCurrent(flow) else { return }
            // 通話の割り込みなどで聞き取りを始められなかった。固まらせず、子供の番に戻す。
            // 「聞こえなかった」とは区別する（子供のせいではなく、聞き取れずの数も汚さないため）
            AppLog.play.error("聞き取り失敗: \(String(describing: error), privacy: .public)")
            listenTask = nil
            listenFailures += 1
            heard = nil
            heardReading = nil
            lastVerdict = nil
            await say(Phrases.cannotListen)
            guard isCurrent(flow) else { return }
            setPhase(.waitingForChild)
            return
        }
        guard isCurrent(flow) else { return }
        listenTask = nil

        let best = ReadingExtractor.best(from: candidates, heads: heads)
        let verdict = session.submit(reading: best?.reading)
        heard = best?.heard
        heardReading = best?.reading
        lastVerdict = verdict
        canUndo = true
        syncFromSession()
        AppLog.play.debug("判定: きこえた=\(best?.heard ?? "（なし）", privacy: .public) 読み=\(best?.reading ?? "（なし）", privacy: .public) → \(String(describing: verdict), privacy: .public)")

        await say(phrase(for: verdict, reading: best?.reading))
        guard isCurrent(flow) else { return }

        if verdict == .accepted {
            await appTurn(flow)
        } else {
            setPhase(.waitingForChild)
        }
    }

    /// 「ちがうよ」。直前の聞き取りを無かったことにして、言い直してもらう。
    public func undoTapped() {
        guard canUndo, phase == .appSpeaking || phase == .waitingForChild else { return }
        _ = beginFlow()          // 進行中の返事を打ち切る
        speaker.stop()
        session.undoLast()
        heard = nil
        heardReading = nil
        lastVerdict = nil
        canUndo = false
        syncFromSession()
        setPhase(.waitingForChild)
    }

    /// 「おしまい」。あそんでいる間いつでも押せる。
    public func finishTapped() {
        switch phase {
        case .appSpeaking, .waitingForChild, .listening: break
        case .title, .unavailable, .finished: return
        }
        _ = beginFlow()
        speaker.stop()
        canUndo = false
        setPhase(.finished)
    }

    public func backToTitleTapped() {
        _ = beginFlow()
        speaker.stop()
        setPhase(.title)
    }

    // MARK: - 流れ

    /// アプリの番。続きの言葉を言う。思いつかなければ「まいった！」、辞書を使い切っていたら終わる。
    private func appTurn(_ flow: Int) async {
        let move = session.appTurn(using: &random)
        AppLog.play.debug("アプリの番: \(String(describing: move), privacy: .public)")
        switch move {
        case .reply(let word):
            syncFromSession()
            await say(Phrases.appWord(word.reading))
        case .giveUp(let word):
            await say(Phrases.giveUp)
            guard isCurrent(flow) else { return }
            syncFromSession()
            await say(Phrases.appWord(word.reading))
        case .outOfWords:
            await say(Phrases.outOfWords)
            guard isCurrent(flow) else { return }
            canUndo = false
            setPhase(.finished)
            return
        }
        guard isCurrent(flow) else { return }
        setPhase(.waitingForChild)
    }

    private func say(_ text: String) async {
        setPhase(.appSpeaking)
        await speaker.speak(text)
    }

    /// 判定への反応。聞き取った読みを頭に付けて言い返し、子供の言葉を受けてから続ける（M1.5）。
    /// 漢字で返った認識結果（「車」）ではなく、ひらがなの読み（「くるま」）を使う
    private func phrase(for verdict: Verdict, reading: String?) -> String {
        let reaction: String
        switch verdict {
        case .unreadable: return Phrases.askAgain
        case .accepted:
            // accepted は読みがあるときだけ出る。万一無いときは、空文字を話して待たせないよう M1 の言い方に戻す
            return reading.map(Phrases.accepted) ?? "\(session.chainCount)かいめ！"
        case .wrongHead(let expected): reaction = Phrases.wrongHead(expected)
        case .endsWithN: reaction = Phrases.endsWithN
        case .alreadyUsed: reaction = Phrases.alreadyUsed
        }
        return reading.map { Phrases.echoed($0, reaction) } ?? reaction
    }

    private func beginFlow() -> Int {
        listenTask?.cancel()
        listenTask = nil
        generation += 1
        return generation
    }

    private func isCurrent(_ flow: Int) -> Bool {
        flow == generation
    }

    private func setPhase(_ newPhase: Phase) {
        guard phase != newPhase else { return }
        AppLog.play.debug("状態: \(String(describing: self.phase), privacy: .public) → \(String(describing: newPhase), privacy: .public)")
        phase = newPhase
    }

    /// 画面に出す値を、あそびの状態から写す
    private func syncFromSession() {
        appWord = session.lastAppWord
        headLabel = session.heads.first ?? ""
        chainCount = session.chainCount
        recentChain = Array(session.chain.suffix(3))
        stats = session.stats
    }
}

/// 乱数の実体を包む。テストでは種を固定した乱数を、本番では OS の乱数を渡す。
private struct AnyRandom: RandomNumberGenerator {
    var base: any RandomNumberGenerator

    mutating func next() -> UInt64 {
        base.next()
    }
}
