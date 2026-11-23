/// 聞き取りが使えるかどうか。
public enum ListeningAvailability: Equatable, Sendable {
    case ready
    /// マイクか音声認識の許可が無い
    case denied
    /// この端末では、端末内の日本語認識が使えない
    case unsupported
}

/// 子供の声を聞いて、認識の候補を返す。
///
/// 画面の状態（ViewModel）はこのプロトコル越しに聞くので、テストでは即座に返る偽物に差し替えられる。
public protocol SpeechListening: Sendable {
    /// 許可を求め、端末内認識が使えるかを返す
    func prepare() async -> ListeningAvailability
    /// 聞き始め、話し終わりを検知したら認識の候補（第1候補が先頭）を返す。何も聞こえなければ空
    func listen(hints: [String]) async throws -> [String]
}

/// アプリの声。
@MainActor
public protocol SpeechSpeaking: AnyObject {
    /// 言い終わるか `stop()` されるまで待つ
    func speak(_ text: String) async
    func stop()
}
