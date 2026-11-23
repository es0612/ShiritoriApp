import Testing
@testable import ShiritoriCore

@Test func packageBuildsAndLogsExist() {
    _ = AppLog.rules
    _ = AppLog.session
    _ = AppLog.speech
    _ = AppLog.play
}
