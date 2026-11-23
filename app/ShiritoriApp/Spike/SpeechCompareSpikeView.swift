//
//  SpeechCompareSpikeView.swift
//  【試作・捨てる前提】音声認識方式の聞き比べ画面
//
//  お題の言葉を子供に言ってもらい、同じ録音を全方式に通して ◎/○/× を数える。
//  見た目やアーキテクチャは作り込まない。知りたいのは「どの方式が子供の声に強いか」だけ。
//

import AVFoundation
import ShiritoriCore
import Speech
import SwiftUI

/// 1語ぶんの記録
private struct SpikeTrial: Identifiable {
    let id = UUID()
    let target: String
    let useHints: Bool
    var outputs: [SpikeEngine: SpikeOutput] = [:]
    var verdicts: [SpikeEngine: SpikeKana.Verdict] = [:]
}

struct SpeechCompareSpikeView: View {
    /// お題。長さ・促音・拗音・長音・濁音が混ざるように選んでいる
    private let prompts: [(emoji: String, word: String)] = [
        ("🍎", "りんご"), ("🦍", "ごりら"), ("🎺", "らっぱ"), ("🐼", "ぱんだ"), ("🥛", "ぎゅうにゅう"),
        ("🐰", "うさぎ"), ("🦒", "きりん"), ("🚗", "くるま"), ("🍰", "けーき"), ("🚄", "しんかんせん"),
        ("🐱", "ねこ"), ("🍙", "おにぎり"),
    ]

    @State private var index = 0
    @State private var useHints = true
    @State private var isRecording = false
    @State private var isAnalyzing = false
    @State private var status = "ボタンを おして おだいを いってね"
    @State private var trials: [SpikeTrial] = []
    @State private var recorder: AVAudioRecorder?

    private let dictionary = WordDictionaryService()

    private var current: (emoji: String, word: String) { prompts[index % prompts.count] }
    private var recordingURL: URL { FileManager.default.temporaryDirectory.appendingPathComponent("spike.wav") }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("聞き比べ試作 \(trials.count)語め完了")
                    .font(.caption)
                Text(current.emoji).font(.system(size: 90))
                Text(current.word).font(.system(size: 44, weight: .bold))

                Button(action: toggleRecording) {
                    Text(isRecording ? "■ とめる" : "🎤 はなす")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, minHeight: 90)
                        .background(isRecording ? Color.red : Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .disabled(isAnalyzing)
                .accessibilityLabel(isRecording ? "録音を止める" : "録音を始める")

                Text(status).font(.footnote)

                Toggle("ヒントを渡す（同じ文字で始まる言葉のリスト）", isOn: $useHints)
                    .font(.footnote)
                    .disabled(isRecording || isAnalyzing)

                if let last = trials.last {
                    lastTrialView(last)
                }

                summaryView

                HStack {
                    Button("つぎの おだい") { index += 1 }
                    Spacer()
                    Button("結果をコピー") { UIPasteboard.general.string = reportText }
                        .disabled(trials.isEmpty)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .task { await requestPermissions() }
    }

    // MARK: - 表示

    private func lastTrialView(_ trial: SpikeTrial) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("直前: \(trial.target)（マークをタップで手動訂正）").font(.caption.bold())
            ForEach(SpikeEngine.allCases) { engine in
                let output = trial.outputs[engine] ?? SpikeOutput()
                HStack(alignment: .top) {
                    Button(trial.verdicts[engine]?.rawValue ?? "…") { cycleVerdict(engine) }
                        .font(.title3)
                        .frame(width: 36)
                    VStack(alignment: .leading) {
                        Text("\(engine.rawValue): \(output.best.isEmpty ? "（なし）" : output.best)")
                        Text("別候補 \(output.alternatives.prefix(4).joined(separator: "・")) \(String(format: "%.1f秒", output.seconds)) \(output.note)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("集計（◎第1候補で正解 / ○別候補に正解 / ×はずれ）").font(.caption.bold())
            ForEach(SpikeEngine.allCases) { engine in
                Text(summaryLine(engine)).font(.caption.monospaced())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryLine(_ engine: SpikeEngine) -> String {
        func count(_ verdict: SpikeKana.Verdict, hints: Bool) -> Int {
            trials.filter { $0.useHints == hints && $0.verdicts[engine] == verdict }.count
        }
        let parts = [true, false].map { hints in
            "\(hints ? "ヒント有" : "ヒント無") ◎\(count(.top, hints: hints)) ○\(count(.inAlternatives, hints: hints)) ×\(count(.miss, hints: hints))"
        }
        return "\(engine.rawValue): \(parts.joined(separator: " | "))"
    }

    /// Claude に貼り付けて渡すための結果テキスト
    private var reportText: String {
        var lines = ["# 聞き比べ結果 \(trials.count)語", ""]
        lines += SpikeEngine.allCases.map(summaryLine)
        lines.append("")
        for trial in trials {
            lines.append("## \(trial.target) \(trial.useHints ? "ヒント有" : "ヒント無")")
            for engine in SpikeEngine.allCases {
                let output = trial.outputs[engine] ?? SpikeOutput()
                lines.append("- \(trial.verdicts[engine]?.rawValue ?? "?") \(engine.rawValue): \(output.best) / 別候補 \(output.alternatives.prefix(4).joined(separator: "・")) / \(String(format: "%.1f", output.seconds))秒 \(output.note)")
            }
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - 操作

    private func requestPermissions() async {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        let microphone = await AVAudioApplication.requestRecordPermission()
        if speech != .authorized || !microphone {
            status = "⚠️ 設定アプリで マイクと音声認識を 許可してください"
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopAndAnalyze()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
            ]
            let newRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            newRecorder.record()
            recorder = newRecorder
            isRecording = true
            status = "きいてるよ… いいおわったら「とめる」"
        } catch {
            status = "録音を開始できません: \(error.localizedDescription)"
        }
    }

    private func stopAndAnalyze() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        isAnalyzing = true
        status = "かんがえちゅう…（初回はモデルの準備で時間がかかります）"

        let target = current.word
        let hintsOn = useHints
        let hints = hintsOn ? hintWords(for: target) : []
        let url = recordingURL

        Task {
            var trial = SpikeTrial(target: target, useHints: hintsOn)
            // 方式どうしで端末の計算資源を取り合わないよう、1つずつ順番に通す
            for engine in SpikeEngine.allCases {
                let output = await SpikeSpeech.run(engine, url: url, hints: hints)
                trial.outputs[engine] = output
                trial.verdicts[engine] = SpikeKana.judge(output, target: target)
            }
            trials.append(trial)
            isAnalyzing = false
            index += 1
            status = "できた！ つぎの おだいを どうぞ"
        }
    }

    /// 実際のしりとりを想定したヒント: お題と同じ文字で始まる、アプリ内辞書の言葉（最大100語）。
    /// お題が辞書に無い場合は含まれない（本番でも子供は辞書に無い言葉を言うので、あえて足さない）。
    private func hintWords(for target: String) -> [String] {
        guard let first = target.first.map(String.init) else { return [] }
        let words = DifficultyLevel.allCases.flatMap { dictionary.getWordsStartingWith(first, difficulty: $0) }
        return Array(Set(words).sorted().prefix(100))
    }

    private func cycleVerdict(_ engine: SpikeEngine) {
        guard !trials.isEmpty else { return }
        let order: [SpikeKana.Verdict] = [.top, .inAlternatives, .miss, .unavailable]
        let currentVerdict = trials[trials.count - 1].verdicts[engine] ?? .miss
        let next = order[((order.firstIndex(of: currentVerdict) ?? 0) + 1) % order.count]
        trials[trials.count - 1].verdicts[engine] = next
    }
}

#Preview {
    SpeechCompareSpikeView()
}
