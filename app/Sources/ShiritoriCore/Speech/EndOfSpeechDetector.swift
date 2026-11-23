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

    public func shouldFinish(at time: TimeInterval) -> Bool {
        if time - startedAt >= maximum { return true }
        guard let lastChangeAt else { return false }
        return time - lastChangeAt >= silence
    }
}
