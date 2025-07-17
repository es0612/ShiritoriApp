import Foundation

/// チュートリアル管理のシングルトンクラス
public class TutorialManager: ObservableObject {
    public static let shared = TutorialManager()
    
    @Published public var shouldShowTutorial: Bool = false
    @Published public var tutorialState: TutorialState
    
    private init() {
        AppLogger.shared.debug("TutorialManager初期化")
        self.tutorialState = TutorialState()
        self.shouldShowTutorial = tutorialState.isFirstLaunch && !tutorialState.isCompleted
        AppLogger.shared.info("TutorialManager初期化完了: チュートリアル表示=\(shouldShowTutorial)")
    }
    
    /// チュートリアルの表示状態を確認
    public func checkTutorialStatus() {
        AppLogger.shared.debug("チュートリアル状態確認")
        shouldShowTutorial = tutorialState.isFirstLaunch && !tutorialState.isCompleted
        AppLogger.shared.info("チュートリアル状態確認結果: 表示=\(shouldShowTutorial), 初回起動=\(tutorialState.isFirstLaunch), 完了=\(tutorialState.isCompleted)")
    }
    
    /// チュートリアルを開始
    public func startTutorial() {
        AppLogger.shared.info("チュートリアル開始")
        tutorialState.currentStep = .welcome
        shouldShowTutorial = true
    }
    
    /// チュートリアルを完了
    public func completeTutorial() {
        AppLogger.shared.info("TutorialManagerでチュートリアル完了処理")
        tutorialState.completeTutorial()
        shouldShowTutorial = false
    }
    
    /// チュートリアルをリセット（開発・デバッグ用）
    public func resetTutorial() {
        AppLogger.shared.info("TutorialManagerでチュートリアルリセット")
        tutorialState.resetTutorial()
        shouldShowTutorial = true
    }
    
    /// 強制的にチュートリアルを非表示
    public func dismissTutorial() {
        AppLogger.shared.info("チュートリアル強制非表示")
        shouldShowTutorial = false
    }
}

// MARK: - App Integration Helper

public extension TutorialManager {
    /// アプリ起動時の初期化処理
    func initializeOnAppLaunch() {
        AppLogger.shared.debug("アプリ起動時チュートリアル初期化")
        checkTutorialStatus()
        
        // 初回起動の場合、少し遅延してチュートリアルを表示
        if shouldShowTutorial {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AppLogger.shared.info("初回起動検出: チュートリアル表示開始")
                self.shouldShowTutorial = true
            }
        }
    }
    
    /// デバッグ用の状態出力
    func debugState() -> String {
        return """
        TutorialManager State:
        - shouldShowTutorial: \(shouldShowTutorial)
        - isFirstLaunch: \(tutorialState.isFirstLaunch)
        - isCompleted: \(tutorialState.isCompleted)
        - currentStep: \(tutorialState.currentStep)
        """
    }
}