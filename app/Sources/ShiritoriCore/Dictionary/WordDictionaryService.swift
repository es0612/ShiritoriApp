//
//  WordDictionaryService.swift
//  ShiritoriApp
//
//  Created on 2025/07/12
//

import Foundation

// MARK: - 難易度レベル
public enum DifficultyLevel: String, CaseIterable, Hashable, Codable {
    case easy = "easy"    // よわい
    case normal = "normal"  // ふつう
    case hard = "hard"    // つよい
    
    public var displayName: String {
        switch self {
        case .easy:
            return "よわい"
        case .normal:
            return "ふつう"
        case .hard:
            return "つよい"
        }
    }
    
    public var description: String {
        switch self {
        case .easy:
            return "かんたんな\nことば"
        case .normal:
            return "ふつうの\nことば"
        case .hard:
            return "むずかしい\nことば"
        }
    }
}

// MARK: - 単語辞書サービス
public final class WordDictionaryService {
    
    // MARK: - 辞書データ
    private let easyWords: [String: [String]]
    private let normalWords: [String: [String]]
    private let hardWords: [String: [String]]
    
    // MARK: - イニシャライザ
    public init() {
        AppLogger.shared.info("WordDictionaryServiceを初期化しています")
        AppLogger.shared.debug("辞書データの読み込み開始")
        
        // 簡単な語彙（子供向け）
        self.easyWords = [
            "あ": ["あめ", "あり", "あか", "あお"],
            "い": ["いぬ", "いえ", "いす", "いも"],
            "う": ["うま", "うし", "うみ", "うえ"],
            "え": ["えび", "えん", "えき"],
            "お": ["おに", "おか", "おと", "おや"],
            "か": ["かに", "かめ", "かみ", "かぜ"],
            "き": ["きつね", "きのこ", "きって", "きもの"],
            "く": ["くま", "くるま", "くじら", "くつ"],
            "け": ["けーき", "けいと", "けむり"],
            "こ": ["ここ", "こま", "こめ", "こおり"],
            "さ": ["さかな", "さる", "さくら", "さとう"],
            "し": ["しか", "しお", "しろ", "しんぶん"],
            "す": ["すいか", "すし", "すずめ", "すな"],
            "せ": ["せんせい", "せみ", "せっけん"],
            "そ": ["そら", "そば", "そふ"],
            "た": ["たまご", "たこ", "たいこ", "たね"],
            "ち": ["ちず", "ちょう", "ちから", "ちゃ"],
            "つ": ["つき", "つくえ", "つめ", "つち"],
            "て": ["てがみ", "てんき", "てぶくろ"],
            "と": ["とり", "とけい", "とまと", "とびら"],
            "な": ["なし", "なべ", "なつ", "なまえ"],
            "に": ["にく", "にわ", "にじ", "にんじん"],
            "ぬ": ["ぬいぐるみ", "ぬの", "ぬま"],
            "ね": ["ねこ", "ねずみ", "ねつ", "ねんど"],
            "の": ["のり", "のど", "のこぎり"],
            "は": ["はな", "はし", "はと", "はこ"],
            "ひ": ["ひよこ", "ひかり", "ひげ", "ひも"],
            "ふ": ["ふね", "ふうせん", "ふろ", "ふくろ"],
            "へ": ["へび", "へや", "へそ"],
            "ほ": ["ほし", "ほん", "ほね", "ほうき"],
            "ま": ["まめ", "まど", "まくら", "まち"],
            "み": ["みず", "みかん", "みち", "みどり"],
            "む": ["むし", "むぎ", "むね", "むら"],
            "め": ["めがね", "めん", "めだか"],
            "も": ["もも", "もり", "もち", "もの"],
            "や": ["やま", "やね", "やさい", "やぎ"],
            "ゆ": ["ゆき", "ゆめ", "ゆび", "ゆかた"],
            "よ": ["よる", "よこ", "よぞら"],
            "ら": ["らいおん", "らくだ", "らっぱ"],
            "り": ["りんご", "りす", "りょうり", "りぼん"],
            "る": ["るーる"],
            "れ": ["れいぞうこ", "れんが", "れもん"],
            "ろ": ["ろうそく", "ろばた", "ろっく"],
            "わ": ["わに", "わた", "わかめ", "わらび"],
            "が": ["がっこう", "がぞう"],
            "ぎ": ["ぎゅうにゅう", "ぎんこう"],
            "ぐ": ["ぐみ", "ぐつ"],
            "げ": ["げんかん", "げーむ"],
            "ご": ["ごはん", "ごみ", "ごま"],
            "ざ": ["ざっし", "ざる"],
            "じ": ["じどうしゃ", "じかん"],
            "ず": ["ずかん", "ずぼん"],
            "ぜ": ["ぜりー", "ぜんぶ"],
            "ぞ": ["ぞう", "ぞうきん"],
            "だ": ["だんごむし", "だいこん"],
            "で": ["でんしゃ", "でんき"],
            "ど": ["どうぶつ", "どあ"],
            "ば": ["ばなな", "ばす"],
            "び": ["びーる", "びじゅつかん"],
            "ぶ": ["ぶた", "ぶどう"],
            "べ": ["べっど", "べんとう"],
            "ぼ": ["ぼうし", "ぼーる"],
            "ぱ": ["ぱん", "ぱんだ"],
            "ぴ": ["ぴあの", "ぴざ"],
            "ぷ": ["ぷーる", "ぷりん"],
            "ぺ": ["ぺんぎん", "ぺん"],
            "ぽ": ["ぽすと", "ぽけっと"]
        ]
        
        // 通常の語彙
        self.normalWords = [
            "あ": ["あめ", "あり", "あか", "あお", "あさ", "あき", "あらし", "あいす"],
            "い": ["いぬ", "いえ", "いす", "いも", "いちご", "いけ", "いわ", "いろ"],
            "う": ["うま", "うし", "うみ", "うえ", "うた", "うでどけい", "うちゅう"],
            "え": ["えび", "えん", "えき", "えんぴつ", "えほん", "えいが"],
            "お": ["おに", "おか", "おと", "おや", "おもちゃ", "おんがく", "おかし"],
            "か": ["かに", "かめ", "かみ", "かぜ", "かばん", "かがみ", "かんがるー"],
            "き": ["きつね", "きのこ", "きって", "きもの", "きんぎょ", "きかんしゃ"],
            "く": ["くま", "くるま", "くじら", "くつ", "くうき", "くるみ", "くろ"],
            "け": ["けーき", "けいと", "けむり", "けしゴム", "けんこう"],
            "こ": ["ここ", "こま", "こめ", "こおり", "こうえん", "こうちょう"],
            "さ": ["さかな", "さる", "さくら", "さとう", "さいふ", "さんぽ"],
            "し": ["しか", "しお", "しろ", "しんぶん", "しゃしん", "しごと"],
            "す": ["すいか", "すし", "すずめ", "すな", "すうじ", "すぽーつ"],
            "せ": ["せんせい", "せみ", "せっけん", "せかい", "せんたく"],
            "そ": ["そら", "そば", "そふ", "そうじ", "そくたつ"],
            "た": ["たまご", "たこ", "たいこ", "たね", "たいよう", "たからもの"],
            "ち": ["ちず", "ちょう", "ちから", "ちゃ", "ちきゅう", "ちゅうもん"],
            "つ": ["つき", "つくえ", "つめ", "つち", "つみき", "つばめ"],
            "て": ["てがみ", "てんき", "てぶくろ", "てれび", "てんしょく"],
            "と": ["とり", "とけい", "とまと", "とびら", "とうきょう", "ともだち"],
            "な": ["なし", "なべ", "なつ", "なまえ", "なにか", "ながれ"],
            "に": ["にく", "にわ", "にじ", "にんじん", "にほん", "にっき"],
            "ぬ": ["ぬいぐるみ", "ぬの", "ぬま", "ぬるま湯"],
            "ね": ["ねこ", "ねずみ", "ねつ", "ねんど", "ねがい", "ねむり"],
            "の": ["のり", "のど", "のこぎり", "のうりょく", "のりもの"],
            "は": ["はな", "はし", "はと", "はこ", "はやし", "はくぶつかん"],
            "ひ": ["ひよこ", "ひかり", "ひげ", "ひも", "ひまわり", "ひこうき"],
            "ふ": ["ふね", "ふうせん", "ふろ", "ふくろ", "ふゆ", "ふうせん"],
            "へ": ["へび", "へや", "へそ", "へんじ", "へいわ"],
            "ほ": ["ほし", "ほん", "ほね", "ほうき", "ほけん", "ほーむ"],
            "ま": ["まめ", "まど", "まくら", "まち", "まつり", "まんが"],
            "み": ["みず", "みかん", "みち", "みどり", "みらい", "みんな"],
            "む": ["むし", "むぎ", "むね", "むら", "むかし", "むりょう"],
            "め": ["めがね", "めん", "めだか", "めざまし", "めいじん"],
            "も": ["もも", "もり", "もち", "もの", "もんだい", "もくよう"],
            "や": ["やま", "やね", "やさい", "やぎ", "やくそく", "やきゅう"],
            "ゆ": ["ゆき", "ゆめ", "ゆび", "ゆかた", "ゆうめい", "ゆうえんち"],
            "よ": ["よる", "よこ", "よぞら", "よてい", "よろこび"],
            "ら": ["らいおん", "らくだ", "らっぱ", "らいねん", "らくがき"],
            "り": ["りんご", "りす", "りょうり", "りぼん", "りょこう", "りゆう"],
            "る": ["るーる", "るすばん"],
            "れ": ["れいぞうこ", "れんが", "れもん", "れきし", "れっしゃ"],
            "ろ": ["ろうそく", "ろばた", "ろっく", "ろんぶん", "ろうじん"],
            "わ": ["わに", "わた", "わかめ", "わらび", "わらい", "わかもの"]
        ]
        
        // 高難易度語彙（返しにくい文字も含む）
        var hardWordsData = normalWords
        
        // 難しい語彙を追加
        hardWordsData["る"] = (hardWordsData["る"] ?? []) + ["るいじ", "るびー", "るーまにあ"]
        hardWordsData["ゆ"] = (hardWordsData["ゆ"] ?? []) + ["ゆうしょう", "ゆうこう", "ゆうざい"]
        hardWordsData["づ"] = ["づつみ", "づら"]
        hardWordsData["ぢ"] = ["ぢめん", "ぢから"]
        
        self.hardWords = hardWordsData
        
        AppLogger.shared.info("辞書初期化完了: easy=\(getTotalWordCount(easyWords))語, normal=\(getTotalWordCount(normalWords))語, hard=\(getTotalWordCount(hardWords))語")
    }
    
    // MARK: - パブリックメソッド
    
    public func getWordsStartingWith(_ character: String, difficulty: DifficultyLevel) -> [String] {
        AppLogger.shared.debug("文字 '\(character)' で始まる単語を検索 (難易度: \(difficulty))")
        
        let dictionary = getDictionary(for: difficulty)
        let words = dictionary[character] ?? []
        
        AppLogger.shared.debug("検索結果: \(words.count)個の単語が見つかりました")
        
        return words
    }
    
    public func getRandomWord(startingWith character: String, difficulty: DifficultyLevel) -> String? {
        let words = getWordsStartingWith(character, difficulty: difficulty)
        guard !words.isEmpty else {
            AppLogger.shared.warning("文字 '\(character)' で始まる単語が見つかりません (難易度: \(difficulty))")
            return nil
        }
        
        let randomWord = words.randomElement()!
        AppLogger.shared.debug("ランダム選択: '\(randomWord)'")
        
        return randomWord
    }
    
    public func isWordInDictionary(_ word: String, difficulty: DifficultyLevel) -> Bool {
        guard !word.isEmpty && !word.hasSuffix("ん") else {
            AppLogger.shared.debug("単語 '\(word)' は無効です（空文字または「ん」で終わる）")
            return false
        }
        
        let firstChar = String(word.prefix(1))
        let words = getWordsStartingWith(firstChar, difficulty: difficulty)
        let exists = words.contains(word)
        
        AppLogger.shared.debug("辞書チェック: '\(word)' -> \(exists)")
        
        return exists
    }
    
    public func getAllWords(difficulty: DifficultyLevel) -> [String] {
        let dictionary = getDictionary(for: difficulty)
        let allWords = dictionary.values.flatMap { $0 }
        
        AppLogger.shared.debug("全単語取得 (難易度: \(difficulty)): \(allWords.count)語")
        
        return allWords
    }
    
    // MARK: - プライベートメソッド
    
    private func getDictionary(for difficulty: DifficultyLevel) -> [String: [String]] {
        switch difficulty {
        case .easy:
            return easyWords
        case .normal:
            return normalWords
        case .hard:
            return hardWords
        }
    }
    
    private func getTotalWordCount(_ dictionary: [String: [String]]) -> Int {
        return dictionary.values.reduce(0) { $0 + $1.count }
    }
}