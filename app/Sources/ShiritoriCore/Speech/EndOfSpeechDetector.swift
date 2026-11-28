import Foundation

/// 子供が話し終わったかどうかを、途中結果の変化から判定する（設計書 §5.5）。
///
/// 時刻を引数で受け取るので、テストでは実際に待たずに確かめられる。
public struct EndOfSpeechDetector: Sendable {
    private let silence: TimeInterval
    private let maximum: TimeInterval
    private let startedAt: TimeInterval
    private var lastText = ""
    private var lastChangeAt: TimeInterval?

    /// - Parameters:
    ///   - silence: 何か聞こえたあと、途中結果がこの秒数変わらなければ話し終わりとみなす
    ///   - maximum: 開始からこの秒数たったら、話していても打ち切る
    public init(silence: TimeInterval = 1.2, maximum: TimeInterval = 6.0, startedAt: TimeInterval) {
        self.silence = silence
        self.maximum = maximum
        self.startedAt = startedAt
    }

    /// 途中結果が届いたときに呼ぶ。同じ文字列なら「変化なし」として扱う。
    public mutating func textChanged(_ text: String, at time: TimeInterval) {
        guard !text.isEmpty, text != lastText else { return }
        lastText = text
        lastChangeAt = time
    }

    /// 話し終わりとみなした理由。記録に残し、言いかけで切れていないかを後から確かめる
    public enum FinishReason: String, Sendable {
        /// 何か聞こえたあと、途中結果が変わらなくなった
        case silence
        /// 開始から最長の秒数がたった
        case maximum
    }

    public func shouldFinish(at time: TimeInterval) -> Bool {
        finishReason(at: time) != nil
    }

    /// 話し終わりなら、その理由。まだなら nil。最長を先に見る（話している途中でも打ち切るため）
    public func finishReason(at time: TimeInterval) -> FinishReason? {
        if time - startedAt >= maximum { return .maximum }
        guard let lastChangeAt else { return nil }
        return time - lastChangeAt >= silence ? .silence : nil
    }
}
