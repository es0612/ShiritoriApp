import SwiftUI

/// チュートリアル画面のメインビュー
public struct TutorialView: View {
    @State private var tutorialState = TutorialState()
    private let onComplete: () -> Void
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        AppLogger.shared.debug("TutorialView初期化")
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                ChildFriendlyBackground(animationSpeed: 0.3)
                
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: DesignSystem.Spacing.large) {
                            // プログレスインジケーター
                            TutorialProgressView(
                                currentStep: tutorialState.currentStep,
                                totalSteps: TutorialStep.allCases.count
                            )
                            .standardPadding()
                            
                            // メインコンテンツ
                            TutorialStepView(
                                step: tutorialState.currentStep,
                                screenSize: geometry.size
                            )
                            .cardStyle()
                            .standardPadding()
                            
                            Spacer()
                            
                            // ナビゲーションボタン
                            TutorialNavigationView(
                                currentStep: tutorialState.currentStep,
                                canSkip: tutorialState.canSkip,
                                onPrevious: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        tutorialState.previousStep()
                                    }
                                },
                                onNext: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        tutorialState.nextStep()
                                    }
                                },
                                onSkip: {
                                    tutorialState.skipTutorial()
                                    onComplete()
                                },
                                onComplete: {
                                    tutorialState.completeTutorial()
                                    onComplete()
                                }
                            )
                            .standardPadding()
                        }
                    }
                }
            }
            .navigationTitle("チュートリアル")
            .navigationBarBackButtonHidden(true)
            .onAppear {
                AppLogger.shared.info("チュートリアル画面表示: ステップ=\(tutorialState.currentStep)")
            }
            .onChange(of: tutorialState.isCompleted) { _, isCompleted in
                if isCompleted {
                    AppLogger.shared.info("チュートリアル完了、メイン画面に戻る")
                    onComplete()
                }
            }
        }
    }
}

/// チュートリアルの進行状況を表示
private struct TutorialProgressView: View {
    let currentStep: TutorialStep
    let totalSteps: Int
    
    private var currentStepIndex: Int {
        TutorialStep.allCases.firstIndex(of: currentStep) ?? 0
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            Text("ステップ \(currentStepIndex + 1) / \(totalSteps)")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: Double(currentStepIndex + 1), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(y: 2.0)
        }
    }
}

/// 各チュートリアルステップの内容を表示
private struct TutorialStepView: View {
    let step: TutorialStep
    let screenSize: CGSize
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            // アイコンと タイトル
            VStack(spacing: DesignSystem.Spacing.standard) {
                Image(systemName: step.icon)
                    .font(.system(size: 60))
                    .foregroundColor(stepColor)
                    .padding()
                    .background(
                        Circle()
                            .fill(stepColor.opacity(0.1))
                    )
                
                Text(step.displayName)
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            
            // 説明テキスト
            Text(step.description)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, DesignSystem.Spacing.small)
            
            // ステップ別の追加コンテンツ
            stepSpecificContent
        }
        .frame(minHeight: stepContentHeight)
    }
    
    private var stepColor: Color {
        switch step.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        default: return DesignSystem.Colors.primary
        }
    }
    
    private var stepContentHeight: CGFloat {
        // 小さな画面では高さを調整
        screenSize.height < 600 ? 300 : 400
    }
    
    @ViewBuilder
    private var stepSpecificContent: some View {
        switch step {
        case .welcome:
            welcomeContent
        case .basicRules:
            basicRulesContent
        case .voiceInput:
            voiceInputContent
        case .gamePlay:
            gamePlayContent
        case .tips:
            tipsContent
        }
    }
    
    private var welcomeContent: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            Text("🎮")
                .font(.system(size: 80))
            
            Text("楽しいしりとりゲームで\n言葉の力を鍛えよう！")
                .font(DesignSystem.Typography.subtitle)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var basicRulesContent: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            ruleItem(icon: "1.circle.fill", text: "前の単語の最後の文字で始める", color: .blue)
            ruleItem(icon: "2.circle.fill", text: "「ん」で終わる単語は負け", color: .red)
            ruleItem(icon: "3.circle.fill", text: "同じ単語は使えません", color: .orange)
        }
    }
    
    private func ruleItem(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.small)
    }
    
    private var voiceInputContent: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            HStack(spacing: DesignSystem.Spacing.standard) {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                Text("りんご")
                    .font(DesignSystem.Typography.title)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                            .fill(DesignSystem.Colors.lightGray)
                    )
            }
            
            Text("話すだけで自動入力！")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var gamePlayContent: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // ミニゲームプレビュー
            VStack(spacing: DesignSystem.Spacing.small) {
                Text("りんご")
                    .font(DesignSystem.Typography.title)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                            .fill(DesignSystem.Colors.accent.opacity(0.2))
                    )
                
                Image(systemName: "arrow.down")
                    .foregroundColor(.secondary)
                
                Text("ご で始まる単語は？")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                
                Text("ごりら")
                    .font(DesignSystem.Typography.title)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                            .fill(DesignSystem.Colors.success.opacity(0.2))
                    )
            }
        }
    }
    
    private var tipsContent: some View {
        VStack(spacing: DesignSystem.Spacing.small) {
            tipItem(icon: "brain.head.profile", text: "動物の名前をたくさん覚えよう", color: .blue)
            tipItem(icon: "leaf.fill", text: "植物や食べ物も便利", color: .green)
            tipItem(icon: "exclamationmark.triangle.fill", text: "「る」「ぷ」で終わる単語は要注意", color: .orange)
        }
    }
    
    private func tipItem(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.small)
    }
}

/// チュートリアルナビゲーションボタン
private struct TutorialNavigationView: View {
    let currentStep: TutorialStep
    let canSkip: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let onComplete: () -> Void
    
    private var isFirstStep: Bool {
        currentStep == TutorialStep.allCases.first
    }
    
    private var isLastStep: Bool {
        currentStep == TutorialStep.allCases.last
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.standard) {
            // メインボタン行
            HStack(spacing: DesignSystem.Spacing.standard) {
                // 戻るボタン
                Button(action: onPrevious) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                }
                .buttonStyle(DesignSystem.SecondaryButtonStyle())
                .disabled(isFirstStep)
                .opacity(isFirstStep ? 0.5 : 1.0)
                
                Spacer()
                
                // 次へ／完了ボタン
                Button(action: isLastStep ? onComplete : onNext) {
                    HStack {
                        Text(isLastStep ? "完了" : "次へ")
                        if !isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .buttonStyle(DesignSystem.PrimaryButtonStyle())
            }
            
            // スキップボタン
            if canSkip && !isLastStep {
                Button("チュートリアルをスキップ", action: onSkip)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    TutorialView(onComplete: {})
}