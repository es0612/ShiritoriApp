#if DEBUG
/// Xcode のプレビュー用。マイクも音も使わない部品で画面だけを確かめる。
extension PlayViewModel {
    static func preview() -> PlayViewModel {
        PlayViewModel(
            bank: WordBank(words: ["りんご", "ごりら", "らっぱ"].map { Word(reading: $0) }),
            listener: PreviewListener(),
            speaker: PreviewSpeaker()
        )
    }
}

private struct PreviewListener: SpeechListening {
    func prepare() async -> ListeningAvailability { .ready }
    func listen(hints: [String]) async throws -> [String] { [] }
}

@MainActor
private final class PreviewSpeaker: SpeechSpeaking {
    func speak(_ text: String) async {}
    func stop() {}
}
#endif
