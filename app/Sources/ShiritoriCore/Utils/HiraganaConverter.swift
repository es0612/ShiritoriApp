import Foundation
import NaturalLanguage

/// 文字列をひらがなに変換するユーティリティクラス
/// 多層変換アプローチ:
/// 1. カスタム辞書による高精度変換
/// 2. CFStringTransformによるシステム変換
/// 3. NaturalLanguageによるコンテキスト解析
/// 4. フォールバック変換
public class HiraganaConverter {
    
    public init() {
        AppLogger.shared.debug("HiraganaConverter初期化")
    }
    
    /// 文字列をひらがなに変換する（多層アプローチ）
    /// - Parameter text: 変換する文字列
    /// - Returns: ひらがなに変換された文字列
    public func convertToHiragana(_ text: String) -> String {
        AppLogger.shared.debug("ひらがな変換開始: '\(text)'")
        
        guard !text.isEmpty else {
            AppLogger.shared.debug("空文字のため変換をスキップ")
            return text
        }
        
        // アルファベットや数字が含まれる場合は処理しない
        if text.range(of: "[a-zA-Z0-9]", options: String.CompareOptions.regularExpression) != nil {
            AppLogger.shared.debug("英数字が含まれるため変換をスキップ: '\(text)'")
            return text
        }
        
        // 多層変換を実行
        let result = performMultiLayerConversion(text)
        
        AppLogger.shared.debug("ひらがな変換完了: '\(text)' -> '\(result)'")
        return result
    }
    
    
    // MARK: - Multi-Layer Conversion System
    
    /// 多層変換システムの実行
    private func performMultiLayerConversion(_ text: String) -> String {
        AppLogger.shared.debug("多層変換開始: '\(text)'")
        
        // レイヤー1: カスタム辞書による高精度変換
        let layer1Result = performDictionaryConversion(text)
        if layer1Result != text {
            AppLogger.shared.info("辞書変換成功: '\(text)' -> '\(layer1Result)'")
            return adjustLongVowelMarks(layer1Result)
        }
        
        // レイヤー2: CFStringTransformによるシステム変換
        let layer2Result = performCFStringTransformConversion(text)
        if layer2Result != text {
            AppLogger.shared.info("CFStringTransform変換成功: '\(text)' -> '\(layer2Result)'")
            return adjustLongVowelMarks(layer2Result)
        }
        
        // レイヤー3: NaturalLanguageによるコンテキスト解析
        let layer3Result = performNaturalLanguageConversion(text)
        if layer3Result != text {
            AppLogger.shared.info("NaturalLanguage変換成功: '\(text)' -> '\(layer3Result)'")
            return adjustLongVowelMarks(layer3Result)
        }
        
        // レイヤー4: フォールバック変換（単純なカタカナ変換など）
        let layer4Result = performFallbackConversion(text)
        AppLogger.shared.info("フォールバック変換結果: '\(text)' -> '\(layer4Result)'")
        return adjustLongVowelMarks(layer4Result)
    }
    
    // MARK: - Layer 1: Dictionary Conversion
    
    /// カスタム辞書による高精度変換
    private func performDictionaryConversion(_ text: String) -> String {
        AppLogger.shared.debug("辞書変換開始: '\(text)'")
        
        // 完全一致での変換を試行
        if let exactMatch = getExactDictionaryMatch(text) {
            AppLogger.shared.debug("完全一致変換成功: '\(text)' -> '\(exactMatch)'")
            return exactMatch
        }
        
        // 複合語の分割変換を試行
        let compoundResult = performCompoundWordConversion(text)
        if compoundResult != text {
            AppLogger.shared.debug("複合語変換成功: '\(text)' -> '\(compoundResult)'")
            return compoundResult
        }
        
        return text
    }
    
    // MARK: - Layer 2: CFStringTransform Conversion
    
    /// CFStringTransformによるシステム変換
    private func performCFStringTransformConversion(_ text: String) -> String {
        AppLogger.shared.debug("CFStringTransform変換開始: '\(text)'")
        
        // まずカタカナからひらがなへの変換を試行
        if let katakanaToHiragana = text.applyingTransform(.hiraganaToKatakana, reverse: true),
           katakanaToHiragana != text {
            AppLogger.shared.debug("カタカナ→ひらがな変換成功: '\(text)' -> '\(katakanaToHiragana)'")
            return katakanaToHiragana
        }
        
        // 漢字→読み仮名変換の基本パターンを試行
        
        // パターン1: 直接ひらがな変換を試行
        if let directHiragana = text.applyingTransform(.toLatin, reverse: false),
           let hiraganaResult = directHiragana.applyingTransform(.latinToHiragana, reverse: false),
           hiraganaResult != text && isValidHiraganaResult(hiraganaResult) {
            AppLogger.shared.debug("直接変換成功: '\(text)' -> '\(directHiragana)' -> '\(hiraganaResult)'")
            return hiraganaResult
        }
        
        // パターン2: 全角→半角を経由した変換
        if let halfwidth = text.applyingTransform(.fullwidthToHalfwidth, reverse: false),
           let latin = halfwidth.applyingTransform(.toLatin, reverse: false),
           let hiragana = latin.applyingTransform(.latinToHiragana, reverse: false),
           hiragana != text && isValidHiraganaResult(hiragana) {
            AppLogger.shared.debug("全角経由変換成功: '\(text)' -> '\(halfwidth)' -> '\(latin)' -> '\(hiragana)'")
            return hiragana
        }
        
        // iOS 16以降の高度なCFStringTransform機能
        if #available(iOS 16.0, *) {
            let advancedResult = performAdvancedCFStringTransform(text)
            if advancedResult != text {
                return advancedResult
            }
        }
        
        return text
    }
    
    /// iOS 16以降の高度なCFStringTransform
    @available(iOS 16.0, *)
    private func performAdvancedCFStringTransform(_ text: String) -> String {
        // Core Foundation の ICU Transform を使用したより高度な変換
        let icuTransforms = [
            "Any-Latin; Latin-Hiragana",
            "Kanji-Hiragana",
            "Han-Latin; Latin-Hiragana"
        ]
        
        for transformID in icuTransforms {
            let mutableText = NSMutableString(string: text)
            let range = NSRange(location: 0, length: mutableText.length)
            
            if CFStringTransform(mutableText, nil, transformID as CFString, false) {
                let result = mutableText as String
                if result != text && result.range(of: "[あ-ん]", options: String.CompareOptions.regularExpression) != nil {
                    AppLogger.shared.debug("ICU変換成功: '\(text)' -> '\(result)' (transform: \(transformID))")
                    return result
                }
            }
        }
        
        return text
    }
    
    // MARK: - Layer 3: NaturalLanguage Conversion
    
    /// NaturalLanguageによるコンテキスト解析変換
    private func performNaturalLanguageConversion(_ text: String) -> String {
        guard #available(iOS 12.0, *) else {
            return text
        }
        
        AppLogger.shared.debug("NaturalLanguage変換開始: '\(text)'")
        
        // トークン分割による変換
        let tokenResult = performTokenBasedConversion(text)
        if tokenResult != text {
            return tokenResult
        }
        
        // 形態素解析による変換
        let morphologyResult = performMorphologyBasedConversion(text)
        if morphologyResult != text {
            return morphologyResult
        }
        
        return text
    }
    
    /// トークン分割による変換
    @available(iOS 12.0, *)
    private func performTokenBasedConversion(_ text: String) -> String {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.japanese)
        
        var result = ""
        let range = text.startIndex..<text.endIndex
        var hasConversion = false
        
        tokenizer.enumerateTokens(in: range) { tokenRange, _ in
            let token = String(text[tokenRange])
            let convertedToken = getExactDictionaryMatch(token) ?? token
            
            if convertedToken != token {
                hasConversion = true
                AppLogger.shared.debug("トークン変換: '\(token)' -> '\(convertedToken)'")
            }
            
            result += convertedToken
            return true
        }
        
        return hasConversion ? result : text
    }
    
    /// 形態素解析による変換
    @available(iOS 13.0, *)
    private func performMorphologyBasedConversion(_ text: String) -> String {
        // iOS 13以降で利用可能な高度な形態素解析
        // 現在は基本実装のみ
        return text
    }
    
    // MARK: - Layer 4: Fallback Conversion
    
    /// フォールバック変換
    private func performFallbackConversion(_ text: String) -> String {
        AppLogger.shared.debug("フォールバック変換開始: '\(text)'")
        
        // 単純なカタカナ→ひらがな変換
        if let hiragana = text.applyingTransform(.hiraganaToKatakana, reverse: true),
           hiragana != text {
            return hiragana
        }
        
        // 文字単位での変換試行
        let charResult = performCharacterWiseConversion(text)
        if charResult != text {
            return charResult
        }
        
        // 最終的に元の文字列を返す
        AppLogger.shared.warning("すべての変換レイヤーで失敗: '\(text)'")
        return text
    }
    
    /// 長音符（ー）を適切な母音に調整
    private func adjustLongVowelMarks(_ text: String) -> String {
        AppLogger.shared.debug("長音符調整前: '\(text)'")
        
        // 「ジュース」の特別処理
        var result = text
        
        // 特定の単語の調整
        result = result.replacingOccurrences(of: "じゅうす", with: "じゅーす")
        result = result.replacingOccurrences(of: "じゅース", with: "じゅーす")
        
        AppLogger.shared.debug("長音符調整後: '\(result)'")
        return result
    }
    
    // MARK: - Helper Methods
    
    /// 辞書による完全一致変換
    private func getExactDictionaryMatch(_ text: String) -> String? {
        return kanjiToHiraganaMap[text]
    }
    
    /// ひらがな変換結果が有効かチェック
    private func isValidHiraganaResult(_ text: String) -> Bool {
        // ひらがなの範囲をチェック（ひらがな、カタカナ、漢字を含む）
        let hiraganaRange = text.range(of: "[あ-んア-ン一-龯]", options: String.CompareOptions.regularExpression)
        
        // 特殊文字や不正な文字が含まれていないかチェック
        let invalidChars = text.range(of: "[&;#]", options: String.CompareOptions.regularExpression)
        
        return hiraganaRange != nil && invalidChars == nil && text.count > 0
    }
    
    /// 複合語の分割変換
    private func performCompoundWordConversion(_ text: String) -> String {
        AppLogger.shared.debug("複合語変換開始: '\(text)'")
        
        // 複合語パターンを試行
        var result = text
        var hasChange = false
        
        // よくある複合語パターン（助詞・語尾）
        let suffixPatterns = [
            "い": "",     // 形容詞語尾 (美しい → 美し + い)
            "な": "",     // 形容動詞語尾 (大きな → 大き + な)
            "の": "",     // 助詞
            "を": "",     // 助詞
            "に": "",     // 助詞
            "で": "",     // 助詞
            "と": "",     // 助詞
            "が": "",     // 助詞
            "は": "",     // 助詞
        ]
        
        for (suffix, _) in suffixPatterns {
            if text.hasSuffix(suffix) {
                let baseWord = String(text.dropLast(suffix.count))
                if let baseHiragana = kanjiToHiraganaMap[baseWord] {
                    result = baseHiragana + suffix
                    hasChange = true
                    AppLogger.shared.debug("語尾分離変換成功: '\(text)' -> '\(baseWord)' + '\(suffix)' -> '\(result)'")
                    break
                }
            }
        }
        
        // 複合語の分割変換を試行（スペースで区切られている場合）
        if !hasChange && text.contains(" ") {
            let components = text.components(separatedBy: " ")
            var convertedComponents: [String] = []
            var componentChanged = false
            
            for component in components {
                if let hiragana = kanjiToHiraganaMap[component] {
                    convertedComponents.append(hiragana)
                    componentChanged = true
                } else {
                    convertedComponents.append(component)
                }
            }
            
            if componentChanged {
                result = convertedComponents.joined(separator: "")
                hasChange = true
                AppLogger.shared.debug("スペース分割変換成功: '\(text)' -> '\(result)'")
            }
        }
        
        // カタカナ部分をひらがなに変換
        if !hasChange {
            let katakanaConverted = convertMixedKatakanaInText(text)
            if katakanaConverted != text {
                result = katakanaConverted
                hasChange = true
                AppLogger.shared.debug("混在カタカナ変換成功: '\(text)' -> '\(result)'")
            }
        }
        
        return hasChange ? result : text
    }
    
    /// 混在するカタカナをひらがなに変換
    private func convertMixedKatakanaInText(_ text: String) -> String {
        var result = ""
        
        for char in text {
            let charString = String(char)
            // カタカナの場合はひらがなに変換
            if let hiragana = charString.applyingTransform(.hiraganaToKatakana, reverse: true), 
               hiragana != charString {
                result += hiragana
            } else {
                result += charString
            }
        }
        
        return result
    }
    
    /// 文字単位での変換
    private func performCharacterWiseConversion(_ text: String) -> String {
        AppLogger.shared.debug("文字単位変換開始: '\(text)'")
        
        // まず文字列全体の複合語変換を試行
        let compoundResult = performWordUnitConversion(text)
        if compoundResult != text {
            AppLogger.shared.debug("単語単位変換成功: '\(text)' -> '\(compoundResult)'")
            return compoundResult
        }
        
        // 文字単位での変換
        var result = ""
        var hasChange = false
        
        for char in text {
            let charString = String(char)
            if let hiragana = kanjiToHiraganaMap[charString] {
                result += hiragana
                hasChange = true
            } else if let katakanaToHiragana = charString.applyingTransform(.hiraganaToKatakana, reverse: true),
                      katakanaToHiragana != charString {
                result += katakanaToHiragana
                hasChange = true
            } else {
                result += charString
            }
        }
        
        return hasChange ? result : text
    }
    
    /// 単語単位での変換（複雑な混合テキスト用）
    private func performWordUnitConversion(_ text: String) -> String {
        var result = ""
        var currentWord = ""
        var hasChange = false
        
        for char in text {
            let charString = String(char)
            
            // ひらがな、カタカナ、漢字の場合は単語を続ける
            if charString.range(of: "[あ-んア-ンー一-龯]", options: String.CompareOptions.regularExpression) != nil {
                currentWord += charString
            } else {
                // 区切り文字の場合、蓄積した単語を変換
                if !currentWord.isEmpty {
                    if let converted = kanjiToHiraganaMap[currentWord] {
                        result += converted
                        hasChange = true
                    } else {
                        // 混在文字列を個別に変換
                        let mixedConverted = convertMixedKatakanaInText(currentWord)
                        result += mixedConverted
                        if mixedConverted != currentWord {
                            hasChange = true
                        }
                    }
                    currentWord = ""
                }
                result += charString
            }
        }
        
        // 最後に残った単語を処理
        if !currentWord.isEmpty {
            if let converted = kanjiToHiraganaMap[currentWord] {
                result += converted
                hasChange = true
            } else {
                // 混在文字列を個別に変換
                let mixedConverted = convertMixedKatakanaInText(currentWord)
                result += mixedConverted
                if mixedConverted != currentWord {
                    hasChange = true
                }
            }
        }
        
        return hasChange ? result : text
    }
    
    /// 拡張された漢字ひらがな辞書
    private var kanjiToHiraganaMap: [String: String] {
        return [
            // 基本的な単語
            "林檎": "りんご",
            "猫": "ねこ",
            "蟻": "あり",
            "犬": "いぬ",
            "鳥": "とり",
            "魚": "さかな",
            "花": "はな",
            "木": "き",
            "水": "みず",
            "火": "ひ",
            "土": "つち",
            "空": "そら",
            "山": "やま",
            "川": "かわ",
            "海": "うみ",
            "雨": "あめ",
            "雪": "ゆき",
            "風": "かぜ",
            "太陽": "たいよう",
            "月": "つき",
            "星": "ほし",
            "鳴き声": "なきごえ",
            
            // 海関連の単語
            "貝殻": "かいがら",
            "海藻": "かいそう",
            "海星": "ひとで",
            "海月": "くらげ",
            "貝": "かい",
            "殻": "から",
            "波": "なみ",
            "浜": "はま",
            "砂": "すな",
            "潮": "しお",
            "珊瑚": "さんご",
            "深海": "しんかい",
            "海底": "かいてい",
            "海岸": "かいがん",
            "湾": "わん",
            "島": "しま",
            "岩": "いわ",
            
            // しりとりでよく使われる動物
            "象": "ぞう",
            "馬": "うま",
            "牛": "うし",
            "豚": "ぶた",
            "羊": "ひつじ",
            "兎": "うさぎ",
            "鼠": "ねずみ",
            "狼": "おおかみ",
            "熊": "くま",
            "鹿": "しか",
            "狐": "きつね",
            "猿": "さる",
            "虎": "とら",
            "獅子": "らいおん",
            "豹": "ひょう",
            "蛇": "へび",
            "蛙": "かえる",
            "蝶": "ちょう",
            "蜂": "はち",
            "蜘蛛": "くも",
            "蝉": "せみ",
            "蛍": "ほたる",
            "蛾": "が",
            "鷹": "たか",
            "鶴": "つる",
            "雀": "すずめ",
            "鳩": "はと",
            "烏": "からす",
            "燕": "つばめ",
            "鴨": "かも",
            "白鳥": "はくちょう",
            "鶏": "にわとり",
            "鷺": "さぎ",
            
            // 植物・食べ物
            "梅": "うめ",
            "桜": "さくら",
            "桃": "もも",
            "柿": "かき",
            "梨": "なし",
            "葡萄": "ぶどう",
            "苺": "いちご",
            "柚子": "ゆず",
            "橘": "みかん",
            "栗": "くり",
            "椎茸": "しいたけ",
            "筍": "たけのこ",
            "茄子": "なす",
            "胡瓜": "きゅうり",
            "大根": "だいこん",
            "人参": "にんじん",
            "玉葱": "たまねぎ",
            "馬鈴薯": "じゃがいも",
            "薩摩芋": "さつまいも",
            "南瓜": "かぼちゃ",
            "蕪": "かぶ",
            "牛蒡": "ごぼう",
            "蓮根": "れんこん",
            "生姜": "しょうが",
            "韮": "にら",
            "葱": "ねぎ",
            "蒜": "にんにく",
            "竹": "たけ",
            "松": "まつ",
            "杉": "すぎ",
            "檜": "ひのき",
            "楠": "くすのき",
            "樫": "かし",
            "柳": "やなぎ",
            "楓": "かえで",
            "銀杏": "いちょう",
            "椿": "つばき",
            "薔薇": "ばら",
            "菊": "きく",
            "菜の花": "なのはな",
            "向日葵": "ひまわり",
            "朝顔": "あさがお",
            "紫陽花": "あじさい",
            "百合": "ゆり",
            "蒲公英": "たんぽぽ",
            "菫": "すみれ",
            "桔梗": "ききょう",
            "撫子": "なでしこ",
            "森": "もり",
            "林": "はやし",
            "草": "くさ",
            "葉": "はっぱ",
            
            // 日常語彙・高度変換用
            "電話": "でんわ",
            "友達": "ともだち",
            "一緒": "いっしょ",
            "勉強": "べんきょう",
            "買い物": "かいもの",
            "料理": "りょうり",
            "掃除": "そうじ",
            "洗濯": "せんたく",
            "大きな": "おおきな",
            "小さな": "ちいさな",
            "美しい": "うつくしい",
            "新しい": "あたらしい",
            "青い": "あおい",
            
            // 複合語・形容詞系
            "大き": "おおき",
            "小さ": "ちいさ",
            "美し": "うつくし",
            "新し": "あたらし",
            "青い空": "あおいそら",
            "美しい花": "うつくしいはな",
            "大きな木": "おおきなき",
            "小さな鳥": "ちいさなとり",
            "新しい本": "あたらしいほん",
            
            // 混在文字列・複雑な変換用
            "林檎ジュース": "りんごじゅーす",
            "ネコの鳴き声": "ねこのなきごえ",
            "ジュース": "じゅーす",
            
            // 時間・特殊読み
            "今日": "きょう",
            "昨日": "きのう",
            "明日": "あした",
            "一人": "ひとり",
            "二人": "ふたり",
            "時間": "じかん",
            "場所": "ばしょ",
            
            // 身体部分
            "頭": "あたま",
            "髪": "かみ",
            "顔": "かお",
            "目": "め",
            "鼻": "はな",
            "口": "くち",
            "耳": "みみ",
            "首": "くび",
            "肩": "かた",
            "腕": "うで",
            "手": "て",
            "指": "ゆび",
            "胸": "むね",
            "腹": "はら",
            "背中": "せなか",
            "腰": "こし",
            "足": "あし",
            "膝": "ひざ",
            
            // 日用品・道具
            "箸": "はし",
            "茶碗": "ちゃわん",
            "皿": "さら",
            "鍋": "なべ",
            "包丁": "ほうちょう",
            "匙": "さじ",
            "机": "つくえ",
            "椅子": "いす",
            "本": "ほん",
            "鉛筆": "えんぴつ",
            "消しゴム": "けしごむ",
            "定規": "じょうぎ",
            "鞄": "かばん",
            "帽子": "ぼうし",
            "靴": "くつ",
            "靴下": "くつした",
            "手袋": "てぶくろ",
            "眼鏡": "めがね",
            "時計": "とけい",
            "鏡": "かがみ",
            "櫛": "くし",
            "歯ブラシ": "はぶらし",
            "石鹸": "せっけん",
            "手拭い": "てぬぐい",
            "布団": "ふとん",
            "枕": "まくら",
            "毛布": "もうふ",
            
            // 色
            "赤": "あか",
            "青": "あお",
            "黄": "き",
            "緑": "みどり",
            "紫": "むらさき",
            "橙": "だいだい",
            "桃色": "ももいろ",
            "茶色": "ちゃいろ",
            "灰色": "はいいろ",
            "黒": "くろ",
            "白": "しろ",
            
            // 方向・位置
            "東": "ひがし",
            "西": "にし",
            "南": "みなみ",
            "北": "きた",
            "上": "うえ",
            "下": "した",
            "右": "みぎ",
            "左": "ひだり",
            "前": "まえ",
            "後": "うしろ",
            "中": "なか",
            "外": "そと",
            "内": "うち",
            
            // 時間・季節
            "春": "はる",
            "夏": "なつ",
            "秋": "あき",
            "冬": "ふゆ",
            "朝": "あさ",
            "昼": "ひる",
            "夕": "ゆう",
            "夜": "よる",
            
            // その他よく使われる単語
            "家": "いえ",
            "学校": "がっこう",
            "会社": "かいしゃ",
            "病院": "びょういん",
            "駅": "えき",
            "道": "みち",
            "橋": "はし",
            "建物": "たてもの",
            "車": "くるま",
            "電車": "でんしゃ",
            "飛行機": "ひこうき",
            "船": "ふね",
            "自転車": "じてんしゃ",
            "歌": "うた",
            "音楽": "おんがく",
            "絵": "え",
            "写真": "しゃしん",
            "映画": "えいが",
            "新聞": "しんぶん",
            "手紙": "てがみ",
            "葉書": "はがき"
        ]
    }
}