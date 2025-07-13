import SwiftUI

/// ゲーム進行状況バー
public struct GameProgressBar: View {
    public let usedWordsCount: Int
    public let totalTurns: Int
    
    public init(usedWordsCount: Int, totalTurns: Int) {
        AppLogger.shared.debug("GameProgressBar初期化: \(usedWordsCount)/\(totalTurns)")
        self.usedWordsCount = usedWordsCount
        self.totalTurns = totalTurns
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            // プログレスバー
            HStack {
                Text("しんちょく")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(usedWordsCount) / \(totalTurns)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: progressValue)
                .progressViewStyle(CustomProgressViewStyle())
                .frame(height: 12)
        }
        .padding(.horizontal)
    }
    
    private var progressValue: Double {
        guard totalTurns > 0 else { return 0.0 }
        return min(Double(usedWordsCount) / Double(totalTurns), 1.0)
    }
}

/// カスタムプログレスバースタイル
private struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            // 背景
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 12)
            
            // プログレス
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [.green, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: (configuration.fractionCompleted ?? 0) * 300, // 固定幅
                    height: 12
                )
                .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
        }
    }
}