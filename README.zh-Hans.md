# TypeTop

[繁體中文](README.md) · **简体中文** · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

**macOS 语音输入工具 —— 按住右侧 ⌘ 说话，松开就把文字打进光标所在的任何地方。**

[![Download](https://img.shields.io/github/v/release/Lance70176/TypeTop?label=下载最新版&style=for-the-badge)](https://github.com/Lance70176/TypeTop/releases/latest)
![macOS](https://img.shields.io/badge/macOS-14.0%2B-black?style=for-the-badge&logo=apple)
![Apple Silicon](https://img.shields.io/badge/Apple-Silicon-blue?style=for-the-badge)

![TypeTop](typetop.png)

---

## 下载安装

**➡️ [直接下载 TypeTop.dmg（最新版）](https://github.com/Lance70176/TypeTop/releases/latest/download/TypeTop.dmg)**　·　[所有版本与更新说明](https://github.com/Lance70176/TypeTop/releases)

1. 打开 DMG，把 **TypeTop** 拖进「应用程序」文件夹
2. 第一次打开若被系统拦截（App 未经 Apple 公证）：**系统设置 → 隐私与安全性**，滚到底部点「**仍要打开**」
3. 按提示授予**麦克风**与**辅助功能**权限（辅助功能是用来模拟键盘输入的，没有它无法打字）
4. 点菜单栏的麦克风图标 → **偏好设置 → API 设置**，填入 Groq API Key
5. 把光标放进任何输入框，**按住右侧 ⌘** 说话，松开即输入

> 系统要求：**Apple Silicon**（M1 以上）、**macOS 14.0 Sonoma** 以上。

---

## 功能

### 输入体验

- **按住说话（Push-to-talk）**：按住启动键录音，松开就识别并输入，全程不用切窗口
- **启动键可自定义**：右侧 ⌘（默认）、左侧 ⌘、左右 ⌥、左右 ⌃、fn 共七种
- **随处可用**：以系统级的键盘事件输入文字，任何 App 的任何输入框都能用
- **随时取消**：录音中按下其他修饰键（⌥ / ⌃ / fn 等）即取消这次录音，不会输入任何文字
- **录音浮层与音效**：屏幕角落显示录音状态与音量，菜单栏图标同步变化，提示音可开关
- **录音时静音系统音频**：说话时自动压下背景音乐／视频声音，避免被一起录进去
- **菜单栏常驻**：不占 Dock，可设置开机自动启动
- **五种界面语言**：繁體中文、简体中文、English、日本語、한국어，设置里实时切换不用重启

### 识别与修正

- **语音识别（STT）**：Groq Whisper `whisper-large-v3-turbo`，速度快、免费额度足够日常使用
- **LLM 语义修正**：识别完再让 LLM 修错字、补标点，支持 8 种供应商（含**完全离线**的 Apple 本机模型）
- **修正程度可调**：无修正／轻微／中等／重度，从「只加标点」到「重组句子结构」，也可直接改系统提示词
- **采样温度可调**：默认 0.3，越低输出越稳定
- **多语言混合模式**：同一句话中英夹杂也能正确识别
- **标点符号风格**：全角 `，。！？`／半角 `,.!?`／完全移除／保持原样
- **中英文自动加空格**：`使用React框架` → `使用 React 框架`
- **Whisper 提示词**：先告诉 Whisper 你常讲的专有名词，提升识别准确度

### 账号与额度

- **多组 API 账号**：同一供应商可存多组 Key，并可自定义名称（例如「工作账号」「备用账号」）
- **额度自动切换**：某组 Key 触发 HTTP 429（达额度上限）时，自动换到下一组继续用
- **查看／编辑 Key**：既有账号可展开修改名称与 Key，不必删掉重加，用量统计也不会归零
- **用量统计**：显示今日 STT／LLM 请求次数与 tokens，Groq 另外显示官方返回的实时剩余额度

### 词汇库

- **替换规则**：修正 Whisper 常错的词（`太好了` → `TypeTop`、`派森` → `Python`），每条可独立启用／停用
- **注音个人词库导入**：直接读取 macOS 注音输入法导出的个人词库（`.txt`），常用词会自动提示 LLM 修正同音错字
- **JSON 导出／导入**：方便备份或分享词库

---

## 界面

> 以下截图是繁体中文界面，App 本身支持五种语言。

### 通用

快捷键、界面语言、权限状态、行为开关一目了然。

<img src="docs/screenshots/settings-general.png" width="620" alt="通用设置">

### API 设置

每个供应商都可以存多组账号，达额度时自动切换；下方是今日用量统计。

<img src="docs/screenshots/settings-api.png" width="620" alt="API 设置">

### 语言

识别语言、文字处理、Whisper 提示词、LLM 修正程度与温度都在这里。

<img src="docs/screenshots/settings-language.png" width="620" alt="语言设置">

### 词汇库

修正常错词汇，支持注音词库与 JSON 导入导出。

<img src="docs/screenshots/settings-vocabulary.png" width="620" alt="词汇库">

---

## API Key 设置

TypeTop 需要至少一组 **Groq API Key**（语音识别用）才能运作。

### 语音识别（STT）— Groq

1. 前往 [console.groq.com](https://console.groq.com/keys) 注册／登录
2. 左侧菜单点「API Keys」→「Create API Key」
3. 复制 `gsk_` 开头的 Key，粘贴到 **API 设置 → 语音识别** 的栏位后按「添加账号」

> Groq 提供免费额度，日常语音输入绰绰有余。额度不够可以再申请一组账号加进去，用完会自动切换。

### 语义修正（LLM）

在「API 设置 → 语义修正」选择供应商并填入对应 Key：

| 供应商 | 默认模型 | 需要 API Key | 获取位置 |
|--------|---------|:---:|-------------|
| OpenAI | `gpt-4o-mini` | ✅ | [platform.openai.com](https://platform.openai.com/api-keys) |
| Groq | `llama-3.3-70b-versatile` | ✅ | [console.groq.com](https://console.groq.com/keys) |
| DeepSeek | `deepseek-chat` | ✅ | [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| Moonshot (Kimi) | `kimi-k2.5` | ✅ | [platform.moonshot.ai](https://platform.moonshot.ai/console/api-keys) |
| Google Gemini | `gemini-3.1-flash-lite` | ✅ | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **Apple 本机模型** | 系统内置（on-device） | ❌ | 免设置，需 macOS 26+ 并已开启 Apple Intelligence |
| Ollama（本地） | `llama3` | ❌ | [ollama.com](https://ollama.com) |
| 自定义 | 自填 | 视 endpoint | 任何 OpenAI 兼容的 Chat Completion API |

> STT 与 LLM 可以用不同供应商，例如 Groq 负责语音转文字、OpenAI 负责语义修正。
> 想让内容完全不离开电脑，就把 LLM 设成 **Apple 本机模型** 或 **Ollama**。

---

## 偏好设置说明

### 通用

| 项目 | 说明 |
|------|------|
| 按住说话快捷键 | 选择启动键，共七种修饰键可选 |
| 界面语言 | 切换 app 界面语言，与识别语言相同的五种，实时生效 |
| 辅助功能权限 | 未授权时无法输入文字，点「前往设置」打开系统设置 |
| 麦克风权限 | 未授权时无法录音 |
| 播放音效提示 | 开始／结束录音时的提示音 |
| 录音时静音系统音频 | 录音期间自动降低系统音量，避免背景声被录进去 |
| 开机自动启动 | 登录时自动启动 TypeTop |

### 语言

| 项目 | 说明 |
|------|------|
| 识别语言 | 主要语言（默认繁体中文），Whisper 会优先识别该语言。切换后，未手动改过的 Whisper／LLM 提示词会自动换成该语言的版本 |
| 多语言混合模式 | 同时识别主要语言和英文内容 |
| 中英文之间自动加空格 | `使用React框架` → `使用 React 框架` |
| 标点符号风格 | 全角／半角／无标点／保持原样 |
| Whisper 提示词 | 填入常用专有名词，提升识别准确度 |
| 启用 LLM 智能修正 | 关闭后直接输出 Whisper 原始结果 |
| 修正程度 | 无修正／轻微／中等／重度，选择后自动套用对应提示词 |
| 采样温度 | 越低越稳定，错字修正建议 0～0.3 |
| LLM 系统提示词 | 可手动改写，自定义修正风格与领域用语 |

### 词汇库

用来修正 Whisper 常识别错的词：

| 识别错误（来源） | 正确文字（目标） | 说明 |
|---|---|---|
| 太好了 | TypeTop | App 名称 |
| 瑞乃特 | React | 前端框架 |
| 派森 | Python | 编程语言 |

- 点 **+** 添加规则，每条可独立启用／停用
- 支持 **JSON 导出／导入**，方便备份或分享
- 支持导入 **macOS 注音输入法个人词库**（`.txt`）

---

## 常见问题

**按住 ⌘ 没反应？**
先确认菜单栏有麦克风图标，再到「通用」页看**辅助功能权限**是否已授权。重新安装或换版本后，权限有时需要重新勾选一次。

**识别不准怎么办？**
三个地方可以调：在「语言 → Whisper 提示词」加入常用专有名词、在「词汇库」建立替换规则、把「修正程度」调高让 LLM 帮忙改写。

**额度用完了？**
在「API 设置」对同一个供应商添加第二组账号，触发 429 时会自动切到下一组。也可以把 LLM 换成 Apple 本机模型或 Ollama，完全不耗云端额度。

**界面可以换语言吗？**
可以。「通用 → 界面语言」提供繁體中文、简体中文、English、日本語、한국어，选了立刻生效不用重启。另外「语言 → 识别语言」是决定你说哪种语言、输出哪种语言，两者各自独立。

**我的语音会被送到哪里？**
音频只会送到你设置的 STT 供应商（Groq）；文字修正会送到你选的 LLM 供应商。选 Apple 本机模型或 Ollama 时，修正阶段完全在本机进行。API Key 存在本机的钥匙串与应用程序支持目录（权限 0600）。

---

## 开发

本项目使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 管理 Xcode 项目。

```bash
# 安装 XcodeGen
brew install xcodegen

# 生成 Xcode 项目
xcodegen generate

# 用 Xcode 打开
open TypeTop.xcodeproj
```

### 打包 DMG

```bash
cd build
./build_dmg.sh
```

DMG 会生成在 `build/TypeTop.dmg`。

---

## 技术架构

| 组件 | 技术 |
|------|------|
| UI 框架 | SwiftUI + AppKit |
| 快捷键 | CGEvent Tap（可自定义修饰键，默认右侧 ⌘／keyCode 54） |
| 录音 | AVFoundation（16kHz, 16-bit, mono WAV） |
| 语音识别 | Groq Whisper API（whisper-large-v3-turbo） |
| 语义修正 | 多供应商 LLM（OpenAI 兼容 Chat Completion API）＋ Apple FoundationModels |
| 文字输入 | CGEvent 键盘事件模拟 |
| 设置存储 | UserDefaults + 钥匙串（API Key）＋ `apiaccounts.json`（多账号，0600） |
| 多语言 | app 内字符串表与运行时切换（`TypeTop/Localization`） |
| 项目管理 | XcodeGen（project.yml） |
