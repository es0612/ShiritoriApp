import Testing
@testable import ShiritoriCore

/// 聞き取りが終わった理由の記録（M1.5）。後から H2（言いかけで切れる）を数えるので、
/// 「誰が止めたか」と「そのあと何が起きたか」を取り違えずに残す。
@Suite struct ListeningEndReasonTests {
    @Test func cancelledBeforeAnything_isRecordedAsInterrupted() {
        // 「おしまい」などで流れを打ち切ると、何の出来事も無いまま終わる
        let reason = ListeningEndReason()
        #expect(reason.text == "中断")
        #expect(!reason.gotFinal)
    }

    @Test func finalWithoutDetector_isFinalResult() {
        var reason = ListeningEndReason()
        reason.finalArrived()
        #expect(reason.text == "最終結果")
        #expect(reason.gotFinal)
    }

    @Test func finalAfterSilence_keepsSilence() {
        var reason = ListeningEndReason()
        reason.detectorFinished(.silence)
        reason.finalArrived()
        #expect(reason.text == "話し終わり")
        #expect(reason.gotFinal)
    }

    @Test func errorAfterDetector_keepsWhoStopped() {
        var reason = ListeningEndReason()
        reason.detectorFinished(.silence)
        reason.failed()
        #expect(reason.text == "話し終わり→エラー")
    }

    @Test func errorAlone_isError() {
        var reason = ListeningEndReason()
        reason.failed()
        #expect(reason.text == "エラー")
    }

    @Test func timeoutAfterMaximum_keepsBoth() {
        var reason = ListeningEndReason()
        reason.detectorFinished(.maximum)
        reason.timedOut()
        #expect(reason.text == "最長→最終結果待ちの打ち切り")
        #expect(!reason.gotFinal)
    }
}
