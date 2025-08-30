import Foundation
import Observation

/// チュートリアルの進行状況を管理するモデル
@Observable
public class TutorialState {
    /// 初回起動かどうか
    public var isFirstLaunch: Bool = true
    
    /// チュートリアルが完了しているかどうか
    public var isCompleted: Bool = false
    
    /// 現在のチュートリアルステップ
    public var currentStep: TutorialStep = .welcome
    
    /// スキップ可能かどうか
    public var canSkip: Bool = true
    
    public init() {
        AppLogger.shared.debug("TutorialState初期化")
        loadTutorialState()
    }
    
    /// 次のステップに進む
    public func nextStep() {
        AppLogger.shared.debug("次のチュートリアルステップに進む: \(currentStep)")
        
        switch currentStep {
        case .welcome:
            currentStep = .basicRules
        case .basicRules:
            currentStep = .voiceInput
        case .voiceInput:
            currentStep = .gamePlay
        case .gamePlay:
            currentStep = .tips
        case .tips:
            completeTutorial()
        }
        
        saveTutorialState()
    }
    
    /// 前のステップに戻る
    public func previousStep() {
        AppLogger.shared.debug("前のチュートリアルステップに戻る: \(currentStep)")
        
        switch currentStep {
        case .welcome:
            break // 最初のステップなので何もしない
        case .basicRules:
            currentStep = .welcome
        case .voiceInput:
            currentStep = .basicRules
        case .gamePlay:
            currentStep = .voiceInput
        case .tips:
            currentStep = .gamePlay
        }
        
        saveTutorialState()
    }
    
    /// チュートリアルをスキップ
    public func skipTutorial() {
        guard canSkip else { return }
        
        AppLogger.shared.info("チュートリアルをスキップしました")
        completeTutorial()
    }
    
    /// チュートリアルを完了
    public func completeTutorial() {
        AppLogger.shared.info("チュートリアル完了")
        isCompleted = true
        isFirstLaunch = false
        saveTutorialState()
    }
    
    /// チュートリアルをリセット（開発・デバッグ用）
    public func resetTutorial() {
        AppLogger.shared.debug("チュートリアルをリセット")
        isFirstLaunch = true
        isCompleted = false
        currentStep = .welcome
        saveTutorialState()
    }
    
    // MARK: - Private Methods
    
    /// チュートリアル状態を保存
    private func saveTutorialState() {
        UserDefaults.standard.set(isFirstLaunch, forKey: "tutorial_isFirstLaunch")
        UserDefaults.standard.set(isCompleted, forKey: "tutorial_isCompleted")
        UserDefaults.standard.set(currentStep.rawValue, forKey: "tutorial_currentStep")
        
        AppLogger.shared.debug("チュートリアル状態保存: 初回起動=\(isFirstLaunch), 完了=\(isCompleted), ステップ=\(currentStep)")
    }
    
    /// チュートリアル状態を読み込み
    private func loadTutorialState() {
        isFirstLaunch = UserDefaults.standard.object(forKey: "tutorial_isFirstLaunch") as? Bool ?? true
        isCompleted = UserDefaults.standard.bool(forKey: "tutorial_isCompleted")
        
        if let stepRawValue = UserDefaults.standard.object(forKey: "tutorial_currentStep") as? String,
           let step = TutorialStep(rawValue: stepRawValue) {
            currentStep = step
        } else {
            currentStep = .welcome
        }
        
        AppLogger.shared.debug("チュートリアル状態読み込み: 初回起動=\(isFirstLaunch), 完了=\(isCompleted), ステップ=\(currentStep)")
    }
}

/// チュートリアルのステップを定義
public enum TutorialStep: String, CaseIterable {
    case welcome = "welcome"           // ようこそ画面
    case basicRules = "basicRules"     // 基本ルール説明
    case voiceInput = "voiceInput"     // 音声入力の説明
    case gamePlay = "gamePlay"         // ゲームプレイの説明
    case tips = "tips"                 // コツ・ヒント
    
    /// ステップの表示名
    public var displayName: String {
        switch self {
        case .welcome:
            return "ようこそ"
        case .basicRules:
            return "基本ルール"
        case .voiceInput:
            return "音声入力"
        case .gamePlay:
            return "ゲームの進め方"
        case .tips:
            return "コツとヒント"
        }
    }
    
    /// ステップの説明文
    public var description: String {
        switch self {
        case .welcome:
            return "しりとりアプリへようこそ！\n楽しいしりとりゲームを始めましょう。"
        case .basicRules:
            return "しりとりの基本ルール：\n・前の単語の最後の文字で始まる単語を言う\n・「ん」で終わる単語は負け\n・同じ単語は使えません"
        case .voiceInput:
            return "音声入力機能：\n・マイクボタンを押して話すだけ\n・自動でひらがなに変換します\n・キーボードでも入力できます"
        case .gamePlay:
            return "ゲームの進め方：\n・プレイヤーを追加してゲーム開始\n・制限時間内に単語を答える\n・間違えると脱落します"
        case .tips:
            return "上達のコツ：\n・たくさんの単語を覚えよう\n・「る」「ぷ」「ず」で終わる単語は要注意\n・動物や食べ物の名前を覚えると便利"
        }
    }
    
    /// ステップのアイコン
    public var icon: String {
        switch self {
        case .welcome:
            return "hand.wave.fill"
        case .basicRules:
            return "book.fill"
        case .voiceInput:
            return "mic.fill"
        case .gamePlay:
            return "gamecontroller.fill"
        case .tips:
            return "lightbulb.fill"
        }
    }
    
    /// ステップのカラー
    public var color: String {
        switch self {
        case .welcome:
            return "blue"
        case .basicRules:
            return "green"
        case .voiceInput:
            return "purple"
        case .gamePlay:
            return "orange"
        case .tips:
            return "yellow"
        }
    }
}
