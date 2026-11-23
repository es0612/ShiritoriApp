/// 辞書の1語。アプリが返事に使う言葉。
public struct Word: Codable, Equatable, Hashable, Sendable {
    /// 読み（ひらがな）。画面にも読み上げにもこれを使う
    public let reading: String
    /// 言葉に添える絵文字。無くてもよい
    public let emoji: String?

    public init(reading: String, emoji: String? = nil) {
        self.reading = reading
        self.emoji = emoji
    }
}
