import Foundation

/// LLM 修正提示詞與 Whisper 提示詞的預設值。
///
/// 這些提示詞跟著**辨識語言**走（不是介面語言）—— 決定輸出文字用哪種語言的是辨識語言。
enum PromptTemplates {

    // MARK: - Whisper 提示詞

    static func whisperPrompt(for language: SupportedLanguage) -> String {
        switch language {
        case .zhHant:
            return "繁體中文語音輸入，可能包含英文單字如 API、iPhone、React、TypeScript、macOS 等技術術語。"
        case .zhHans:
            return "简体中文语音输入，可能包含英文单词如 API、iPhone、React、TypeScript、macOS 等技术术语。"
        case .en:
            return "English dictation that may include technical terms such as API, iPhone, React, TypeScript and macOS."
        case .ja:
            return "日本語の音声入力です。API、iPhone、React、TypeScript、macOS などの技術用語が含まれることがあります。"
        case .ko:
            return "한국어 음성 입력입니다. API, iPhone, React, TypeScript, macOS 같은 기술 용어가 포함될 수 있습니다."
        }
    }

    /// 是否為某個語言的預設 Whisper 提示詞（用來判斷使用者有沒有自己改過）
    static func isDefaultWhisperPrompt(_ prompt: String) -> Bool {
        SupportedLanguage.allCases.contains { whisperPrompt(for: $0) == prompt }
    }

    // MARK: - LLM 修正提示詞

    static func correctionPrompt(level: LLMCorrectionLevel, language: SupportedLanguage) -> String {
        switch language {
        case .zhHant: return zhHant(level)
        case .zhHans: return zhHans(level)
        case .en, .ja, .ko: return english(level, outputLanguage: language)
        }
    }

    /// 是否為任一語言／任一程度的預設提示詞
    static func isDefaultCorrectionPrompt(_ prompt: String) -> Bool {
        for language in SupportedLanguage.allCases {
            for level in LLMCorrectionLevel.allCases where correctionPrompt(level: level, language: language) == prompt {
                return true
            }
        }
        return false
    }

    // MARK: - 繁體中文

    private static func zhHant(_ level: LLMCorrectionLevel) -> String {
        switch level {
        case .none:
            return """
                你是語音輸入的標點助手。使用者透過語音輸入文字，你只需要加上標點符號。

                規則：
                1. 完全保留原文的每一個字，不要刪除、替換或改寫任何詞語
                2. 只加上適當的標點符號（逗號、句號、問號、驚嘆號）
                3. 使用繁體中文標點
                4. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                5. 直接輸出結果，不要加任何解釋
                """
        case .light:
            return """
                你是語音輸入的修正助手。使用者透過語音輸入文字，你要做最小幅度的修正。

                規則：
                1. 保留原文的語氣和用詞風格，包括口語表達
                2. 只修正明顯的錯字和語音辨識錯誤
                3. 加上適當的標點符號
                4. 使用繁體中文，不要用簡體
                5. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                6. 不要刪除任何內容，不要改變語序
                7. 直接輸出修正後的文字，不要加任何解釋
                """
        case .medium:
            return """
                你是語音輸入的改寫助手。使用者透過語音輸入文字，你要理解他的意思，然後用通順的書面語重新寫出來。

                規則：
                1. 先理解語意，再用清晰的書面中文改寫，去除口語贅詞（嗯、那個、就是說）
                2. 使用繁體中文，不要用簡體
                3. 加上適當的標點符號，讓句子結構清晰
                4. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                5. 保持原意，但可以調整語序和用詞讓表達更精確
                6. 直接輸出改寫後的文字，不要加任何解釋
                """
        case .heavy:
            return """
                你是語音輸入的精煉助手。使用者透過語音輸入文字，你要將內容大幅精煉為精確、簡潔的書面語。

                規則：
                1. 深度理解語意後，用最精煉的書面中文重新表達
                2. 刪除所有口語贅詞、重複表達和不必要的修飾
                3. 重組句子結構，讓邏輯更清晰
                4. 使用繁體中文，不要用簡體
                5. 加上適當的標點符號
                6. 英文專有名詞保持正確拼寫（如 API、iPhone、React、TypeScript、macOS）
                7. 直接輸出精煉後的文字，不要加任何解釋
                """
        }
    }

    // MARK: - 简体中文

    private static func zhHans(_ level: LLMCorrectionLevel) -> String {
        switch level {
        case .none:
            return """
                你是语音输入的标点助手。用户通过语音输入文字，你只需要加上标点符号。

                规则：
                1. 完全保留原文的每一个字，不要删除、替换或改写任何词语
                2. 只加上适当的标点符号（逗号、句号、问号、感叹号）
                3. 使用简体中文标点
                4. 英文专有名词保持正确拼写（如 API、iPhone、React、TypeScript、macOS）
                5. 直接输出结果，不要加任何解释
                """
        case .light:
            return """
                你是语音输入的修正助手。用户通过语音输入文字，你要做最小幅度的修正。

                规则：
                1. 保留原文的语气和用词风格，包括口语表达
                2. 只修正明显的错字和语音识别错误
                3. 加上适当的标点符号
                4. 使用简体中文，不要用繁体
                5. 英文专有名词保持正确拼写（如 API、iPhone、React、TypeScript、macOS）
                6. 不要删除任何内容，不要改变语序
                7. 直接输出修正后的文字，不要加任何解释
                """
        case .medium:
            return """
                你是语音输入的改写助手。用户通过语音输入文字，你要理解他的意思，然后用通顺的书面语重新写出来。

                规则：
                1. 先理解语意，再用清晰的书面中文改写，去除口语赘词（嗯、那个、就是说）
                2. 使用简体中文，不要用繁体
                3. 加上适当的标点符号，让句子结构清晰
                4. 英文专有名词保持正确拼写（如 API、iPhone、React、TypeScript、macOS）
                5. 保持原意，但可以调整语序和用词让表达更精确
                6. 直接输出改写后的文字，不要加任何解释
                """
        case .heavy:
            return """
                你是语音输入的精炼助手。用户通过语音输入文字，你要将内容大幅精炼为精确、简洁的书面语。

                规则：
                1. 深度理解语意后，用最精炼的书面中文重新表达
                2. 删除所有口语赘词、重复表达和不必要的修饰
                3. 重组句子结构，让逻辑更清晰
                4. 使用简体中文，不要用繁体
                5. 加上适当的标点符号
                6. 英文专有名词保持正确拼写（如 API、iPhone、React、TypeScript、macOS）
                7. 直接输出精炼后的文字，不要加任何解释
                """
        }
    }

    // MARK: - English / 日本語 / 한국어（以英文指令 + 指定輸出語言）

    private static func english(_ level: LLMCorrectionLevel, outputLanguage: SupportedLanguage) -> String {
        let name = outputLanguageName(outputLanguage)
        switch level {
        case .none:
            return """
                You add punctuation to dictated text. The user speaks; you only insert punctuation.

                Rules:
                1. Keep every word exactly as dictated — never delete, replace or reword anything
                2. Only add appropriate punctuation (commas, periods, question marks, exclamation marks)
                3. Write the result in \(name)
                4. Keep proper nouns correctly spelled (API, iPhone, React, TypeScript, macOS)
                5. Output the result only, with no explanation
                """
        case .light:
            return """
                You lightly clean up dictated text. The user speaks; you make the smallest possible corrections.

                Rules:
                1. Preserve the speaker's tone and word choice, including casual phrasing
                2. Fix only obvious typos and speech-recognition errors
                3. Add appropriate punctuation
                4. Write the result in \(name)
                5. Keep proper nouns correctly spelled (API, iPhone, React, TypeScript, macOS)
                6. Do not delete anything and do not reorder the sentence
                7. Output the corrected text only, with no explanation
                """
        case .medium:
            return """
                You rewrite dictated text. Understand what the speaker meant, then express it in clear written prose.

                Rules:
                1. Grasp the meaning first, then rewrite clearly, dropping filler words (um, you know, like)
                2. Write the result in \(name)
                3. Add punctuation so the sentence structure is clear
                4. Keep proper nouns correctly spelled (API, iPhone, React, TypeScript, macOS)
                5. Preserve the original meaning, but you may reorder and reword for precision
                6. Output the rewritten text only, with no explanation
                """
        case .heavy:
            return """
                You condense dictated text into precise, concise written prose.

                Rules:
                1. Understand the meaning deeply, then re-express it as tightly as possible
                2. Remove all filler words, repetition and unnecessary qualifiers
                3. Restructure sentences so the logic is clearer
                4. Write the result in \(name)
                5. Add appropriate punctuation
                6. Keep proper nouns correctly spelled (API, iPhone, React, TypeScript, macOS)
                7. Output the condensed text only, with no explanation
                """
        }
    }

    private static func outputLanguageName(_ language: SupportedLanguage) -> String {
        switch language {
        case .zhHant: return "Traditional Chinese"
        case .zhHans: return "Simplified Chinese"
        case .en: return "English"
        case .ja: return "Japanese"
        case .ko: return "Korean"
        }
    }
}
