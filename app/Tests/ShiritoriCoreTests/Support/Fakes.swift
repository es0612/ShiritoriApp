@testable import ShiritoriCore

/// テスト用の「聞く」。決めておいた結果を順に、待たずに返す。
/// テストは MainActor 上で順に触るだけなので、検査を外している。
final class FakeListener: SpeechListening, @unchecked Sendable {
    struct Failure: Error {}

    var availability: ListeningAvailability = .ready
    /// `listen` が呼ばれるたびに先頭から1つずつ返す。尽きたら空の候補
    var results: [Result<[String], Error>] = []
    private(set) var listenCount = 0
    private(set) var cancelCount = 0
    private(set) var receivedHints: [[String]] = []
    private var shouldHoldNext = false
    private var held: CheckedContinuation<Void, Never>?

    /// 次の `listen` を、キャンセルか `release()` まで終わらせない（「聞いている最中」を作る）
    func holdNext() { shouldHoldNext = true }
    var isHolding: Bool { held != nil }

    func prepare() async -> ListeningAvailability { availability }

    func listen(hints: [String]) async throws -> [String] {
        listenCount += 1
        receivedHints.append(hints)
        if shouldHoldNext {
            shouldHoldNext = false
            await withTaskCancellationHandler {
                await withCheckedContinuation { held = $0 }
            } onCancel: {
                cancelCount += 1
                release()
            }
        }
        guard !results.isEmpty else { return [] }
        return try results.removeFirst().get()
    }

    func release() {
        held?.resume()
        held = nil
    }

    /// `listen` が待ち状態に入るまで待つ
    @MainActor func waitUntilHolding() async {
        while !isHolding { await Task.yield() }
    }
}

/// テスト用の「話す」。言った文を記録するだけで、音は出さない。
@MainActor
final class FakeSpeaker: SpeechSpeaking {
    private(set) var spoken: [String] = []
    private(set) var stopCount = 0
    private var shouldHoldNext = false
    private var held: CheckedContinuation<Void, Never>?

    /// 次の `speak` を、`stop()` か `release()` まで終わらせない（「話している最中」を作る）
    func holdNext() { shouldHoldNext = true }
    var isHolding: Bool { held != nil }

    func speak(_ text: String) async {
        spoken.append(text)
        guard shouldHoldNext else { return }
        shouldHoldNext = false
        await withCheckedContinuation { held = $0 }
    }

    func stop() {
        stopCount += 1
        release()
    }

    func release() {
        held?.resume()
        held = nil
    }

    /// `speak` が待ち状態に入るまで待つ
    func waitUntilHolding() async {
        while !isHolding { await Task.yield() }
    }
}
