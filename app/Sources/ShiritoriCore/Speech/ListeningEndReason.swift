/// 聞き取りが終わった理由。記録に残して、後から「言いかけで切れていないか」（#11 の H2）を数える。
///
/// 誰が録音を止めたか（話し終わりの判定・最長）と、そのあと認識器から何が来たか（最終結果・エラー・待ちの打ち切り）を
/// 取り違えないよう、止めた理由を先に持ち、あとの出来事は「→」でつなぐ。何も起きずに終わったら「中断」。
public struct ListeningEndReason: Sendable {
    public private(set) var text = "中断"
    /// 認識器の最終結果を受け取ったか（受け取れずに途中結果で返したなら false）
    public private(set) var gotFinal = false
    /// 話し終わりの判定（または最長）で録音を止めたか
    private var stoppedByDetector = false

    public init() {}

    public mutating func detectorFinished(_ reason: EndOfSpeechDetector.FinishReason) {
        text = reason == .silence ? "話し終わり" : "最長"
        stoppedByDetector = true
    }

    public mutating func finalArrived() {
        gotFinal = true
        if !stoppedByDetector { text = "最終結果" }
    }

    public mutating func failed() {
        text = stoppedByDetector ? text + "→エラー" : "エラー"
    }

    public mutating func timedOut() {
        text += "→最終結果待ちの打ち切り"
    }
}
