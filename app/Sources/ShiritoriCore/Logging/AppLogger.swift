//
//  AppLogger.swift
//  ShiritoriApp
//
//  Created on 2025/07/12
//

import Foundation
import os

// MARK: - ログレベル定義
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

// MARK: - ログエントリ
struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let message: String
    let file: String
    let function: String
    let line: Int
    
    var formattedMessage: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timeString = dateFormatter.string(from: timestamp)
        
        return "[\(level.rawValue)] [\(timeString)] [\(file):\(line)] [\(function)] - \(message)"
    }
}

// MARK: - AppLogger シングルトンクラス
public final class AppLogger {
    public static let shared = AppLogger()
    
    private let osLogger = os.Logger(subsystem: "com.asapapalab.ShiritoriApp", category: "default")
    private var logEntries: [LogEntry] = []
    private let queue = DispatchQueue(label: "com.asapapalab.logger", qos: .utility)
    
    private init() {
        // 開発環境とリリース環境の判定
        #if DEBUG
        print("🎯 AppLogger initialized - Debug mode")
        #endif
    }
    
    // MARK: - ログ出力メソッド
    public func debug(_ message: String, 
               file: String = #file, 
               function: String = #function, 
               line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, 
              file: String = #file, 
              function: String = #function, 
              line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, 
                 file: String = #file, 
                 function: String = #function, 
                 line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, 
               file: String = #file, 
               function: String = #function, 
               line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    // MARK: - 内部ログ処理
    private func log(level: LogLevel, 
                     message: String, 
                     file: String, 
                     function: String, 
                     line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            file: fileName,
            function: function,
            line: line
        )
        
        queue.async { [weak self] in
            self?.logEntries.append(entry)
            
            // 本番環境ではerror/warningのみ、開発環境では全レベル出力
            #if DEBUG
            print(entry.formattedMessage)
            #else
            if level == .error || level == .warning {
                print(entry.formattedMessage)
            }
            #endif
            
            // OS Loggerにも出力
            self?.logToOSLogger(entry)
        }
    }
    
    private func logToOSLogger(_ entry: LogEntry) {
        switch entry.level {
        case .debug:
            osLogger.debug("\(entry.message)")
        case .info:
            osLogger.info("\(entry.message)")
        case .warning:
            osLogger.warning("\(entry.message)")
        case .error:
            osLogger.error("\(entry.message)")
        }
    }
    
    // MARK: - テスト用メソッド
    func getLastLog() -> LogEntry? {
        return queue.sync {
            return logEntries.last
        }
    }
    
    func getAllLogs() -> [LogEntry] {
        return queue.sync {
            return logEntries
        }
    }
    
    func clearLogs() {
        queue.async { [weak self] in
            self?.logEntries.removeAll()
        }
    }
}