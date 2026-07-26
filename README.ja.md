# TypeTop

[繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [English](README.en.md) · **日本語** · [한국어](README.ko.md)

**macOS の音声入力ツール —— 右 ⌘ を押しながら話し、離すとカーソルのある場所に文字が入ります。**

[![Download](https://img.shields.io/github/v/release/Lance70176/TypeTop?label=ダウンロード&style=for-the-badge)](https://github.com/Lance70176/TypeTop/releases/latest)
![macOS](https://img.shields.io/badge/macOS-14.0%2B-black?style=for-the-badge&logo=apple)
![Apple Silicon](https://img.shields.io/badge/Apple-Silicon-blue?style=for-the-badge)

![TypeTop](typetop.png)

---

## インストール

**➡️ [TypeTop.dmg をダウンロード（最新版）](https://github.com/Lance70176/TypeTop/releases/latest/download/TypeTop.dmg)**　·　[すべてのリリースと更新内容](https://github.com/Lance70176/TypeTop/releases)

1. DMG を開き、**TypeTop** を「アプリケーション」フォルダにドラッグします
2. 初回起動がブロックされた場合（Apple の公証を受けていないため）：**システム設定 → プライバシーとセキュリティ** の一番下にある「**このまま開く**」をクリック
3. 求められたら**マイク**と**アクセシビリティ**を許可します（アクセシビリティがないと文字を入力できません）
4. メニューバーのマイクアイコン →**環境設定 → API** で Groq の API キーを入力します
5. 任意の入力欄にカーソルを置き、**右 ⌘ を押しながら**話して離します

> 動作環境：**Apple Silicon**（M1 以降）、**macOS 14.0 Sonoma** 以降。

---

## 機能

### 入力

- **押しながら話す（Push-to-talk）** — キーを押している間だけ録音し、離すと認識して入力。ウインドウを切り替える必要はありません
- **起動キーを選べる** — 右 ⌘（既定）、左 ⌘、左右の ⌥、左右の ⌃、fn の 7 種類
- **どこでも使える** — システムレベルのキーボードイベントで入力するので、どのアプリのどの入力欄でも動作します
- **途中でキャンセル** — 録音中に別の修飾キー（⌥ / ⌃ / fn）を押すと、何も入力せずに取り消せます
- **録音オーバーレイと効果音** — 画面の隅に録音状態と音量を表示し、メニューバーのアイコンも変化します。効果音はオフにできます
- **録音中はシステム音声をミュート** — 音楽や動画の音がマイクに混ざりません
- **メニューバー常駐** — Dock を占有せず、ログイン時の自動起動も設定できます
- **5 つの表示言語** — 繁体字中国語・簡体字中国語・英語・日本語・韓国語。再起動なしで即座に切り替わります

### 認識と補正

- **音声認識（STT）** — Groq Whisper `whisper-large-v3-turbo`。高速で、無料枠が日常利用に十分です
- **LLM による補正** — 認識後に誤字を直し句読点を補います。**完全オフライン**の Apple オンデバイスモデルを含む 8 種類のプロバイダに対応
- **補正の強さは 4 段階** — 「句読点だけ」から「文構造の組み替え」まで。システムプロンプトを直接編集することもできます
- **温度を調整可能** — 既定は 0.3。低いほど安定します
- **多言語ミックスモード** — 主な言語と英語が混ざった文もそのまま認識します
- **句読点のスタイル** — 全角 `，。！？`／半角 `,.!?`／すべて削除／変換しない
- **CJK と英数字の自動スペース** — `使用React框架` → `使用 React 框架`
- **Whisper プロンプト** — よく使う固有名詞をあらかじめ伝えると精度が上がります

### アカウントと利用枠

- **複数の API アカウント** — 同じプロバイダに複数のキーを保存でき、それぞれに名前を付けられます（「仕事用」「予備」など）
- **上限時の自動切り替え** — あるキーが HTTP 429（上限到達）を返すと、次のアカウントへ自動的に切り替わります
- **キーの表示・編集** — 既存アカウントの名前とキーをその場で変更できます。削除して作り直す必要がないので使用量の集計も引き継がれます
- **使用量の表示** — 本日の STT／LLM リクエスト数とトークン数、さらに Groq が返す残り枠をリアルタイムに表示

### 単語登録

- **置き換えルール** — 認識をよく間違える単語を修正します（`太好了` → `TypeTop`、`派森` → `Python`）。ルールごとに有効・無効を切り替えられます
- **注音辞書の読み込み** — macOS の注音入力方式が書き出した個人辞書（`.txt`）をそのまま取り込めます。よく使う語は LLM に渡され、同音異字の誤りを直します
- **JSON の書き出し／読み込み** — バックアップや共有に便利です

---

## スクリーンショット

> 以下のスクリーンショットは繁体字中国語の画面ですが、アプリは 5 言語に対応しています。

### 一般

ショートカット、表示言語、アクセス権の状態、動作のスイッチ。

<img src="docs/screenshots/settings-general.png" width="620" alt="一般設定">

### API

プロバイダごとに複数アカウントを登録でき、上限時は自動で切り替わります。下部は本日の使用量です。

<img src="docs/screenshots/settings-api.png" width="620" alt="API 設定">

### 言語

認識する言語、テキスト処理、Whisper プロンプト、LLM の補正の強さと温度。

<img src="docs/screenshots/settings-language.png" width="620" alt="言語設定">

### 単語登録

よく誤認識される単語を修正します。注音辞書と JSON の入出力に対応。

<img src="docs/screenshots/settings-vocabulary.png" width="620" alt="単語登録">

---

## API キーの設定

TypeTop を使うには、少なくとも 1 つの **Groq API キー**（音声認識用）が必要です。

### 音声認識（STT）— Groq

1. [console.groq.com](https://console.groq.com/keys) で登録／ログイン
2. 左メニューの「API Keys」→「Create API Key」
3. `gsk_` で始まるキーをコピーし、**API → 音声認識** の欄に貼り付けて「アカウントを追加」を押します

> Groq の無料枠は日常の音声入力に十分です。足りなくなったら別アカウントのキーを追加すれば、自動で切り替わります。

### 文章補正（LLM）

**API → 文章補正** でプロバイダを選び、対応するキーを入力します：

| プロバイダ | 既定のモデル | API キー | 取得先 |
|--------|---------|:---:|-------------|
| OpenAI | `gpt-4o-mini` | ✅ | [platform.openai.com](https://platform.openai.com/api-keys) |
| Groq | `llama-3.3-70b-versatile` | ✅ | [console.groq.com](https://console.groq.com/keys) |
| DeepSeek | `deepseek-chat` | ✅ | [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| Moonshot (Kimi) | `kimi-k2.5` | ✅ | [platform.moonshot.ai](https://platform.moonshot.ai/console/api-keys) |
| Google Gemini | `gemini-3.1-flash-lite` | ✅ | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **Apple オンデバイス** | OS 内蔵 | ❌ | 設定不要。macOS 26 以降で Apple Intelligence が有効なこと |
| Ollama（ローカル） | `llama3` | ❌ | [ollama.com](https://ollama.com) |
| カスタム | 自由入力 | 環境による | OpenAI 互換の Chat Completions API |

> STT と LLM は別々のプロバイダを使えます。例えば文字起こしは Groq、補正は OpenAI。
> 内容を Mac の外に出したくない場合は、LLM を **Apple オンデバイスモデル**か **Ollama** にしてください。

---

## 環境設定

### 一般

| 項目 | 説明 |
|------|------|
| 押しながら話すキー | 起動キーを選択（修飾キー 7 種類） |
| 表示言語 | アプリの表示言語を切り替え。認識言語と同じ 5 言語で、即座に反映されます |
| アクセシビリティ | 未許可だと文字を入力できません。「設定を開く」から許可します |
| マイク | 未許可だと録音できません |
| 効果音を鳴らす | 録音の開始・終了時の効果音 |
| 録音中はシステム音声をミュート | 録音中はシステム音量を下げ、背景音の混入を防ぎます |
| ログイン時に起動 | ログイン時に TypeTop を自動起動します |

### 言語

| 項目 | 説明 |
|------|------|
| 認識する言語 | 主な言語（既定は繁体字中国語）。切り替えると、自分で編集していない Whisper／LLM のプロンプトもその言語版に変わります |
| 多言語ミックスモード | 主な言語と英語を同時に認識します |
| CJK と英数字の間に自動でスペース | `使用React框架` → `使用 React 框架` |
| 句読点のスタイル | 全角／半角／なし／そのまま |
| Whisper プロンプト | よく使う固有名詞を入れて精度を上げます |
| LLM 補正を有効にする | オフにすると Whisper の生の結果をそのまま入力します |
| 補正の強さ | なし／弱／中／強。選ぶと既定のプロンプトが適用されます |
| 温度 | 低いほど安定。誤字修正は 0〜0.3 が最適です |
| LLM システムプロンプト | 文体や専門用語に合わせて自由に編集できます |

### 単語登録

認識をよく間違える単語を修正します：

| 誤認識（変換元） | 正しい文字（変換先） | メモ |
|---|---|---|
| 太好了 | TypeTop | アプリ名 |
| 瑞乃特 | React | フロントエンドのフレームワーク |
| 派森 | Python | プログラミング言語 |

- **＋** でルールを追加。ルールごとに有効・無効を切り替えられます
- **JSON の書き出し／読み込み**でバックアップや共有ができます
- **macOS 注音入力方式の個人辞書**（`.txt`）を読み込めます

---

## よくある質問

**⌘ を押しても反応しません。**
まずメニューバーにマイクアイコンがあるか確認し、「一般」タブの**アクセシビリティ**が許可済みか見てください。再インストールやアップデートの後は、許可し直しが必要なことがあります。

**認識精度が上がりません。**
調整できる場所は 3 つあります。「言語 → Whisper プロンプト」によく使う固有名詞を追加する、「単語登録」で置き換えルールを作る、**補正の強さ**を上げて LLM に整えてもらう。

**利用枠を使い切りました。**
API タブで同じプロバイダのアカウントをもう 1 つ追加すると、HTTP 429 のときに自動で切り替わります。LLM を Apple オンデバイスモデルや Ollama にすれば、クラウドの枠を一切使いません。

**表示言語は変えられますか？**
はい。「一般 → 表示言語」で繁体字中国語・簡体字中国語・英語・日本語・韓国語を選べ、再起動なしで反映されます。話す言語・書き出す言語を決める「言語 → 認識する言語」とは独立した設定です。

**音声はどこに送られますか？**
音声は設定した STT プロバイダ（Groq）にのみ送られ、文章の補正は選んだ LLM プロバイダに送られます。Apple オンデバイスモデルや Ollama を選べば、補正はすべてこの Mac の中で完結します。API キーはローカルのキーチェーンとアプリケーションサポートディレクトリ（パーミッション 0600）に保存されます。

---

## 開発

Xcode プロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) で管理しています。

```bash
# XcodeGen をインストール
brew install xcodegen

# Xcode プロジェクトを生成
xcodegen generate

# 開く
open TypeTop.xcodeproj
```

### DMG のビルド

```bash
cd build
./build_dmg.sh
```

DMG は `build/TypeTop.dmg` に生成されます。

---

## 構成

| 要素 | 技術 |
|------|------|
| UI | SwiftUI + AppKit |
| ショートカット | CGEvent Tap（修飾キーは変更可能。既定は右 ⌘ / keyCode 54） |
| 録音 | AVFoundation（16kHz, 16-bit, モノラル WAV） |
| 音声認識 | Groq Whisper API（whisper-large-v3-turbo） |
| 文章補正 | 複数プロバイダの LLM（OpenAI 互換 Chat Completions）＋ Apple FoundationModels |
| 文字入力 | CGEvent によるキーボードイベントのシミュレート |
| 保存先 | UserDefaults + キーチェーン（API キー）＋ `apiaccounts.json`（複数アカウント, 0600） |
| 多言語化 | アプリ内の文字列テーブルと実行時切り替え（`TypeTop/Localization`） |
| プロジェクト管理 | XcodeGen（project.yml） |
