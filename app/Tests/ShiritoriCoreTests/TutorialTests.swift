import Testing
@testable import ShiritoriCore

@Suite("Tutorial Tests")
struct TutorialTests {
    
    @Test("TutorialState初期化テスト")
    func testTutorialStateInitialization() {
        // Given & When
        let tutorialState = TutorialState()
        
        // Then
        #expect(tutorialState.isFirstLaunch == true)
        #expect(tutorialState.isCompleted == false)
        #expect(tutorialState.currentStep == .welcome)
        #expect(tutorialState.canSkip == true)
    }
    
    @Test("チュートリアルステップの順序テスト")
    func testTutorialStepProgression() {
        // Given
        let tutorialState = TutorialState()
        
        // When & Then: 正常な順序でステップが進むことを確認
        #expect(tutorialState.currentStep == .welcome)
        
        tutorialState.nextStep()
        #expect(tutorialState.currentStep == .basicRules)
        
        tutorialState.nextStep()
        #expect(tutorialState.currentStep == .voiceInput)
        
        tutorialState.nextStep()
        #expect(tutorialState.currentStep == .gamePlay)
        
        tutorialState.nextStep()
        #expect(tutorialState.currentStep == .tips)
        
        // 最後のステップで完了する
        tutorialState.nextStep()
        #expect(tutorialState.isCompleted == true)
        #expect(tutorialState.isFirstLaunch == false)
    }
    
    @Test("チュートリアル戻る機能テスト")
    func testTutorialPreviousStep() {
        // Given
        let tutorialState = TutorialState()
        tutorialState.nextStep() // basicRules
        tutorialState.nextStep() // voiceInput
        
        // When & Then
        #expect(tutorialState.currentStep == .voiceInput)
        
        tutorialState.previousStep()
        #expect(tutorialState.currentStep == .basicRules)
        
        tutorialState.previousStep()
        #expect(tutorialState.currentStep == .welcome)
        
        // 最初のステップでは何も変わらない
        tutorialState.previousStep()
        #expect(tutorialState.currentStep == .welcome)
    }
    
    @Test("チュートリアルスキップ機能テスト")
    func testTutorialSkip() {
        // Given
        let tutorialState = TutorialState()
        #expect(tutorialState.canSkip == true)
        
        // When
        tutorialState.skipTutorial()
        
        // Then
        #expect(tutorialState.isCompleted == true)
        #expect(tutorialState.isFirstLaunch == false)
    }
    
    @Test("チュートリアルリセット機能テスト")
    func testTutorialReset() {
        // Given
        let tutorialState = TutorialState()
        tutorialState.completeTutorial()
        
        #expect(tutorialState.isCompleted == true)
        #expect(tutorialState.isFirstLaunch == false)
        
        // When
        tutorialState.resetTutorial()
        
        // Then
        #expect(tutorialState.isFirstLaunch == true)
        #expect(tutorialState.isCompleted == false)
        #expect(tutorialState.currentStep == .welcome)
    }
    
    @Test("TutorialStepの属性テスト")
    func testTutorialStepProperties() {
        // Given & When & Then
        let welcomeStep = TutorialStep.welcome
        #expect(welcomeStep.displayName == "ようこそ")
        #expect(welcomeStep.icon == "hand.wave.fill")
        #expect(welcomeStep.color == "blue")
        #expect(!welcomeStep.description.isEmpty)
        
        let basicRulesStep = TutorialStep.basicRules
        #expect(basicRulesStep.displayName == "基本ルール")
        #expect(basicRulesStep.icon == "book.fill")
        #expect(basicRulesStep.color == "green")
        
        let voiceInputStep = TutorialStep.voiceInput
        #expect(voiceInputStep.displayName == "音声入力")
        #expect(voiceInputStep.icon == "mic.fill")
        #expect(voiceInputStep.color == "purple")
        
        let gamePlayStep = TutorialStep.gamePlay
        #expect(gamePlayStep.displayName == "ゲームの進め方")
        #expect(gamePlayStep.icon == "gamecontroller.fill")
        #expect(gamePlayStep.color == "orange")
        
        let tipsStep = TutorialStep.tips
        #expect(tipsStep.displayName == "コツとヒント")
        #expect(tipsStep.icon == "lightbulb.fill")
        #expect(tipsStep.color == "yellow")
    }
    
    @Test("TutorialManagerシングルトンテスト")
    func testTutorialManagerSingleton() {
        // Given & When
        let manager1 = TutorialManager.shared
        let manager2 = TutorialManager.shared
        
        // Then
        #expect(manager1 === manager2) // 同じインスタンスであることを確認
    }
    
    @Test("TutorialManager初期状態テスト")
    func testTutorialManagerInitialState() {
        // Given & When
        let manager = TutorialManager.shared
        
        // Then: 初期状態の確認（TutorialStateは非Optional型のため適切な状態検証）
        #expect(manager.tutorialState.currentStep == .welcome)
        #expect(manager.shouldShowTutorial == manager.tutorialState.isFirstLaunch && !manager.tutorialState.isCompleted)
    }
    
    @Test("TutorialManagerチュートリアル制御テスト")
    func testTutorialManagerControl() {
        // Given
        let manager = TutorialManager.shared
        
        // When: チュートリアル開始
        manager.startTutorial()
        
        // Then
        #expect(manager.shouldShowTutorial == true)
        #expect(manager.tutorialState.currentStep == .welcome)
        
        // When: チュートリアル完了
        manager.completeTutorial()
        
        // Then
        #expect(manager.shouldShowTutorial == false)
        #expect(manager.tutorialState.isCompleted == true)
    }
    
    @Test("TutorialManagerリセット機能テスト")
    func testTutorialManagerReset() {
        // Given
        let manager = TutorialManager.shared
        manager.completeTutorial()
        
        // When
        manager.resetTutorial()
        
        // Then
        #expect(manager.shouldShowTutorial == true)
        #expect(manager.tutorialState.isFirstLaunch == true)
        #expect(manager.tutorialState.isCompleted == false)
    }
    
    @Test("TutorialManager強制非表示テスト")
    func testTutorialManagerDismiss() {
        // Given
        let manager = TutorialManager.shared
        manager.startTutorial()
        #expect(manager.shouldShowTutorial == true)
        
        // When
        manager.dismissTutorial()
        
        // Then
        #expect(manager.shouldShowTutorial == false)
    }
}