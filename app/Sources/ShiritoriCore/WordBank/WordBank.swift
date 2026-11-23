import Foundation

/// アプリが返事に使う言葉の集まりと、その選び方（設計書 §5.6）。
///
/// 子供の言葉の判定には使わない。辞書にない言葉も受け入れるため。
public struct WordBank: Sendable {
    public let words: [Word]

    /// 行き止まりの言葉（読みの集合）。先に計算しておく。
    private let deadEnds: Set<String>

    /// 続く言葉がこの数より少ない文字で終わる言葉は「行き止まり」とみなす
    private static let minimumContinuations = 5
    private static let maximumHints = 100

    public init(words: [Word]) {
        self.words = words
        self.deadEnds = Set(words.map(\.reading).filter { reading in
            // その言葉のあと、アプリ自身が続けるときに使う文字（先頭の候補）で数える
            guard let head = ShiritoriRules.nextHeads(after: reading).first else { return true }
            return words.count { $0.reading.hasPrefix(head) } < Self.minimumContinuations
        })
    }

    /// `heads` の先頭の文字で始まる、まだ出ていない言葉を選ぶ。
    ///
    /// 行き止まりの言葉（例: 「る」で終わる）は、ほかに候補があれば避ける。子供を詰まらせないため。
    public func pick<R: RandomNumberGenerator>(heads: [String], used: Set<String>, using rng: inout R) -> Word? {
        guard let head = heads.first else { return nil }
        return choose(from: words.filter { $0.reading.hasPrefix(head) && !used.contains($0.reading) }, using: &rng)
    }

    /// 文字を問わず、まだ出ていない言葉を選ぶ。最初の言葉と「まいった！」のあとの再開に使う。
    public func pickAny<R: RandomNumberGenerator>(used: Set<String>, using rng: inout R) -> Word? {
        choose(from: words.filter { !used.contains($0.reading) }, using: &rng)
    }

    /// 音声認識へ渡すヒント。`heads` のどれかで始まる読みを最大100語。
    public func hints(for heads: [String]) -> [String] {
        Array(words.map(\.reading).filter { ShiritoriRules.starts($0, withAnyOf: heads) }.prefix(Self.maximumHints))
    }

    private func choose<R: RandomNumberGenerator>(from candidates: [Word], using rng: inout R) -> Word? {
        let open = candidates.filter { !deadEnds.contains($0.reading) }
        return (open.isEmpty ? candidates : open).randomElement(using: &rng)
    }
}

extension WordBank {
    public enum LoadError: Error {
        case resourceNotFound
    }

    /// アプリに同梱した辞書（`Resources/words.json`）を読み込む。
    public static func bundled() throws -> WordBank {
        guard let url = Bundle.module.url(forResource: "words", withExtension: "json") else {
            throw LoadError.resourceNotFound
        }
        let words = try JSONDecoder().decode([Word].self, from: Data(contentsOf: url))
        return WordBank(words: words)
    }
}
