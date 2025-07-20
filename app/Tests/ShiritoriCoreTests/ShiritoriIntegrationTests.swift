import Testing
@testable import ShiritoriCore

/// しりとり機能の統合テスト
struct ShiritoriIntegrationTests {
    
    @Test("長音符で終わる単語のしりとり接続テスト")
    func testLongVowelMarkConnection() async throws {
        let ruleEngine = ShiritoriRuleEngine()
        
        // 従来は接続しない組み合わせ
        let beforeNormalization = ruleEngine.canWordFollow(previousWord: "るびー", nextWord: "ばしょ")
        #expect(!beforeNormalization) // 元々は接続しない
        
        // 正規化により接続するようになる組み合わせ
        #expect(ruleEngine.canWordFollow(previousWord: "るびー", nextWord: "いぬ")) // 「るびい」→「いぬ」
        #expect(ruleEngine.canWordFollow(previousWord: "すーぷ", nextWord: "ぷりん")) // 「すーぷ」→「ぷりん」(末尾は「ぷ」)
        #expect(ruleEngine.canWordFollow(previousWord: "せんせー", nextWord: "えんぴつ")) // 「せんせえ」→「えんぴつ」
    }
    
    @Test("拗音・促音のしりとり接続テスト")
    func testSmallKanaConnection() async throws {
        let ruleEngine = ShiritoriRuleEngine()
        
        // 拗音の正規化による接続
        #expect(ruleEngine.canWordFollow(previousWord: "ばしょ", nextWord: "よる")) // 「ばしよ」→「よる」
        #expect(ruleEngine.canWordFollow(previousWord: "りょこう", nextWord: "うみ")) // 「りよこう」→「うみ」
        
        // 促音の正規化による接続
        #expect(ruleEngine.canWordFollow(previousWord: "まっぷ", nextWord: "ぷれぜんと")) // 「まつぷ」→「ぷれぜんと」
    }
    
    @Test("HiraganaConverterとShiritoriWordNormalizerの統合")
    func testHiraganaConversionWithNormalization() async throws {
        let converter = HiraganaConverter()
        let normalizer = ShiritoriWordNormalizer()
        
        // カタカナ入力のひらがな変換
        let converted1 = converter.convertToHiragana("ルビー")
        #expect(converted1 == "るびー")
        // 末尾のみ正規化（「ー」は前の文字の母音に変換される）
        #expect(normalizer.normalizeLastCharacterOnly(converted1) == "るびい")
        
        let converted2 = converter.convertToHiragana("スープ")
        #expect(converted2 == "すーぷ")
        #expect(normalizer.normalizeLastCharacterOnly(converted2) == "すーぷ") // 末尾は「ぷ」なので変換なし
        
        // 混在文字列の処理
        let converted3 = converter.convertToHiragana("ジュース")
        #expect(converted3 == "じゅーす")
        
        // 既にひらがなの場合（「ー」末尾は前の文字の母音に変換）
        #expect(normalizer.normalizeLastCharacterOnly("すーぷ") == "すーぷ") // 末尾は「ぷ」なので変換なし
        #expect(normalizer.normalizeLastCharacterOnly("せんせー") == "せんせえ") // 「せ」はえ行系統なので「え」に変換
    }
    
    @Test("しりとりゲーム全体フローのテスト")
    func testCompleteShiritoriFlow() async throws {
        let ruleEngine = ShiritoriRuleEngine()
        
        // 正規化が必要な単語チェーンの検証（「ん」で終わらない単語を使用）
        let words = [
            "ねこ",        // 通常の単語
            "こいぬ",      // 通常の単語
            "ぬりえ",      // 通常の単語
            "えびー",      // 長音符あり →「えびい」
            "いぬ"         // 正規化された末尾「い」に接続
        ]
        
        let result = ruleEngine.validateShiritoriChain(words)
        #expect(result.isValid) // 正規化により全て接続する
    }
    
    @Test("「ん」で終わる単語の正規化チェック")
    func testNEndingWithNormalization() async throws {
        let ruleEngine = ShiritoriRuleEngine()
        
        // 「ん」で終わる単語は無効（正規化の影響なし）
        #expect(!ruleEngine.isWordValidForShiritori("みかん"))
        #expect(!ruleEngine.isWordValidForShiritori("ぺん"))
        
        // 正規化で「ん」にならない単語は有効
        #expect(ruleEngine.isWordValidForShiritori("るびー")) // 「るびい」になる
        #expect(ruleEngine.isWordValidForShiritori("すーぷ")) // 「すうぷ」になる
    }
    
    @Test("エッジケースの統合テスト")
    func testEdgeCaseIntegration() async throws {
        let ruleEngine = ShiritoriRuleEngine()
        let converter = HiraganaConverter()
        
        // 空文字列の処理
        #expect(converter.convertToHiragana("") == "")
        #expect(!ruleEngine.canWordFollow(previousWord: "", nextWord: "あ"))
        
        // 単一文字の処理
        #expect(converter.convertToHiragana("あ") == "あ")
        #expect(!ruleEngine.canWordFollow(previousWord: "ねこ", nextWord: "あ")) // 「こ」→「あ」は接続しない
        
        // 複雑な長音符・拗音組み合わせ
        let complexWord = "しゃーぷ" // 末尾のみ正規化で「しゃあぷ」になる
        #expect(ruleEngine.canWordFollow(previousWord: complexWord, nextWord: "ぷりんと"))
    }
    
    @Test("音声認識シミュレーションテスト")
    func testVoiceRecognitionSimulation() async throws {
        let converter = HiraganaConverter()
        
        // 音声認識でよくある結果のシミュレーション（ひらがな変換のみ）
        let voiceInputs = [
            "ルビー",
            "バショー", 
            "ジュース",
            "チョコレート"
        ]
        
        let expectedOutputs = [
            "るびー",
            "ばしょー",
            "じゅーす",
            "ちょこれーと"
        ]
        
        for (input, expected) in zip(voiceInputs, expectedOutputs) {
            let result = converter.convertToHiragana(input)
            #expect(result == expected, "音声入力'\(input)'のひらがな変換結果が期待値'\(expected)'と一致しません。実際: '\(result)'")
        }
    }
    
    @Test("リアルタイム正規化の効果測定")
    func testNormalizationImpact() async throws {
        let normalizer = ShiritoriWordNormalizer()
        
        // 正規化により接続性が改善される単語ペア（実際に接続する組み合わせ）
        let testPairs = [
            ("るびー", "いぬ"),     // 「るびい」→「いぬ」
            ("ばしょ", "よる")      // 「ばしよ」→「よる」
        ]
        
        for (word1, word2) in testPairs {
            let improvesConnection = normalizer.improvesShiritoriConnection(word1: word1, word2: word2)
            #expect(improvesConnection, "'\(word1)' → '\(word2)' の正規化による接続改善が確認できません")
        }
    }
}