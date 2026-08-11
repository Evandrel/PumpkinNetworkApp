# PumpNet

**English** | [繁體中文](#繁體中文說明)

PumpNet is a private SwiftUI utility app that brings together Minecraft, Apple, network, and AI tools, with an additional reader for articles from `pcl2.top`. Tools are the main experience and the default tab when the app opens.

## Features

### Articles

- Reads public posts from the `pcl2.top` WordPress REST API.
- Downloads articles only after the user requests them for the first time.
- Uses local caching to make later launches faster.
- Supports manual refresh and animated article updates.

### Tools

- **Minecraft Skin Stealer** — Finds a Java Edition player's skin, displays the texture, provides a draggable 3D SceneKit preview, and supports sharing the skin file.
- **SHSH2 Checker** — Looks up saved SHSH blobs by ECID and keeps local search history.
- **IP Lookup** — Shows either the public IP address alone or extended region and ISP information after a privacy warning.
- **AI Chat** — Connects to user-provided OpenAI-compatible services, automatically loads their models, and supports three configurations by default with an optional on-device unlock for more.

> **AI Chat unlock code:** `www.pcl2.top`. The first three configurations can be added normally. To add a fourth configuration, choose **Unlock More Configurations** and enter this code to remove the configuration limit on this device.

AI Chat also provides:

- Per-provider name, API key, Base URL, and model selection.
- API keys stored securely in Apple Keychain.
- A conversation list with independent messages, presets, providers, and models.
- Provider and model switching inside each conversation without clearing its context.
- Clear-chat and share-transcript actions.
- Support for common OpenAI-compatible model-list and chat-response formats.

Example AI Base URLs:

| Provider | Base URL |
| --- | --- |
| OpenAI | `https://api.openai.com/v1` |
| xAI / Grok | `https://api.x.ai/v1` |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` |
| Custom provider | `https://example.com/v1` |

Custom providers must use HTTPS and expose compatible `GET /models` and `POST /chat/completions` endpoints. A consumer chatbot subscription does not necessarily include API access or API credits.

### Settings and About

- Clears cached articles and URL responses after confirmation.
- Includes an Advanced Privacy Protection interface reserved for future Tor support.
- Provides a separate About tab.

> **Important:** Tor routing is not currently active. Its controls are intentionally disabled until a Tor runtime and leak-prevention networking layer are added.

## Requirements

- macOS with Xcode 26 or later.
- iOS 17.0 or later.
- Internet access for online features.
- A provider API key and available API credit for AI Chat where required.

The project has been tested with Xcode 27 beta and the iOS 27 Simulator SDK.

## Run the Project

1. Open `PumpNet App.xcodeproj` in Xcode.
2. Select the **PumpNet App** scheme.
3. Choose an iPhone or iPad simulator.
4. Press **Run** (`⌘R`).

## Project Structure

```text
PumpNetApp/
├── Models/       Data models for articles, skins, SHSH, IP, and AI Chat
├── Services/     WordPress, Mojang, SHSH, IP, AI, cache, and Keychain access
├── ViewModels/   Observable state and feature logic
├── Views/        SwiftUI screens and the SceneKit skin preview
├── About.swift
├── ContentView.swift
└── PumpNetApp.swift
```

The features are split into separate files instead of being placed in one large `ContentView`.

## Data and Privacy

PumpNet contacts third-party services only when their corresponding features are used:

- `pcl2.top` for public WordPress articles.
- Mojang services for Minecraft profiles and skins.
- `jjr.one` for SHSH lookup.
- `api64.ipify.org` and `ipinfo.io` for IP lookup.
- The AI provider selected by the user for model discovery and conversations.

IP lookup providers can see the connection's public IP address. AI providers receive the preset and messages needed to answer a request. If the provider is changed inside an existing conversation, that conversation context is sent to the newly selected provider with the next request. Review the privacy policy of each provider before using it.

Article caches, search histories, AI configurations, presets, and chat histories are stored locally. AI API keys are stored separately in Apple Keychain and are never embedded in the source code.

## Status

PumpNet is under active development and is currently a private project. No open-source license is granted by this repository.

---

# 繁體中文說明

[English](#pumpnet) | **繁體中文**

PumpNet 是一款私人開發的 SwiftUI 實用工具 App，主要提供 Minecraft、Apple、網路和 AI 工具，同時附帶用於閱讀 `pcl2.top` 文章的閱讀器。工具是 App 的主要內容，也是啟動後預設顯示的頁面。

## 功能

### 文章

- 透過 `pcl2.top` 的 WordPress REST API 讀取公開文章。
- 從未取得過文章的使用者需要主動按一下後，才會發出第一次請求。
- 使用本機快取加快後續啟動和載入速度。
- 支援手動重新整理，並為更新後的文章列表加入動畫。

### 工具

- **Minecraft Skin Stealer** —— 查詢 Java 版玩家皮膚、查看原始貼圖、拖曳查看 SceneKit 3D 模型，並分享皮膚檔案。
- **SHSH2 Checker** —— 透過 ECID 查詢已儲存的 SHSH，並在本機保留查詢紀錄。
- **IP Lookup** —— 顯示隱私警告後，可以只查詢公開 IP，也可以查詢地區和 ISP 等詳細資訊。
- **AI Chat** —— 連接使用者自行提供的 OpenAI-compatible 服務並自動重新整理模型，預設最多儲存三個設定，也可以在本機輸入解鎖碼解除限制。

> **AI Chat 解鎖碼：** `www.pcl2.top`。前三個設定可以直接新增；要新增第四個設定時，按下「Unlock More Configurations」並輸入此解鎖碼，即可在此裝置解除設定數量限制。

AI Chat 也支援：

- 為每個服務設定名稱、API Key、Base URL 和模型。
- 使用 Apple Keychain 安全儲存 API Key。
- 提供獨立對話列表，每個對話分別儲存訊息、預設、服務供應商和模型。
- 可以在對話內切換服務設定和模型，並保留目前上下文。
- 清空聊天與分享聊天紀錄。
- 相容多種常見的模型列表和聊天回覆 JSON 格式。

AI Base URL 範例：

| 服務供應商 | Base URL |
| --- | --- |
| OpenAI | `https://api.openai.com/v1` |
| xAI / Grok | `https://api.x.ai/v1` |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` |
| 自訂服務 | `https://example.com/v1` |

自訂服務必須使用 HTTPS，並提供相容的 `GET /models` 和 `POST /chat/completions` 介面。一般聊天產品的會員訂閱不一定包含 API 權限或 API 額度。

### 設定與關於

- 在使用者確認後清除文章快取和網路回應快取。
- 提供為未來 Tor 支援預留的 Advanced Privacy Protection 介面。
- 提供獨立的 About 頁面。

> **重要：** Tor 代理目前尚未實際啟用。在 Tor 執行元件和防洩漏網路層完成之前，相關控制按鈕會保持停用。

## 環境需求

- 安裝了 Xcode 26 或更新版本的 macOS。
- iOS 17.0 或更新版本。
- 線上功能需要網路連線。
- AI Chat 可能需要服務供應商提供的 API Key 和可用 API 額度。

目前專案已使用 Xcode 27 beta 和 iOS 27 Simulator SDK 編譯測試。

## 執行專案

1. 使用 Xcode 開啟 `PumpNet App.xcodeproj`。
2. 選擇 **PumpNet App** Scheme。
3. 選擇 iPhone 或 iPad 模擬器。
4. 按下 **Run**（`⌘R`）。

## 專案結構

```text
PumpNetApp/
├── Models/       文章、皮膚、SHSH、IP 和 AI Chat 資料模型
├── Services/     WordPress、Mojang、SHSH、IP、AI、快取和 Keychain 服務
├── ViewModels/   可觀察狀態與功能邏輯
├── Views/        SwiftUI 頁面和 SceneKit 皮膚預覽
├── About.swift
├── ContentView.swift
└── PumpNetApp.swift
```

各項功能已拆分至獨立檔案，沒有全部堆放在一個大型 `ContentView` 內。

## 資料與隱私

PumpNet 只會在使用者使用對應功能時存取相關第三方服務：

- `pcl2.top`：取得公開 WordPress 文章。
- Mojang 服務：查詢 Minecraft 玩家資料和皮膚。
- `jjr.one`：查詢 SHSH。
- `api64.ipify.org` 和 `ipinfo.io`：查詢公開 IP。
- 使用者選擇的 AI 服務供應商：重新整理模型並完成對話。

IP 查詢服務供應商能看到連線所使用的公開 IP。AI 服務供應商會收到產生回答所需的預設和聊天訊息。如果在現有對話中切換服務供應商，下一次請求會把該對話上下文傳送給新的服務供應商。使用前請自行查看相應服務供應商的隱私政策。

文章快取、查詢紀錄、AI 設定、預設和聊天紀錄儲存在本機。AI API Key 會單獨儲存在 Apple Keychain 中，不會寫入原始碼。

## 專案狀態

PumpNet 仍在持續開發中，目前是私人專案。本儲存庫沒有授予開源授權。
