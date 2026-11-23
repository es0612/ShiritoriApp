import os

/// アプリ全体で使うログの入口。
///
/// 記録するのは、状態遷移・判定・聞き取りの開始と結果・エラーだけ。
/// 旧版は全タップやアニメーションまで記録してログ呼び出しが500か所を超え、
/// 肝心の流れが追いにくくなったので、対象を絞っている。
public enum AppLog {
    private static let subsystem = "com.asapapalab.ShiritoriApp"

    /// しりとりのルール（つなぎ方・判定）
    public static let rules = Logger(subsystem: subsystem, category: "rules")
    /// 1回のあそびの状態
    public static let session = Logger(subsystem: subsystem, category: "session")
    /// 聞く・話す
    public static let speech = Logger(subsystem: subsystem, category: "speech")
    /// 画面の状態
    public static let play = Logger(subsystem: subsystem, category: "play")
}
