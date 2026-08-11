# PumpNet

**English** | [中文](#中文说明)

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

# 中文说明

[English](#pumpnet) | **中文**

PumpNet 是一款私人开发的 SwiftUI 实用工具应用，主要提供 Minecraft、Apple、网络和 AI 工具，同时附带用于阅读 `pcl2.top` 文章的阅读器。Tools 是应用的主要内容，也是启动后默认显示的页面。

## 功能

### 文章

- 通过 `pcl2.top` 的 WordPress REST API 读取公开文章。
- 从未获取过文章的用户需要主动点击后才会发起第一次请求。
- 使用本地缓存加快之后的启动和加载速度。
- 支持手动刷新，并为更新后的文章列表添加动画。

### 工具

- **Minecraft Skin Stealer** —— 查询 Java 版玩家皮肤、查看原始贴图、拖动查看 SceneKit 3D 模型，并分享皮肤文件。
- **SHSH2 Checker** —— 通过 ECID 查询已保存的 SHSH，并在本地保留查询历史。
- **IP Lookup** —— 在显示隐私警告后，可以只查询公网 IP，也可以查询地区和 ISP 等详细信息。
- **AI Chat** —— 连接用户自行提供的 OpenAI-compatible 服务并自动刷新模型，默认最多保存三个配置，也可以在本机输入解锁码解除限制。

AI Chat 还支持：

- 为每个服务设置名称、API Key、Base URL 和模型。
- 使用 Apple Keychain 安全保存 API Key。
- 提供独立会话列表，每个会话分别保存消息、预设、服务商和模型。
- 可以在会话内部切换服务配置和模型，并保留当前上下文。
- 清空聊天以及分享聊天记录。
- 兼容多种常见的模型列表和聊天回复 JSON 格式。

AI Base URL 示例：

| 服务商 | Base URL |
| --- | --- |
| OpenAI | `https://api.openai.com/v1` |
| xAI / Grok | `https://api.x.ai/v1` |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` |
| 自定义服务 | `https://example.com/v1` |

自定义服务必须使用 HTTPS，并提供兼容的 `GET /models` 和 `POST /chat/completions` 接口。普通聊天产品的会员订阅不一定包含 API 权限或 API 额度。

### 设置与关于

- 在用户确认后清除文章缓存和网络响应缓存。
- 提供为未来 Tor 支持预留的 Advanced Privacy Protection 界面。
- 提供独立的 About 页面。

> **重要：** Tor 代理目前没有实际启用。在 Tor 运行组件和防泄漏网络层完成之前，相关控制按钮会保持禁用。

## 环境要求

- 安装了 Xcode 26 或更新版本的 macOS。
- iOS 17.0 或更新版本。
- 在线功能需要网络连接。
- AI Chat 可能需要服务商提供的 API Key 和可用 API 额度。

当前项目已使用 Xcode 27 beta 和 iOS 27 Simulator SDK 编译测试。

## 运行项目

1. 使用 Xcode 打开 `PumpNet App.xcodeproj`。
2. 选择 **PumpNet App** Scheme。
3. 选择 iPhone 或 iPad 模拟器。
4. 按下 **Run**（`⌘R`）。

## 项目结构

```text
PumpNetApp/
├── Models/       文章、皮肤、SHSH、IP 和 AI Chat 数据模型
├── Services/     WordPress、Mojang、SHSH、IP、AI、缓存和 Keychain 服务
├── ViewModels/   可观察状态与功能逻辑
├── Views/        SwiftUI 页面和 SceneKit 皮肤预览
├── About.swift
├── ContentView.swift
└── PumpNetApp.swift
```

各项功能已经拆分到独立文件中，没有全部堆放在一个大型 `ContentView` 内。

## 数据与隐私

PumpNet 只会在用户使用对应功能时访问相关第三方服务：

- `pcl2.top`：获取公开 WordPress 文章。
- Mojang 服务：查询 Minecraft 玩家资料和皮肤。
- `jjr.one`：查询 SHSH。
- `api64.ipify.org` 和 `ipinfo.io`：查询公网 IP。
- 用户选择的 AI 服务商：刷新模型并完成对话。

IP 查询服务商能够看到连接所使用的公网 IP。AI 服务商会收到生成回答所需的预设和聊天消息。如果在现有会话中切换服务商，下一次请求会把该会话上下文发送给新服务商。使用前请自行查看相应服务商的隐私政策。

文章缓存、查询历史、AI 配置、预设和聊天记录保存在本机。AI API Key 会单独保存在 Apple Keychain 中，不会写入源代码。

## 项目状态

PumpNet 仍在持续开发中，目前是私人项目。本仓库没有授予开源许可证。
