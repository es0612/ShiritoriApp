import Foundation
import SwiftUI
import AVFoundation
import AudioToolbox

#if canImport(UIKit)
import UIKit
#endif

/// ゲーム内効果音を管理するシングルトンクラス
@Observable
public class SoundManager {
    public static let shared = SoundManager()
    
    public var isEnabled: Bool = true
    public var volume: Float = 0.7
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        AppLogger.shared.debug("SoundManager初期化")
        loadSettings()
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    /// 正解時の効果音を再生
    public func playCorrectSound() {
        guard isEnabled else { return }
        
        AppLogger.shared.debug("正解音再生")
        playSystemSound(.correct)
    }
    
    /// 不正解時の効果音を再生
    public func playIncorrectSound() {
        guard isEnabled else { return }
        
        AppLogger.shared.debug("不正解音再生")
        playSystemSound(.incorrect)
    }
    
    /// ターン切り替え時の効果音を再生
    public func playTurnChangeSound() {
        guard isEnabled else { return }
        
        AppLogger.shared.debug("ターン切り替え音再生")
        playSystemSound(.turnChange)
    }
    
    /// プレイヤー脱落時の効果音を再生
    public func playEliminationSound() {
        guard isEnabled else { return }
        
        AppLogger.shared.debug("脱落音再生")
        playSystemSound(.elimination)
    }
    
    /// ゲーム終了時の効果音を再生
    public func playGameEndSound() {
        guard isEnabled else { return }
        
        AppLogger.shared.debug("ゲーム終了音再生")
        playSystemSound(.gameEnd)
    }
    
    /// 効果音の有効/無効を設定
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        saveSettings()
        AppLogger.shared.info("効果音設定変更: \(enabled ? "有効" : "無効")")
    }
    
    /// 音量を設定（0.0〜1.0）
    public func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        saveSettings()
        AppLogger.shared.info("音量設定変更: \(self.volume)")
    }
    
    // MARK: - Private Methods
    
    /// オーディオセッションの設定
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            AppLogger.shared.debug("オーディオセッション設定完了")
        } catch {
            AppLogger.shared.error("オーディオセッション設定失敗: \(error.localizedDescription)")
        }
        #else
        AppLogger.shared.debug("macOS環境のためオーディオセッション設定をスキップ")
        #endif
    }
    
    /// システム効果音を再生
    private func playSystemSound(_ soundType: SoundType) {
        // iOS システム効果音を使用
        AudioServicesPlaySystemSoundWithCompletion(soundType.systemSoundID) {
            AppLogger.shared.debug("システム効果音再生完了: \(soundType)")
        }
    }
    
    /// カスタム効果音を再生（将来の拡張用）
    private func playCustomSound(_ fileName: String) {
        guard let soundURL = Bundle.main.url(forResource: fileName, withExtension: "wav") else {
            AppLogger.shared.warning("効果音ファイルが見つかりません: \(fileName)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.volume = volume
            audioPlayer?.play()
            AppLogger.shared.debug("カスタム効果音再生: \(fileName)")
        } catch {
            AppLogger.shared.error("効果音再生エラー: \(error.localizedDescription)")
        }
    }
    
    /// 設定を保存
    private func saveSettings() {
        UserDefaults.standard.set(isEnabled, forKey: "sound_enabled")
        UserDefaults.standard.set(volume, forKey: "sound_volume")
        AppLogger.shared.debug("効果音設定保存: 有効=\(isEnabled), 音量=\(volume)")
    }
    
    /// 設定を読み込み
    private func loadSettings() {
        isEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
        volume = UserDefaults.standard.object(forKey: "sound_volume") as? Float ?? 0.7
        AppLogger.shared.debug("効果音設定読み込み: 有効=\(isEnabled), 音量=\(volume)")
    }
}

/// 効果音の種類を定義
private enum SoundType {
    case correct        // 正解
    case incorrect      // 不正解
    case turnChange     // ターン切り替え
    case elimination    // 脱落
    case gameEnd        // ゲーム終了
    
    /// 対応するシステム効果音ID
    var systemSoundID: SystemSoundID {
        switch self {
        case .correct:
            return 1057  // 成功音（メール送信音）
        case .incorrect:
            return 1053  // エラー音（ビープ音）
        case .turnChange:
            return 1104  // 軽やかな音（カメラシャッター音）
        case .elimination:
            return 1006  // 警告音（バッテリー低下音）
        case .gameEnd:
            return 1013  // 終了音（鈴の音）
        }
    }
}

// MARK: - Static Helper Methods

public extension SoundManager {
    /// 効果音付きの振動
    static func playHapticFeedback() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        AppLogger.shared.debug("触覚フィードバック実行")
        #else
        AppLogger.shared.debug("macOS環境のため触覚フィードバックをスキップ")
        #endif
    }
    
    /// 成功時の効果音＋振動
    static func playSuccessFeedback() {
        shared.playCorrectSound()
        playHapticFeedback()
    }
    
    /// エラー時の効果音＋振動
    static func playErrorFeedback() {
        shared.playIncorrectSound()
        playHapticFeedback()
    }
    
    /// ターン切り替え時の効果音＋振動
    static func playTurnChangeFeedback() {
        shared.playTurnChangeSound()
        playHapticFeedback()
    }
    
    /// 脱落時の効果音＋振動
    static func playEliminationFeedback() {
        shared.playEliminationSound()
        playHapticFeedback()
    }
}