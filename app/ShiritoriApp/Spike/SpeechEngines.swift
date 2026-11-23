//
//  SpeechEngines.swift
//  【試作・捨てる前提】音声認識方式の聞き比べ用エンジン
//
//  1回録音した音声ファイルを、複数の認識方式に通して結果を比べる。
//  UI に依存させていないのは、Mac 上で合成音声を使って動作確認するため。
//

import AVFoundation
import Foundation
import Speech

/// 比べる認識方式
enum SpikeEngine: String, CaseIterable, Identifiable {
    case legacyServer = "従来(サーバー)"
    case legacyOnDevice = "従来(端末内)"
    case dictation = "新・短文向け"
    case transcriber = "新・長文向け"

    var id: String { rawValue }

    /// ヒント（次に来そうな言葉のリスト）を渡せる方式かどうか
    var supportsHints: Bool { self != .transcriber }
}

/// 1方式ぶんの認識結果
struct SpikeOutput {
    var best: String = ""
    var alternatives: [String] = []
    var seconds: Double = 0
    var note: String = ""  // 非対応・エラーなどの理由
}

enum SpikeSpeech {
    static let locale = Locale(identifier: "ja-JP")

    static func run(_ engine: SpikeEngine, url: URL, hints: [String]) async -> SpikeOutput {
        let started = Date()
        var output: SpikeOutput
        switch engine {
        case .legacyServer:
            output = await legacy(url: url, hints: hints, onDevice: false)
        case .legacyOnDevice:
            output = await legacy(url: url, hints: hints, onDevice: true)
        case .dictation, .transcriber:
            if #available(iOS 26.0, macOS 26.0, *) {
                output = await modern(engine, url: url, hints: hints)
            } else {
                output = SpikeOutput(note: "iOS 26 以上が必要")
            }
        }
        output.seconds = Date().timeIntervalSince(started)
        return output
    }

    // MARK: - 従来方式 (SFSpeechRecognizer)

    private static func legacy(url: URL, hints: [String], onDevice: Bool) async -> SpikeOutput {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            return SpikeOutput(note: "認識エンジンが使えません")
        }
        if onDevice && !recognizer.supportsOnDeviceRecognition {
            return SpikeOutput(note: "端末内認識に非対応")
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = onDevice
        request.addsPunctuation = false
        request.contextualStrings = hints

        return await withCheckedContinuation { continuation in
            // コールバックが複数回呼ばれても、再開は1回だけにする
            var resumed = false
            func finish(_ output: SpikeOutput) {
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: output)
            }
            recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    let texts = result.transcriptions.map(\.formattedString)
                    finish(SpikeOutput(best: texts.first ?? "", alternatives: Array(texts.dropFirst())))
                } else if let error {
                    finish(SpikeOutput(note: shortError(error)))
                }
            }
        }
    }

    // MARK: - 新方式 (SpeechAnalyzer)

    @available(iOS 26.0, macOS 26.0, *)
    private static func modern(_ engine: SpikeEngine, url: URL, hints: [String]) async -> SpikeOutput {
        do {
            let module: any SpeechModule
            let collector: Task<[(String, [String])], Error>

            if engine == .dictation {
                guard let supported = await DictationTranscriber.supportedLocale(equivalentTo: locale) else {
                    return SpikeOutput(note: "日本語に非対応")
                }
                let transcriber = DictationTranscriber(
                    locale: supported,
                    contentHints: [.shortForm],
                    transcriptionOptions: [],
                    reportingOptions: [.alternativeTranscriptions],
                    attributeOptions: []
                )
                module = transcriber
                collector = Task {
                    var segments: [(String, [String])] = []
                    for try await result in transcriber.results {
                        segments.append((String(result.text.characters), result.alternatives.map { String($0.characters) }))
                    }
                    return segments
                }
            } else {
                guard let supported = await SpeechTranscriber.supportedLocale(equivalentTo: locale) else {
                    return SpikeOutput(note: "日本語に非対応（この端末では使えない可能性）")
                }
                let transcriber = SpeechTranscriber(locale: supported, preset: .transcriptionWithAlternatives)
                module = transcriber
                collector = Task {
                    var segments: [(String, [String])] = []
                    for try await result in transcriber.results {
                        segments.append((String(result.text.characters), result.alternatives.map { String($0.characters) }))
                    }
                    return segments
                }
            }

            // 認識モデルが端末に無ければダウンロードする（初回だけ時間がかかる）
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
                try await request.downloadAndInstall()
            }

            let analyzer = SpeechAnalyzer(modules: [module])
            if engine.supportsHints, !hints.isEmpty {
                let context = AnalysisContext()
                context.contextualStrings[.general] = hints
                try await analyzer.setContext(context)
            }

            let file = try AVAudioFile(forReading: url)
            if let lastSample = try await analyzer.analyzeSequence(from: file) {
                try await analyzer.finalizeAndFinish(through: lastSample)
            } else {
                await analyzer.cancelAndFinishNow()
            }

            let segments = try await collector.value
            // 短い発話でも複数の区間に分かれることがあるので、つなげて1語として扱う
            let best = segments.map(\.0).joined()
            // 先頭は best と同じ内容のことがあるので取り除く
            let alternatives = (segments.first?.1 ?? []).filter { $0 != best }
            return SpikeOutput(best: best, alternatives: alternatives)
        } catch {
            return SpikeOutput(note: shortError(error))
        }
    }

    private static func shortError(_ error: Error) -> String {
        let nsError = error as NSError
        return "エラー: \(nsError.domain) \(nsError.code) \(nsError.localizedDescription)"
    }
}

// MARK: - 読み（ひらがな）への変換と判定

enum SpikeKana {
    /// 認識結果（漢字・カタカナまじり）を、比較用のひらがなにそろえる
    static func reading(_ text: String) -> String {
        let trimmed = text.filter { !$0.isWhitespace && !$0.isPunctuation }
        let alreadyKana = trimmed.unicodeScalars.allSatisfy { (0x3040...0x30FF).contains($0.value) }
        if alreadyKana {
            return katakanaToHiragana(trimmed)
        }

        // 漢字を含む場合は、OS の形態素解析で読み（ローマ字）を取り、ひらがなに直す
        let cfText = trimmed as CFString
        let tokenizer = CFStringTokenizerCreate(
            nil, cfText, CFRangeMake(0, CFStringGetLength(cfText)),
            kCFStringTokenizerUnitWordBoundary, Locale(identifier: "ja") as CFLocale
        )
        var result = ""
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            guard let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String else {
                continue
            }
            let mutable = NSMutableString(string: latin)
            CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false)
            result += mutable as String
        }
        return result
    }

    /// カタカナをひらがなに直す。
    /// OS の変換は長音「ー」を母音に置き換える（ケーキ→けえき）ので、文字コードをずらして自前で直す。
    private static func katakanaToHiragana(_ text: String) -> String {
        String(String.UnicodeScalarView(text.unicodeScalars.map { scalar in
            (0x30A1...0x30F6).contains(scalar.value) ? Unicode.Scalar(scalar.value - 0x60) ?? scalar : scalar
        }))
    }

    enum Verdict: String {
        case top = "◎"      // 第1候補が一致
        case inAlternatives = "○"  // 別候補の中に一致あり
        case miss = "×"
        case unavailable = "−"  // 方式が使えなかった
    }

    static func judge(_ output: SpikeOutput, target: String) -> Verdict {
        if !output.note.isEmpty && output.best.isEmpty { return .unavailable }
        if reading(output.best) == target { return .top }
        if output.alternatives.contains(where: { reading($0) == target }) { return .inAlternatives }
        return .miss
    }
}
