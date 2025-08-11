//
//  MainAppView.swift
//  ShiritoriApp
//  
//  Created on 2025/07/17
//

import SwiftUI
import ShiritoriCore

/// アプリのメインビュー（チュートリアル統合）
struct MainAppView: View {
    @State private var tutorialManager = TutorialManager.shared
    
    var body: some View {
        Group {
            if tutorialManager.shouldShowTutorial {
                TutorialView(onComplete: {
                    AppLogger.shared.info("チュートリアル完了コールバック")
                    tutorialManager.completeTutorial()
                })
                .transition(.opacity)
            } else {
                TitleView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: tutorialManager.shouldShowTutorial)
        .onAppear {
            AppLogger.shared.info("MainAppView表示: チュートリアル表示=\(tutorialManager.shouldShowTutorial)")
            AppLogger.shared.debug(tutorialManager.debugState())
        }
    }
}

#Preview {
    MainAppView()
}