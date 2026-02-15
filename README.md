# TypeTop

macOS 語音輸入工具 — 按住右側 ⌘ 說話，自動辨識並輸入文字。

![TypeTop](typetop.png)

## 功能

- **語音辨識（STT）**：使用 Groq Whisper 即時將語音轉為文字
- **多供應商 LLM 語意修正**：支援 OpenAI、Groq、DeepSeek、Moonshot (Kimi)、Google Gemini、Ollama (本地)、自訂 endpoint
- **系統級輸入**：辨識結果直接輸入到任何應用程式的游標位置
- **MenuBar 常駐**：不佔 Dock，安靜地在背景等待使用

## 系統需求

- Apple Silicon（M1 / M2 / M3 / M4 / M5）
- macOS 14.0 Sonoma 以上

## 安裝

1. 從 [Releases](https://github.com/Lance70176/TypeTop/releases) 下載 `TypeTop.dmg`
2. 開啟 DMG，將 TypeTop 拖到「應用程式」資料夾
3. 首次開啟時，授權**麥克風**與**輔助使用**權限
4. 點選 MenuBar 麥克風圖示 → 偏好設定 → 填入 API Key

## API Key 設定

TypeTop 需要設定 API Key 才能使用：

### Groq（語音辨識 STT）

1. 前往 [console.groq.com](https://console.groq.com/keys) 註冊／登入
2. 左側選單點「API Keys」→「Create API Key」
3. 複製 `gsk_` 開頭的 Key，貼到設定中的 Groq 欄位

> Groq 提供免費額度，日常語音輸入使用綽綽有餘。

### LLM 語意修正（多供應商）

在「API 設定」頁面選擇 LLM 供應商並填入對應 API Key：

| 供應商 | 預設模型 | API Key 取得 |
|--------|---------|-------------|
| OpenAI | gpt-4o-mini | [platform.openai.com](https://platform.openai.com/api-keys) |
| Groq | llama-3.3-70b-versatile | [console.groq.com](https://console.groq.com/keys) |
| DeepSeek | deepseek-chat | [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| Moonshot (Kimi) | kimi-k2.5 | [platform.moonshot.ai](https://platform.moonshot.ai/console/api-keys) |
| Google Gemini | gemini-2.0-flash | [aistudio.google.com](https://aistudio.google.com/apikey) |
| Ollama (本地) | llama3 | 不需要 API Key |
| 自訂 | 使用者自填 | 使用者自填 |

> STT 和 LLM 可使用不同供應商。例如 Groq 做語音辨識、OpenAI 做語意修正。

## 使用方式

1. 確認 MenuBar 出現麥克風圖示
2. 將游標放在任何輸入框
3. **按住右側 ⌘ 鍵**開始說話
4. **放開按鍵**，文字會自動辨識、修正後輸入

## 偏好設定

### 語言設定

- **辨識語言**：選擇主要語言（預設繁體中文），Whisper 會優先辨識該語言
- **中英文混合模式**：開啟後可同時辨識中英文混雜的語句
- **標點符號風格**：選擇全形或半形標點
- **中英文自動加空格**：在中文與英文之間自動插入空格，提升可讀性
- **Whisper 提示詞**：加入常用專有名詞（如公司名、技術術語），幫助 Whisper 提升辨識準確度
- **LLM 語意修正**：可開關 LLM 後處理，關閉後直接輸出 Whisper 原始辨識結果
- **LLM 系統提示詞**：自訂 LLM 的改寫風格，例如調整正式程度或特定領域用語

### 詞彙庫

詞彙庫用於修正 Whisper 經常辨識錯誤的詞彙，例如：

| 辨識錯誤（來源） | 正確文字（目標） | 說明 |
|---|---|---|
| 太好了 | TypeTop | App 名稱 |
| 瑞乃特 | React | 前端框架 |
| 派森 | Python | 程式語言 |

- 點擊 **+** 新增替換規則
- 支援**匯出 / 匯入** JSON 格式，方便備份或分享
- 每條規則可獨立啟用或停用

## 開發

本專案使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 管理 Xcode 專案。

```bash
# 安裝 XcodeGen
brew install xcodegen

# 產生 Xcode 專案
xcodegen generate

# 用 Xcode 開啟
open TypeTop.xcodeproj
```

### 打包 DMG

```bash
cd build
./build_dmg.sh
```

DMG 會產生在 `build/TypeTop.dmg`。

## 技術架構

| 元件 | 技術 |
|------|------|
| UI 框架 | SwiftUI + AppKit |
| 快捷鍵 | CGEvent Tap（右側 ⌘，keyCode 54） |
| 錄音 | AVFoundation（16kHz, 16-bit, mono WAV） |
| 語音辨識 | Groq Whisper API（whisper-large-v3-turbo） |
| 語意修正 | 多供應商 LLM（OpenAI 相容 Chat Completion API） |
| 文字輸入 | CGEvent 鍵盤事件模擬 |
| 設定儲存 | UserDefaults + Keychain（API Key） |
| 專案管理 | XcodeGen（project.yml） |
