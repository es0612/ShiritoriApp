import Foundation
import SwiftData

/// アプリケーション設定を管理するサービス
@Observable
public final class SettingsManager {
    
    // MARK: - シングルトン
    
    public static let shared = SettingsManager()
    
    // MARK: - プロパティ
    
    private var modelContext: ModelContext?
    private var _settings: AppSettings?
    
    /// 現在の設定（読み取り専用）
    public var settings: AppSettings {
        if let _settings = _settings {
            return _settings
        }
        
        // 設定が未初期化の場合、デフォルト設定を返す
        let defaultSettings = AppSettings()
        AppLogger.shared.warning("設定が未初期化のため、デフォルト設定を返します")
        return defaultSettings
    }
    
    /// デフォルト入力方式
    public var defaultInputMode: Bool {
        settings.defaultInputMode
    }
    
    /// 音声自動提出機能
    public var voiceAutoSubmit: Bool {
        settings.voiceAutoSubmit
    }
    
    /// 音声認識感度
    public var voiceSensitivity: Double {
        settings.voiceSensitivity
    }
    
    /// 自動フォールバック機能
    public var autoFallbackEnabled: Bool {
        settings.autoFallbackEnabled
    }
    
    /// 音声認識失敗閾値
    public var speechFailureThreshold: Int {
        settings.speechFailureThreshold
    }
    
    // MARK: - イニシャライザ
    
    private init() {
        AppLogger.shared.debug("SettingsManager初期化")
    }
    
    // MARK: - 初期化メソッド
    
    /// ModelContextを設定して初期化
    public func initialize(with modelContext: ModelContext) {
        AppLogger.shared.info("SettingsManager初期化開始")
        self.modelContext = modelContext
        loadOrCreateSettings()
    }
    
    /// 設定の読み込みまたは作成
    private func loadOrCreateSettings() {
        guard let modelContext = modelContext else {
            AppLogger.shared.error("ModelContextが設定されていません")
            return
        }
        
        do {
            // 既存の設定を検索
            let descriptor = FetchDescriptor<AppSettings>(
                predicate: #Predicate { $0.id == "app_settings_singleton" }
            )
            
            let existingSettings = try modelContext.fetch(descriptor)
            
            if let existingSettings = existingSettings.first {
                AppLogger.shared.info("既存の設定を読み込み")
                self._settings = existingSettings
            } else {
                AppLogger.shared.info("新しい設定を作成")
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                try modelContext.save()
                self._settings = newSettings
            }
            
            AppLogger.shared.debug("設定読み込み完了: defaultInputMode=\(settings.defaultInputMode)")
            
        } catch {
            AppLogger.shared.error("設定の読み込みに失敗: \(error)")
            
            // エラーの場合、デフォルト設定を作成
            let defaultSettings = AppSettings()
            modelContext.insert(defaultSettings)
            try? modelContext.save()
            self._settings = defaultSettings
        }
    }
    
    // MARK: - 設定更新メソッド
    
    /// デフォルト入力方式を更新
    public func updateDefaultInputMode(_ isVoice: Bool) {
        AppLogger.shared.info("デフォルト入力方式を更新: \(isVoice ? "音声入力" : "キーボード入力")")
        
        settings.updateSettings(defaultInputMode: isVoice)
        saveSettings()
    }
    
    /// 音声自動提出機能を更新
    public func updateVoiceAutoSubmit(_ isEnabled: Bool) {
        AppLogger.shared.info("音声自動提出を更新: \(isEnabled)")
        
        settings.updateSettings(voiceAutoSubmit: isEnabled)
        saveSettings()
    }
    
    /// 音声認識感度を更新
    public func updateVoiceSensitivity(_ sensitivity: Double) {
        AppLogger.shared.info("音声感度を更新: \(sensitivity)")
        
        settings.updateSettings(voiceSensitivity: sensitivity)
        saveSettings()
    }
    
    /// 自動フォールバック機能を更新
    public func updateAutoFallbackEnabled(_ isEnabled: Bool) {
        AppLogger.shared.info("自動フォールバック機能を更新: \(isEnabled)")
        
        settings.updateSettings(autoFallbackEnabled: isEnabled)
        saveSettings()
    }
    
    /// 音声認識失敗閾値を更新
    public func updateSpeechFailureThreshold(_ threshold: Int) {
        AppLogger.shared.info("音声認識失敗閾値を更新: \(threshold)")
        
        settings.updateSettings(speechFailureThreshold: threshold)
        saveSettings()
    }
    
    /// 設定をデフォルトにリセット
    public func resetToDefaults() {
        AppLogger.shared.info("設定をデフォルトにリセット")
        
        settings.resetToDefaults()
        saveSettings()
    }
    
    /// 設定を保存
    private func saveSettings() {
        guard let modelContext = modelContext else {
            AppLogger.shared.error("ModelContextが設定されていないため保存できません")
            return
        }
        
        do {
            try modelContext.save()
            AppLogger.shared.debug("設定の保存完了")
        } catch {
            AppLogger.shared.error("設定の保存に失敗: \(error)")
        }
    }
    
    // MARK: - 便利メソッド
    
    /// 入力方式の文字列表現を取得
    public func getInputModeDisplayName() -> String {
        return defaultInputMode ? "音声入力" : "キーボード入力"
    }
    
    /// デバッグ用設定情報を出力
    public func printDebugInfo() {
        AppLogger.shared.debug("""
        === 設定情報 ===
        デフォルト入力方式: \(defaultInputMode ? "音声入力" : "キーボード入力")
        音声自動提出: \(voiceAutoSubmit)
        音声感度: \(voiceSensitivity)
        自動フォールバック: \(autoFallbackEnabled)
        失敗閾値: \(speechFailureThreshold)回
        最終更新: \(settings.lastUpdated)
        ===============
        """)
    }
}