import AVFoundation

/// OS の読み上げ（`AVSpeechSynthesizer`）でアプリの声を出す。
@MainActor
public final class SystemSpeaker: NSObject, SpeechSpeaking {
    private let synthesizer = AVSpeechSynthesizer()
    /// いま話している発話と、その終わりを待っている呼び出し元
    private var current: (id: ObjectIdentifier, continuation: CheckedContinuation<Void, Never>)?

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func speak(_ text: String) async {
        stop()
        #if os(iOS)
        // 聞き取りと同じ設定にそろえる。再生カテゴリを含むので、消音スイッチが入っていても声が出る
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? audioSession.setActive(true)
        #endif

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        // 子供が聞き取りやすいよう、標準より少しゆっくり
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        let id = ObjectIdentifier(utterance)
        // 通話や Siri の割り込みで「言い終わった」通知が届かないことがある。
        // 届かないと画面が「ちょっと まってね」のまま止まるので、長さに応じた上限で待ちを解く
        let watchdog = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3 + Double(text.count) * 0.5))
            guard !Task.isCancelled else { return }
            self?.finish(id)
        }
        await withCheckedContinuation { continuation in
            current = (id, continuation)
            synthesizer.speak(utterance)
        }
        watchdog.cancel()
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        finish(nil)
    }

    /// 待っている呼び出し元を1回だけ再開する。
    ///
    /// `id` を見るのは、止めた発話の「終わった」通知が遅れて届いたときに、
    /// 次の発話の待ちを間違って解かないため。nil は「いまの発話を無条件に終える」。
    private func finish(_ id: ObjectIdentifier?) {
        guard let current, id == nil || id == current.id else { return }
        self.current = nil
        current.continuation.resume()
    }
}

extension SystemSpeaker: AVSpeechSynthesizerDelegate {
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in self.finish(id) }
    }
}
