import AVFoundation
import Foundation
import Speech

/// `SFSpeechRecognizer` の端末内認識で聞き取る。
///
/// 子供の声を端末の外に送らないよう、`requiresOnDeviceRecognition = true` を必ず付ける。
/// 状態を持たない（1回の聞き取りに必要なものはすべて `listen` の中のローカル変数）ので、
/// どのスレッドから呼んでも安全。
public final class OnDeviceSpeechListener: SpeechListening {
    public enum ListeningError: Error {
        case recognizerUnavailable
        /// マイクの入力が使えない（経路の切り替え直後、マイクの無い環境など）
        case noInput
    }

    /// 聞き取り中に起きる出来事。音声スレッドや認識のコールバックから、1本の流れにまとめて受け取る
    private enum Event: Sendable {
        case heard(candidates: [String], isFinal: Bool)
        case failed
        case tick
    }

    private static let locale = Locale(identifier: "ja-JP")
    /// 話し終わりとみなして録音を止めたあと、最終結果を待つ上限
    private static let finalResultTimeout: TimeInterval = 1.5

    public init() {}

    public func prepare() async -> ListeningAvailability {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        let microphoneGranted = await AVAudioApplication.requestRecordPermission()
        guard speechStatus == .authorized, microphoneGranted else {
            AppLog.speech.info("聞き取りの許可なし: speech=\(speechStatus.rawValue) mic=\(microphoneGranted)")
            return .denied
        }
        guard let recognizer = SFSpeechRecognizer(locale: Self.locale), recognizer.supportsOnDeviceRecognition else {
            AppLog.speech.info("端末内の日本語認識に非対応")
            return .unsupported
        }
        return .ready
    }

    public func listen(hints: [String]) async throws -> [String] {
        guard let recognizer = SFSpeechRecognizer(locale: Self.locale), recognizer.isAvailable else {
            throw ListeningError.recognizerUnavailable
        }

        #if os(iOS)
        // アプリの声（再生）と聞き取り（録音）を同じ設定で行う。再生カテゴリを含むので消音スイッチでも声が出る
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)
        #endif

        // request は音声スレッド（append）とこの関数（endAudio）の両方から触る。
        // Speech フレームワークがその使い方を前提にしているので、コンパイラの検査だけ外す
        nonisolated(unsafe) let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        request.addsPunctuation = false
        request.contextualStrings = hints

        let (events, continuation) = AsyncStream.makeStream(of: Event.self)

        let engine = AVAudioEngine()
        let input = engine.inputNode
        // 入力の形式が無効なまま tap を付けると、Swift では捕まえられない例外でアプリが落ちる。先に確かめて投げる
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else { throw ListeningError.noInput }
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        let task = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                continuation.yield(.heard(candidates: result.transcriptions.map(\.formattedString), isFinal: result.isFinal))
            } else if error != nil {
                // 「何も聞こえなかった」もエラーとして届く。呼び出し側には空の候補として返す
                continuation.yield(.failed)
            }
        }
        // 途中結果が届かない間も、話し終わりの判定を進めるための刻み
        let ticker = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                continuation.yield(.tick)
            }
        }
        // 成功・失敗・キャンセルのどれで抜けても、必ずマイクを離す
        defer {
            ticker.cancel()
            continuation.finish()
            engine.stop()
            input.removeTap(onBus: 0)
            task.cancel()
            // 認識器が聞き取りの途中で解放されないよう、ここまで生かしておく
            withExtendedLifetime(recognizer) {}
        }

        engine.prepare()
        try engine.start()
        AppLog.speech.debug("聞き取り開始: ヒント \(hints.count) 語")

        var detector = EndOfSpeechDetector(startedAt: Self.now)
        var candidates: [String] = []
        var audioEndedAt: TimeInterval?

        loop: for await event in events {
            switch event {
            case .heard(let heard, let isFinal):
                // 終わり際に空の結果が届くことがある。聞こえていた途中結果を消さない
                if !heard.isEmpty { candidates = heard }
                detector.textChanged(heard.first ?? "", at: Self.now)
                if isFinal { break loop }
            case .failed:
                break loop
            case .tick:
                if let audioEndedAt {
                    // 録音を止めたのに最終結果が来ない。途中結果のまま返す
                    if Self.now - audioEndedAt >= Self.finalResultTimeout { break loop }
                } else if detector.shouldFinish(at: Self.now) {
                    // 話し終わり。マイクをすぐ離し、あとは最終結果を待つだけにする
                    request.endAudio()
                    engine.stop()
                    input.removeTap(onBus: 0)
                    audioEndedAt = Self.now
                }
            }
        }
        AppLog.speech.debug("聞き取り終了: 候補 \(candidates.count) 件 先頭=\(candidates.first ?? "（なし）", privacy: .public)")
        return candidates
    }

    private static var now: TimeInterval { ProcessInfo.processInfo.systemUptime }
}
