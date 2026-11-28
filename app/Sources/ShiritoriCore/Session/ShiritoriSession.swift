/// オーナーが TestFlight で記録する物差し（設計書 §9）。
public struct SessionStats: Equatable, Sendable {
    /// 「ちがうよ」を押した回数（聞き間違い）
    public var corrections: Int
    /// 「もういちど いってね」が出た回数（聞き取れず）
    public var unheard: Int
    /// 言い直しになった回数（最初の文字が違う・「ん」で終わる・既に出た）
    public var retries: Int

    public init(corrections: Int = 0, unheard: Int = 0, retries: Int = 0) {
        self.corrections = corrections
        self.unheard = unheard
        self.retries = retries
    }
}

/// アプリの番の結果。
public enum AppMove: Equatable, Sendable {
    /// 続きの言葉を返す
    case reply(Word)
    /// 続きが思いつかない。「まいった！」と言って、別の文字で始まるこの言葉から再開する
    case giveUp(Word)
    /// 辞書を使い切った。あそびを終える
    case outOfWords
}

/// 1回のあそびの状態。値型なので、テストでは時間や画面なしに進められる。
///
/// 勝ち負けは無い。持っているのは「次に使える文字・出た言葉・回数」だけ。
public struct ShiritoriSession: Sendable {
    /// 取り消し（「ちがうよ」）で戻すための、ある時点の状態
    private struct Snapshot: Sendable {
        var heads: [String]
        var used: Set<String>
        var chainCount: Int
        var stats: SessionStats
        var lastAppWord: Word?
        /// 最後の `start` か「まいった」から、出た言葉の読みを出た順に。画面のつながりの表示に使う
        var chain: [String]
    }

    private let bank: WordBank
    private var current = Snapshot(heads: [], used: [], chainCount: 0, stats: SessionStats(), lastAppWord: nil, chain: [])
    /// 直前の `submit` の前の状態。取り消せるのは1回ぶんだけ
    private var checkpoint: Snapshot?

    public init(bank: WordBank) {
        self.bank = bank
    }

    /// 子供が次に使える最初の文字。先頭がアプリの返事にも使う候補
    public var heads: [String] { current.heads }
    public var used: Set<String> { current.used }
    /// 子供が正しく言えた回数。アプリの言葉は数えない
    public var chainCount: Int { current.chainCount }
    public var stats: SessionStats { current.stats }
    public var lastAppWord: Word? { current.lastAppWord }
    /// 出た言葉の並び（子供の言葉は受け入れたものだけ）。取り消すと、ほかの状態と一緒に戻る
    public var chain: [String] { current.chain }
    public var canUndo: Bool { checkpoint != nil }

    /// 最初の言葉を選んで場に出す。前のあそびの状態は消える。辞書が空なら nil。
    public mutating func start<R: RandomNumberGenerator>(using rng: inout R) -> Word? {
        current = Snapshot(heads: [], used: [], chainCount: 0, stats: SessionStats(), lastAppWord: nil, chain: [])
        checkpoint = nil
        guard let word = bank.pickAny(used: [], using: &rng) else { return nil }
        place(word)
        return word
    }

    /// 子供の言葉を判定して状態を進める。
    ///
    /// 言い直しになる判定では回数を減らさない。間違いで損をさせないため。
    public mutating func submit(reading: String?) -> Verdict {
        checkpoint = current
        let verdict = ShiritoriRules.judge(reading: reading, heads: current.heads, used: current.used)
        switch verdict {
        case .accepted:
            // judge が accepted を返すのは reading が非 nil のときだけ
            if let reading {
                current.chainCount += 1
                current.used.insert(reading)
                current.heads = ShiritoriRules.nextHeads(after: reading)
                current.chain.append(reading)
            }
        case .unreadable:
            current.stats.unheard += 1
        case .wrongHead, .endsWithN, .alreadyUsed:
            current.stats.retries += 1
        }
        return verdict
    }

    /// アプリの番。続きの言葉が無ければ「まいった」、辞書を使い切っていれば `outOfWords`。
    public mutating func appTurn<R: RandomNumberGenerator>(using rng: inout R) -> AppMove {
        if let word = bank.pick(heads: current.heads, used: current.used, using: &rng) {
            place(word)
            return .reply(word)
        }
        if let word = bank.pickAny(used: current.used, using: &rng) {
            // つながりが切れたので、表示は新しい言葉から始め直す
            current.chain = []
            place(word)
            return .giveUp(word)
        }
        return .outOfWords
    }

    /// 直前の `submit`（と、それに続いた `appTurn`）を無かったことにする。聞き間違いを直す手段。
    public mutating func undoLast() {
        guard let checkpoint else { return }
        // 取り消した submit が増やした統計は元に戻し、聞き間違いとして1回数える
        current = checkpoint
        current.stats.corrections += 1
        self.checkpoint = nil
    }

    private mutating func place(_ word: Word) {
        current.used.insert(word.reading)
        current.heads = ShiritoriRules.nextHeads(after: word.reading)
        current.lastAppWord = word
        current.chain.append(word.reading)
    }
}
