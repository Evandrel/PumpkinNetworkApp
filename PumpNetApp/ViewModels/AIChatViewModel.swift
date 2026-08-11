import Foundation

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published private(set) var configurations: [AIProviderConfiguration]
    @Published private(set) var selectedConfigurationID: UUID?
    @Published private(set) var conversations: [AIConversation]
    @Published private(set) var sendingConversationID: UUID?
    @Published private(set) var configurationLimitUnlocked: Bool
    @Published var errorMessage: String?

    private let service: AIChatService

    init(service: AIChatService = AIChatService()) {
        self.service = service
        configurationLimitUnlocked = AIChatStorage.loadConfigurationLimitUnlocked()
        let loadedConfigurations = AIChatStorage.loadConfigurations()
        configurations = loadedConfigurations

        let savedID = AIChatStorage.loadSelectedConfigurationID()
        selectedConfigurationID = loadedConfigurations.contains(where: { $0.id == savedID }) ? savedID : loadedConfigurations.first?.id

        var loadedConversations = AIChatStorage.loadConversations()
        if loadedConversations.isEmpty {
            let oldMessages = AIChatStorage.loadMessages()
            let oldPresets = AIChatStorage.loadPresets()
            loadedConversations = loadedConfigurations.compactMap { configuration in
                let messages = oldMessages[configuration.id.uuidString] ?? []
                let preset = oldPresets[configuration.id.uuidString] ?? ""
                guard !messages.isEmpty || !preset.isEmpty else { return nil }
                let firstMessage = messages.first(where: { $0.role == .user })?.content
                let title = Self.conversationTitle(from: firstMessage, fallback: "\(configuration.name) Chat")
                return AIConversation(
                    title: title,
                    messages: messages,
                    preset: preset,
                    configurationID: configuration.id,
                    selectedModel: configuration.selectedModel,
                    createdAt: messages.first?.createdAt ?? Date(),
                    updatedAt: messages.last?.createdAt ?? Date()
                )
            }
            if !loadedConversations.isEmpty { AIChatStorage.saveConversations(loadedConversations) }
        }
        conversations = loadedConversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    var selectedConfiguration: AIProviderConfiguration? {
        guard let id = selectedConfigurationID else { return nil }
        return configurations.first { $0.id == id }
    }

    var canAddConfiguration: Bool { configurations.count < 3 || configurationLimitUnlocked }

    func unlockConfigurationLimit(with code: String) -> Bool {
        guard code.trimmingCharacters(in: .whitespacesAndNewlines) == "www.pcl2.top" else { return false }
        configurationLimitUnlocked = true
        AIChatStorage.saveConfigurationLimitUnlocked(true)
        return true
    }

    func conversation(id: UUID) -> AIConversation? {
        conversations.first { $0.id == id }
    }

    func configuration(for conversationID: UUID) -> AIProviderConfiguration? {
        guard let configurationID = conversation(id: conversationID)?.configurationID else { return nil }
        return configurations.first { $0.id == configurationID }
    }

    func isSending(_ conversationID: UUID) -> Bool {
        sendingConversationID == conversationID
    }

    func shareText(for conversationID: UUID) -> String {
        guard let conversation = conversation(id: conversationID) else { return "AI Chat" }
        let body = conversation.messages.map { message in
            let speaker = message.role == .user ? "You" : "Assistant"
            return "\(speaker):\n\(message.content)"
        }.joined(separator: "\n\n")
        return body.isEmpty ? conversation.title : "\(conversation.title)\n\n\(body)"
    }

    func apiKey(for configuration: AIProviderConfiguration?) -> String {
        guard let configuration else { return "" }
        return AIKeychainStore.apiKey(for: configuration.id)
    }

    func fetchModels(baseURL: String, apiKey: String) async throws -> [String] {
        try await service.fetchModels(baseURL: baseURL, apiKey: apiKey)
    }

    func saveConfiguration(_ configuration: AIProviderConfiguration, apiKey: String) throws {
        let isExisting = configurations.contains { $0.id == configuration.id }
        guard isExisting || canAddConfiguration else { throw AIChatError.maximumConfigurations }
        try AIKeychainStore.save(apiKey: apiKey, for: configuration.id)

        if let index = configurations.firstIndex(where: { $0.id == configuration.id }) {
            configurations[index] = configuration
        } else {
            configurations.append(configuration)
        }
        for index in conversations.indices where conversations[index].configurationID == configuration.id {
            if !configuration.availableModels.contains(conversations[index].selectedModel) {
                conversations[index].selectedModel = configuration.selectedModel
            }
        }
        AIChatStorage.saveConfigurations(configurations)
        persistConversations()
        selectConfiguration(configuration.id)
    }

    func selectConfiguration(_ id: UUID) {
        guard configurations.contains(where: { $0.id == id }) else { return }
        selectedConfigurationID = id
        errorMessage = nil
        AIChatStorage.saveSelectedConfigurationID(id)
    }

    func deleteConfiguration(_ configuration: AIProviderConfiguration) {
        configurations.removeAll { $0.id == configuration.id }
        AIKeychainStore.deleteAPIKey(for: configuration.id)

        let fallback = configurations.first
        for index in conversations.indices where conversations[index].configurationID == configuration.id {
            conversations[index].configurationID = fallback?.id
            conversations[index].selectedModel = fallback?.selectedModel ?? ""
            conversations[index].updatedAt = Date()
        }

        selectedConfigurationID = fallback?.id
        AIChatStorage.saveConfigurations(configurations)
        AIChatStorage.saveSelectedConfigurationID(selectedConfigurationID)
        persistConversations()
    }

    @discardableResult
    func createConversation() -> UUID? {
        guard let configuration = selectedConfiguration ?? configurations.first else {
            errorMessage = AIChatError.noConfiguration.localizedDescription
            return nil
        }
        let conversation = AIConversation(
            configurationID: configuration.id,
            selectedModel: configuration.selectedModel
        )
        conversations.insert(conversation, at: 0)
        persistConversations()
        return conversation.id
    }

    func deleteConversation(_ conversationID: UUID) {
        conversations.removeAll { $0.id == conversationID }
        persistConversations()
    }

    func clearConversation(_ conversationID: UUID) {
        guard let index = conversationIndex(conversationID) else { return }
        conversations[index].messages = []
        conversations[index].title = "New Chat"
        conversations[index].updatedAt = Date()
        persistConversations()
    }

    func savePreset(_ value: String, for conversationID: UUID) {
        guard let index = conversationIndex(conversationID) else { return }
        conversations[index].preset = value
        conversations[index].updatedAt = Date()
        persistConversations()
    }

    func selectConfiguration(_ configurationID: UUID, for conversationID: UUID) {
        guard let index = conversationIndex(conversationID),
              let configuration = configurations.first(where: { $0.id == configurationID }) else { return }
        conversations[index].configurationID = configurationID
        conversations[index].selectedModel = configuration.selectedModel
        conversations[index].updatedAt = Date()
        selectedConfigurationID = configurationID
        AIChatStorage.saveSelectedConfigurationID(configurationID)
        persistConversations()
    }

    func selectModel(_ model: String, for conversationID: UUID) {
        guard let index = conversationIndex(conversationID),
              let configuration = configuration(for: conversationID),
              configuration.availableModels.contains(model) else { return }
        conversations[index].selectedModel = model
        conversations[index].updatedAt = Date()
        persistConversations()
    }

    func refreshModels(for conversationID: UUID) async {
        guard let configuration = configuration(for: conversationID),
              let configurationIndex = configurations.firstIndex(where: { $0.id == configuration.id }) else { return }
        do {
            let models = try await fetchModels(baseURL: configuration.baseURL, apiKey: apiKey(for: configuration))
            guard !models.isEmpty else { throw AIChatError.noModel }
            configurations[configurationIndex].availableModels = models
            if !models.contains(configurations[configurationIndex].selectedModel) {
                configurations[configurationIndex].selectedModel = models[0]
            }
            if let conversationIndex = conversationIndex(conversationID), !models.contains(conversations[conversationIndex].selectedModel) {
                conversations[conversationIndex].selectedModel = configurations[configurationIndex].selectedModel
            }
            AIChatStorage.saveConfigurations(configurations)
            persistConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func send(_ text: String, in conversationID: UUID) async {
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, sendingConversationID == nil else { return }
        guard let index = conversationIndex(conversationID) else { return }
        guard var configuration = configuration(for: conversationID) else {
            errorMessage = AIChatError.noConfiguration.localizedDescription
            return
        }
        let selectedModel = conversations[index].selectedModel
        guard !selectedModel.isEmpty else {
            errorMessage = AIChatError.noModel.localizedDescription
            return
        }

        let wasEmpty = conversations[index].messages.isEmpty
        conversations[index].messages.append(AIChatMessage(role: .user, content: content))
        if wasEmpty {
            conversations[index].title = Self.conversationTitle(from: content, fallback: "New Chat")
        }
        conversations[index].updatedAt = Date()
        let requestMessages = conversations[index].messages
        let requestPreset = conversations[index].preset
        configuration.selectedModel = selectedModel
        persistConversations()

        errorMessage = nil
        sendingConversationID = conversationID
        defer { sendingConversationID = nil }

        do {
            let response = try await service.complete(
                configuration: configuration,
                apiKey: apiKey(for: configuration),
                messages: requestMessages,
                preset: requestPreset
            )
            guard let updatedIndex = conversationIndex(conversationID) else { return }
            conversations[updatedIndex].messages.append(AIChatMessage(role: .assistant, content: response))
            conversations[updatedIndex].updatedAt = Date()
            persistConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func conversationIndex(_ id: UUID) -> Int? {
        conversations.firstIndex { $0.id == id }
    }

    private func persistConversations() {
        conversations.sort { $0.updatedAt > $1.updatedAt }
        AIChatStorage.saveConversations(conversations)
    }

    private static func conversationTitle(from text: String?, fallback: String) -> String {
        guard let text else { return fallback }
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        return String(trimmed.prefix(40))
    }
}
