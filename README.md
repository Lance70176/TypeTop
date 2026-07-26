# TypeTop

**繁體中文** · [简体中文](README.zh-Hans.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

**macOS 語音輸入工具 —— 按住右側 ⌘ 說話，放開就把文字打進游標所在的任何地方。**

[![Download](https://img.shields.io/github/v/release/Lance70176/TypeTop?label=下載最新版&style=for-the-badge)](https://github.com/Lance70176/TypeTop/releases/latest)
![macOS](https://img.shields.io/badge/macOS-14.0%2B-black?style=for-the-badge&logo=apple)
![Apple Silicon](https://img.shields.io/badge/Apple-Silicon-blue?style=for-the-badge)

![TypeTop](typetop.png)

---

## 下載安裝

**➡️ [直接下載 TypeTop.dmg（最新版）](https://github.com/Lance70176/TypeTop/releases/latest/download/TypeTop.dmg)**　·　[所有版本與更新說明](https://github.com/Lance70176/TypeTop/releases)

1. 開啟 DMG，把 **TypeTop** 拖進「應用程式」資料夾
2. 第一次開啟若被系統阻擋（App 未經 Apple 公證）：**系統設定 → 隱私權與安全性**，捲到底點「**強制打開**」
3. 依提示授予**麥克風**與**輔助使用**權限（輔助使用是用來模擬鍵盤輸入，沒有它無法打字）
4. 點選單列的麥克風圖示 → **偏好設定 → API 設定**，填入 Groq API Key
5. 把游標放進任何輸入框，**按住右側 ⌘** 說話，放開即輸入

> 系統需求：**Apple Silicon**（M1 以上）、**macOS 14.0 Sonoma** 以上。

---

## 功能

### 輸入體驗

- **按住說話（Push-to-talk）**：按住啟動鍵錄音，放開就辨識並輸入，全程不用切視窗
- **啟動鍵可自訂**：右側 ⌘（預設）、左側 ⌘、左右 ⌥、左右 ⌃、fn 共七種
- **隨處可用**：以系統層級的鍵盤事件輸入文字，任何 App 的任何輸入框都能用
- **隨時取消**：錄音中按下其他修飾鍵（⌥ / ⌃ / fn 等）即取消這次錄音，不會輸入任何文字
- **錄音浮層與音效**：螢幕角落顯示錄音狀態與音量，選單列圖示同步變化，提示音可開關
- **錄音時靜音系統音訊**：說話時自動壓下背景音樂／影片聲音，避免被一起錄進去
- **選單列常駐**：不佔 Dock，可設定開機自動啟動
- **五種介面語言**：繁體中文、简体中文、English、日本語、한국어，設定裡即時切換不用重啟

### 辨識與修正

- **語音辨識（STT）**：Groq Whisper `whisper-large-v3-turbo`，速度快、免費額度足夠日常使用
- **LLM 語意修正**：辨識完再讓 LLM 修錯字、補標點，支援 8 種供應商（含**完全離線**的 Apple 本機模型）
- **修正程度可調**：無修正／輕微／中等／重度，從「只加標點」到「重組句子結構」，也可直接改系統提示詞
- **取樣溫度可調**：預設 0.3，越低輸出越穩定
- **中英文混合模式**：同一句話中英夾雜也能正確辨識
- **標點符號風格**：全形 `，。！？`／半形 `,.!?`／完全移除／保持原樣
- **中英文自動加空格**：`使用React框架` → `使用 React 框架`
- **Whisper 提示詞**：先告訴 Whisper 你常講的專有名詞，提升辨識準確度

### 帳號與額度

- **多組 API 帳號**：同一供應商可存多組 Key，並可自訂名稱（例如「工作帳號」「備用帳號」）
- **額度自動切換**：某組 Key 觸發 HTTP 429（達額度上限）時，自動換到下一組繼續用
- **檢視／編輯 Key**：既有帳號可展開修改名稱與 Key，不必刪掉重加，用量統計也不會歸零
- **用量統計**：顯示今日 STT／LLM 請求次數與 tokens，Groq 另外顯示官方回報的即時剩餘額度

### 詞彙庫

- **替換規則**：修正 Whisper 常錯的詞（`太好了` → `TypeTop`、`派森` → `Python`），每條可獨立啟用／停用
- **注音個人詞庫匯入**：直接吃 macOS 注音輸入法匯出的個人詞庫（`.txt`），常用詞會自動提示 LLM 修正同音錯字
- **JSON 匯出／匯入**：方便備份或分享詞庫

---

## 畫面

### 一般

快捷鍵、權限狀態、行為開關一目了然。

<img src="docs/screenshots/settings-general.png" width="620" alt="一般設定">

### API 設定

每個供應商都可以存多組帳號，達額度時自動切換；下方是今日用量統計。

<img src="docs/screenshots/settings-api.png" width="620" alt="API 設定">

### 語言

辨識語言、文字處理、Whisper 提示詞、LLM 修正程度與溫度都在這裡。

<img src="docs/screenshots/settings-language.png" width="620" alt="語言設定">

### 詞彙庫

修正常錯詞彙，支援注音個人詞庫與 JSON 匯入匯出。

<img src="docs/screenshots/settings-vocabulary.png" width="620" alt="詞彙庫">

---

## API Key 設定

TypeTop 需要至少一組 **Groq API Key**（語音辨識用）才能運作。

### 語音辨識（STT）— Groq

1. 前往 [console.groq.com](https://console.groq.com/keys) 註冊／登入
2. 左側選單點「API Keys」→「Create API Key」
3. 複製 `gsk_` 開頭的 Key，貼到 **API 設定 → 語音辨識** 的欄位後按「新增帳號」

> Groq 提供免費額度，日常語音輸入綽綽有餘。額度不夠可以再申請一組帳號加進去，用完會自動切換。

### 語意修正（LLM）

在「API 設定 → 語意修正」選擇供應商並填入對應 Key：

| 供應商 | 預設模型 | 需要 API Key | 取得位置 |
|--------|---------|:---:|-------------|
| OpenAI | `gpt-4o-mini` | ✅ | [platform.openai.com](https://platform.openai.com/api-keys) |
| Groq | `llama-3.3-70b-versatile` | ✅ | [console.groq.com](https://console.groq.com/keys) |
| DeepSeek | `deepseek-chat` | ✅ | [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| Moonshot (Kimi) | `kimi-k2.5` | ✅ | [platform.moonshot.ai](https://platform.moonshot.ai/console/api-keys) |
| Google Gemini | `gemini-3.1-flash-lite` | ✅ | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **Apple 本機模型** | 系統內建（on-device） | ❌ | 免設定，需 macOS 26+ 並已開啟 Apple Intelligence |
| Ollama（本地） | `llama3` | ❌ | [ollama.com](https://ollama.com) |
| 自訂 | 自填 | 依 endpoint | 任何 OpenAI 相容的 Chat Completion API |

> STT 與 LLM 可以用不同供應商，例如 Groq 負責語音轉文字、OpenAI 負責語意修正。
> 想讓內容完全不離開電腦，就把 LLM 設成 **Apple 本機模型** 或 **Ollama**。

---

## 偏好設定說明

### 一般

| 項目 | 說明 |
|------|------|
| 按住說話快捷鍵 | 選擇啟動鍵，共七種修飾鍵可選 |
| 介面語言 | 切換 app 介面語言，與辨識語言相同的五種，即時生效 |
| 輔助使用權限 | 未授權時無法輸入文字，點「前往設定」開啟系統設定 |
| 麥克風權限 | 未授權時無法錄音 |
| 播放音效提示 | 開始／結束錄音時的提示音 |
| 錄音時靜音系統音訊 | 錄音期間自動壓低系統音量，避免背景聲被錄進去 |
| 開機自動啟動 | 登入時自動啟動 TypeTop |

### 語言

| 項目 | 說明 |
|------|------|
| 辨識語言 | 主要語言（預設繁體中文），Whisper 會優先辨識該語言。切換後，未手動改過的 Whisper／LLM 提示詞會自動換成該語言的版本 |
| 中英文混合模式 | 同時辨識中英文夾雜的內容 |
| 中英文之間自動加空格 | `使用React框架` → `使用 React 框架` |
| 標點符號風格 | 全形／半形／無標點／保持原樣 |
| Whisper 提示詞 | 填入常用專有名詞，提升辨識準確度 |
| 啟用 LLM 智慧修正 | 關閉後直接輸出 Whisper 原始結果 |
| 修正程度 | 無修正／輕微／中等／重度，選擇後自動套用對應提示詞 |
| 取樣溫度 | 越低越穩定，錯字修正建議 0～0.3 |
| LLM 系統提示詞 | 可手動改寫，自訂修正風格與領域用語 |

### 詞彙庫

用來修正 Whisper 常辨識錯的詞：

| 辨識錯誤（來源） | 正確文字（目標） | 說明 |
|---|---|---|
| 太好了 | TypeTop | App 名稱 |
| 瑞乃特 | React | 前端框架 |
| 派森 | Python | 程式語言 |

- 點 **+** 新增規則，每條可獨立啟用／停用
- 支援 **JSON 匯出／匯入**，方便備份或分享
- 支援匯入 **macOS 注音輸入法個人詞庫**（`.txt`）

---

## 常見問題

**按住 ⌘ 沒反應？**
先確認選單列有麥克風圖示，再到「一般」頁看**輔助使用權限**是否已授權。重新安裝或換版本後，權限有時需要重新勾選一次。

**辨識不準怎麼辦？**
三個地方可以調：在「語言 → Whisper 提示詞」加入常用專有名詞、在「詞彙庫」建立替換規則、把「修正程度」調高讓 LLM 幫忙改寫。

**額度用完了？**
在「API 設定」對同一個供應商新增第二組帳號，觸發 429 時會自動切到下一組。也可以把 LLM 換成 Apple 本機模型或 Ollama，完全不耗雲端額度。

**說話說到一半想反悔？**
錄音中按下其他修飾鍵（⌥ / ⌃ / fn 等）即可取消，不會輸入任何文字。

**介面可以換語言嗎？**
可以。「一般 → 介面語言」提供繁體中文、简体中文、English、日本語、한국어，選了立刻生效不用重啟。另外「語言 → 辨識語言」是決定你說哪種語言、輸出哪種語言，兩者各自獨立。

**我的語音會被送到哪裡？**
音訊只會送到你設定的 STT 供應商（Groq）；文字修正會送到你選的 LLM 供應商。選 Apple 本機模型或 Ollama 時，修正階段完全在本機進行。API Key 存在本機的 Keychain 與應用程式支援目錄（權限 0600）。

---

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

---

## 技術架構

| 元件 | 技術 |
|------|------|
| UI 框架 | SwiftUI + AppKit |
| 快捷鍵 | CGEvent Tap（可自訂修飾鍵，預設右側 ⌘／keyCode 54） |
| 錄音 | AVFoundation（16kHz, 16-bit, mono WAV） |
| 語音辨識 | Groq Whisper API（whisper-large-v3-turbo） |
| 語意修正 | 多供應商 LLM（OpenAI 相容 Chat Completion API）＋ Apple FoundationModels |
| 文字輸入 | CGEvent 鍵盤事件模擬 |
| 設定儲存 | UserDefaults + Keychain（API Key）＋ `apiaccounts.json`（多帳號，0600） |
| 多語言 | app 內字串表與執行期切換（`TypeTop/Localization`） |
| 專案管理 | XcodeGen（project.yml） |
