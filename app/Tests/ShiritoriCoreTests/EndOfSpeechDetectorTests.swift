import Testing
@testable import ShiritoriCore

/// 話し終わりの判定（設計書 §5.5: 途中結果が1.2秒変わらなければ話し終わり。最長6秒）
@Suite struct EndOfSpeechDetectorTests {
    @Test func finishesAfterSilenceOnceSomethingWasHeard() {
        var detector = EndOfSpeechDetector(startedAt: 0)
        #expect(!detector.shouldFinish(at: 3.0))        // まだ何も聞こえていない
        detector.textChanged("ご", at: 1.0)
        detector.textChanged("ごりら", at: 1.5)
        #expect(!detector.shouldFinish(at: 2.6))
        #expect(detector.shouldFinish(at: 2.7))
    }

    @Test func sameTextDoesNotExtendSilence() {
        var detector = EndOfSpeechDetector(startedAt: 0)
        detector.textChanged("ご", at: 1.0)
        detector.textChanged("ご", at: 2.0)
        #expect(detector.shouldFinish(at: 2.2))
    }

    @Test func emptyTextDoesNotCountAsHeard() {
        var detector = EndOfSpeechDetector(startedAt: 0)
        detector.textChanged("", at: 1.0)
        #expect(!detector.shouldFinish(at: 3.0))
    }

    @Test func finishesAtMaximumEvenWithoutSpeech() {
        let detector = EndOfSpeechDetector(startedAt: 0)
        #expect(!detector.shouldFinish(at: 5.9))
        #expect(detector.shouldFinish(at: 6.0))
    }

    @Test func finishesAtMaximumEvenWhileStillTalking() {
        var detector = EndOfSpeechDetector(startedAt: 10)
        detector.textChanged("ながいながい", at: 15.5)
        #expect(detector.shouldFinish(at: 16.0))
    }
}
