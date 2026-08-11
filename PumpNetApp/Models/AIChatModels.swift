import Foundation

struct AIProviderConfiguration: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var baseURL: String
    var availableModels: [String]
    var selectedModel: String

    init(id: UUID = UUID(), name: String, baseURL: String, availableModels: [String] = [], selectedModel: String = "") {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.availableModels = availableModels
        self.selectedModel = selectedModel
    }
}

enum AIChatRole: String, Codable {
    case user
    case assistant
}

struct AIChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let role: AIChatRole
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), role: AIChatRole, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

struct AIConversation: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var messages: [AIChatMessage]
    var preset: String
    var configurationID: UUID?
    var selectedModel: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [AIChatMessage] = [],
        preset: String = "",
        configurationID: UUID?,
        selectedModel: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.preset = preset
        self.configurationID = configurationID
        self.selectedModel = selectedModel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum AIChatError: LocalizedError {
    case invalidBaseURL
    case insecureBaseURL
    case noConfiguration
    case noModel
    case maximumConfigurations
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL: return "Enter a valid Base URL."
        case .insecureBaseURL: return "The Base URL must use HTTPS so your API key is protected."
        case .noConfiguration: return "Add an AI configuration first."
        case .noModel: return "Refresh and select a model first."
        case .maximumConfigurations: return "You can add up to three AI configurations."
        case .invalidResponse: return "The AI provider returned an invalid response."
        case .server(let message): return message
        }
    }
}
