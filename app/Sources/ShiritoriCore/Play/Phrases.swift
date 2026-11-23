/// アプリが言う・見せる台詞（設計書 §5.3）。すべてひらがな。
///
/// 間違いを責める言い方はしない。言い直しを促すだけにする。
public enum Phrases {
    /// アプリの言葉は、読みをそのまま言う
    public static func appWord(_ reading: String) -> String { reading }
    public static func nextHead(_ head: String) -> String { "つぎは 「\(head)」 から！" }
    public static let askAgain = "もういちど いってね"
    /// 聞き取りそのものが始められなかったとき（通話中など）。子供のせいではないので、言い方を分ける
    public static let cannotListen = "いまは きけないみたい。もういちど おしてね"
    public static func wrongHead(_ head: String) -> String { "「\(head)」から だよ" }
    public static let endsWithN = "「ん」が ついちゃった！ もういっかい"
    public static let alreadyUsed = "それ もう いったよ"
    public static func accepted(_ count: Int) -> String { "\(count)かいめ！" }
    public static let giveUp = "まいった！"
    public static let outOfWords = "ことばが なくなっちゃった！"
    public static func finished(_ count: Int) -> String { "\(count)かい つながったね！" }
}
