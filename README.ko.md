# TypeTop

[繁體中文](README.md) · [简体中文](README.zh-Hans.md) · [English](README.en.md) · [日本語](README.ja.md) · **한국어**

**macOS 음성 입력 도구 —— 오른쪽 ⌘ 를 누른 채 말하고 손을 떼면, 커서가 있는 곳에 문자가 입력됩니다.**

[![Download](https://img.shields.io/github/v/release/Lance70176/TypeTop?label=다운로드&style=for-the-badge)](https://github.com/Lance70176/TypeTop/releases/latest)
![macOS](https://img.shields.io/badge/macOS-14.0%2B-black?style=for-the-badge&logo=apple)
![Apple Silicon](https://img.shields.io/badge/Apple-Silicon-blue?style=for-the-badge)

![TypeTop](typetop.png)

---

## 설치

**➡️ [TypeTop.dmg 내려받기(최신 버전)](https://github.com/Lance70176/TypeTop/releases/latest/download/TypeTop.dmg)**　·　[모든 릴리스와 변경 내역](https://github.com/Lance70176/TypeTop/releases)

1. DMG를 열고 **TypeTop**을 응용 프로그램 폴더로 드래그합니다
2. 첫 실행이 차단되면(Apple 공증을 받지 않은 앱입니다): **시스템 설정 → 개인정보 보호 및 보안**에서 맨 아래의 「**그래도 열기**」를 누릅니다
3. 요청에 따라 **마이크**와 **손쉬운 사용** 권한을 허용합니다(손쉬운 사용 권한이 없으면 문자를 입력할 수 없습니다)
4. 메뉴 막대의 마이크 아이콘 → **환경설정 → API** 에서 Groq API 키를 입력합니다
5. 아무 입력란에나 커서를 두고 **오른쪽 ⌘ 를 누른 채** 말한 뒤 손을 뗍니다

> 요구 사항: **Apple Silicon**(M1 이상), **macOS 14.0 Sonoma** 이상.

---

## 기능

### 입력

- **누른 채 말하기(Push-to-talk)** — 키를 누르는 동안 녹음하고 떼면 인식해 입력합니다. 창을 전환할 필요가 없습니다
- **실행 키 선택** — 오른쪽 ⌘(기본), 왼쪽 ⌘, 좌우 ⌥, 좌우 ⌃, fn 등 7가지
- **어디서나 사용** — 시스템 수준의 키보드 이벤트로 입력하므로 모든 앱의 모든 입력란에서 동작합니다
- **도중에 취소** — 녹음 중 다른 보조키(⌥ / ⌃ / fn)를 누르면 아무것도 입력되지 않고 취소됩니다
- **녹음 오버레이와 효과음** — 화면 모서리에 녹음 상태와 음량을 표시하고 메뉴 막대 아이콘도 바뀝니다. 효과음은 끌 수 있습니다
- **녹음 중 시스템 소리 음소거** — 음악이나 영상 소리가 마이크에 섞이지 않습니다
- **메뉴 막대 상주** — Dock을 차지하지 않으며 로그인 시 자동 실행도 설정할 수 있습니다
- **5가지 표시 언어** — 번체 중국어, 간체 중국어, 영어, 일본어, 한국어. 재시작 없이 즉시 전환됩니다

### 인식과 교정

- **음성 인식(STT)** — Groq Whisper `whisper-large-v3-turbo`. 빠르고 무료 한도가 일상 사용에 충분합니다
- **LLM 교정** — 인식 후 오타를 고치고 문장 부호를 채웁니다. **완전 오프라인**인 Apple 온디바이스 모델을 포함해 8개 공급자를 지원합니다
- **4단계 교정 강도** — 「문장 부호만」부터 「문장 구조 재구성」까지. 시스템 프롬프트를 직접 편집할 수도 있습니다
- **온도 조절** — 기본값 0.3, 낮을수록 안정적입니다
- **다국어 혼합 모드** — 주 언어와 영어가 섞인 문장도 정확히 인식합니다
- **문장 부호 스타일** — 전각 `，。！？` / 반각 `,.!?` / 모두 제거 / 변환 안 함
- **한중일 문자와 영문 자동 띄어쓰기** — `使用React框架` → `使用 React 框架`
- **Whisper 프롬프트** — 자주 쓰는 고유명사를 미리 알려 주면 정확도가 올라갑니다

### 계정과 한도

- **여러 API 계정** — 같은 공급자에 여러 키를 저장하고 각각 이름을 붙일 수 있습니다(「업무용」, 「예비」 등)
- **한도 도달 시 자동 전환** — 어떤 키가 HTTP 429(한도 초과)를 반환하면 다음 계정으로 자동 전환해 계속 사용합니다
- **키 보기 / 편집** — 기존 계정의 이름과 키를 그 자리에서 바꿀 수 있어, 삭제 후 다시 추가할 필요가 없고 사용량 집계도 이어집니다
- **사용량 통계** — 오늘의 STT/LLM 요청 수와 토큰 수, 그리고 Groq가 알려 주는 실시간 잔여 한도

### 단어장

- **치환 규칙** — 자주 잘못 인식되는 단어를 고칩니다(`太好了` → `TypeTop`, `派森` → `Python`). 규칙마다 켜고 끌 수 있습니다
- **주음 사전 가져오기** — macOS 주음 입력기가 내보낸 개인 사전(`.txt`)을 그대로 읽어 들입니다. 자주 쓰는 단어는 LLM에 전달돼 동음이의 오류를 고칩니다
- **JSON 내보내기 / 가져오기** — 백업이나 공유에 편리합니다

---

## 스크린샷

> 아래 스크린샷은 번체 중국어 화면이며, 앱 자체는 5개 언어를 지원합니다.

### 일반

단축키, 표시 언어, 권한 상태, 동작 스위치.

<img src="docs/screenshots/settings-general.png" width="620" alt="일반 설정">

### API

공급자마다 여러 계정을 등록할 수 있고 한도 도달 시 자동 전환됩니다. 아래쪽은 오늘 사용량입니다.

<img src="docs/screenshots/settings-api.png" width="620" alt="API 설정">

### 언어

인식 언어, 텍스트 처리, Whisper 프롬프트, LLM 교정 강도와 온도.

<img src="docs/screenshots/settings-language.png" width="620" alt="언어 설정">

### 단어장

자주 틀리는 단어를 고칩니다. 주음 사전과 JSON 입출력을 지원합니다.

<img src="docs/screenshots/settings-vocabulary.png" width="620" alt="단어장">

---

## API 키 설정

TypeTop을 쓰려면 최소한 하나의 **Groq API 키**(음성 인식용)가 필요합니다.

### 음성 인식(STT) — Groq

1. [console.groq.com](https://console.groq.com/keys) 에서 가입 / 로그인
2. 왼쪽 메뉴에서 「API Keys」 → 「Create API Key」
3. `gsk_` 로 시작하는 키를 복사해 **API → 음성 인식** 칸에 붙여넣고 「계정 추가」를 누릅니다

> Groq 무료 한도면 일상적인 음성 입력에 충분합니다. 부족하면 다른 계정의 키를 추가해 두세요. 자동으로 전환됩니다.

### 문장 교정(LLM)

**API → 문장 교정** 에서 공급자를 고르고 해당 키를 입력합니다:

| 공급자 | 기본 모델 | API 키 | 발급처 |
|--------|---------|:---:|-------------|
| OpenAI | `gpt-4o-mini` | ✅ | [platform.openai.com](https://platform.openai.com/api-keys) |
| Groq | `llama-3.3-70b-versatile` | ✅ | [console.groq.com](https://console.groq.com/keys) |
| DeepSeek | `deepseek-chat` | ✅ | [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| Moonshot (Kimi) | `kimi-k2.5` | ✅ | [platform.moonshot.ai](https://platform.moonshot.ai/console/api-keys) |
| Google Gemini | `gemini-3.1-flash-lite` | ✅ | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **Apple 온디바이스** | OS 내장 | ❌ | 설정 불필요. macOS 26 이상에서 Apple Intelligence 활성화 필요 |
| Ollama(로컬) | `llama3` | ❌ | [ollama.com](https://ollama.com) |
| 사용자 지정 | 직접 입력 | 환경에 따라 | OpenAI 호환 Chat Completions API |

> STT와 LLM은 서로 다른 공급자를 쓸 수 있습니다. 예를 들어 받아쓰기는 Groq, 교정은 OpenAI.
> 내용이 Mac 밖으로 나가지 않게 하려면 LLM을 **Apple 온디바이스 모델**이나 **Ollama**로 설정하세요.

---

## 환경설정

### 일반

| 항목 | 설명 |
|------|------|
| 말하기 단축키 | 실행 키 선택(보조키 7가지) |
| 표시 언어 | 앱 표시 언어를 전환. 인식 언어와 같은 5개 언어이며 즉시 적용됩니다 |
| 손쉬운 사용 | 허용하지 않으면 문자를 입력할 수 없습니다. 「설정 열기」에서 허용하세요 |
| 마이크 | 허용하지 않으면 녹음할 수 없습니다 |
| 효과음 재생 | 녹음 시작·종료 시 효과음 |
| 녹음 중 시스템 소리 음소거 | 녹음 중 시스템 음량을 낮춰 배경음이 섞이지 않게 합니다 |
| 로그인 시 자동 실행 | 로그인할 때 TypeTop을 자동으로 실행합니다 |

### 언어

| 항목 | 설명 |
|------|------|
| 인식 언어 | 주 언어(기본값은 번체 중국어). 전환하면 직접 수정하지 않은 Whisper/LLM 프롬프트도 해당 언어 버전으로 바뀝니다 |
| 다국어 혼합 모드 | 주 언어와 영어를 함께 인식합니다 |
| 한중일 문자와 영문 사이 자동 띄어쓰기 | `使用React框架` → `使用 React 框架` |
| 문장 부호 스타일 | 전각 / 반각 / 없음 / 그대로 |
| Whisper 프롬프트 | 자주 쓰는 고유명사를 넣어 정확도를 높입니다 |
| LLM 교정 사용 | 끄면 Whisper 원본 결과를 그대로 입력합니다 |
| 교정 강도 | 없음 / 약하게 / 보통 / 강하게. 고르면 기본 프롬프트가 적용됩니다 |
| 온도 | 낮을수록 안정적이며 오타 교정은 0~0.3을 권장합니다 |
| LLM 시스템 프롬프트 | 문체나 전문 용어에 맞게 자유롭게 편집할 수 있습니다 |

### 단어장

자주 잘못 인식되는 단어를 고칩니다:

| 잘못 인식된 텍스트(원본) | 올바른 텍스트(대상) | 메모 |
|---|---|---|
| 太好了 | TypeTop | 앱 이름 |
| 瑞乃特 | React | 프런트엔드 프레임워크 |
| 派森 | Python | 프로그래밍 언어 |

- **+** 를 눌러 규칙을 추가하며, 규칙마다 켜고 끌 수 있습니다
- **JSON 내보내기 / 가져오기**로 백업하거나 공유할 수 있습니다
- **macOS 주음 입력기 개인 사전**(`.txt`)을 가져올 수 있습니다

---

## 자주 묻는 질문

**⌘ 를 눌러도 반응이 없어요.**
먼저 메뉴 막대에 마이크 아이콘이 있는지 확인하고, 「일반」 탭에서 **손쉬운 사용** 권한이 허용됐는지 보세요. 재설치하거나 업데이트한 뒤에는 권한을 다시 허용해야 할 수 있습니다.

**인식이 정확하지 않아요.**
세 곳을 조정할 수 있습니다. 「언어 → Whisper 프롬프트」에 자주 쓰는 고유명사를 추가하고, 「단어장」에 치환 규칙을 만들고, **교정 강도**를 높여 LLM이 더 다듬게 하세요.

**한도를 다 썼어요.**
API 탭에서 같은 공급자의 계정을 하나 더 추가하면 HTTP 429가 뜰 때 자동으로 전환됩니다. LLM을 Apple 온디바이스 모델이나 Ollama로 바꾸면 클라우드 한도를 전혀 쓰지 않습니다.

**표시 언어를 바꿀 수 있나요?**
네. 「일반 → 표시 언어」에서 번체 중국어, 간체 중국어, 영어, 일본어, 한국어를 고를 수 있고 재시작 없이 바로 적용됩니다. 무엇을 말하고 어떤 언어로 쓸지 정하는 「언어 → 인식 언어」와는 별개의 설정입니다.

**제 음성은 어디로 전송되나요?**
음성은 설정한 STT 공급자(Groq)에만 전송되고, 문장 교정은 선택한 LLM 공급자로 전송됩니다. Apple 온디바이스 모델이나 Ollama를 고르면 교정 단계는 전부 이 Mac 안에서 이뤄집니다. API 키는 로컬 키체인과 응용 프로그램 지원 디렉터리(권한 0600)에 저장됩니다.

---

## 개발

Xcode 프로젝트는 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 으로 관리합니다.

```bash
# XcodeGen 설치
brew install xcodegen

# Xcode 프로젝트 생성
xcodegen generate

# 열기
open TypeTop.xcodeproj
```

### DMG 빌드

```bash
cd build
./build_dmg.sh
```

DMG는 `build/TypeTop.dmg` 에 생성됩니다.

---

## 기술 구성

| 구성 요소 | 기술 |
|------|------|
| UI | SwiftUI + AppKit |
| 단축키 | CGEvent Tap(보조키 변경 가능, 기본은 오른쪽 ⌘ / keyCode 54) |
| 녹음 | AVFoundation(16kHz, 16-bit, 모노 WAV) |
| 음성 인식 | Groq Whisper API(whisper-large-v3-turbo) |
| 문장 교정 | 다중 공급자 LLM(OpenAI 호환 Chat Completions) + Apple FoundationModels |
| 텍스트 입력 | CGEvent 키보드 이벤트 시뮬레이션 |
| 저장소 | UserDefaults + 키체인(API 키) + `apiaccounts.json`(다중 계정, 0600) |
| 다국어 | 앱 내 문자열 테이블과 런타임 전환(`TypeTop/Localization`) |
| 프로젝트 관리 | XcodeGen(project.yml) |
