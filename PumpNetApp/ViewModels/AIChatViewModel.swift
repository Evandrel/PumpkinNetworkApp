import Foundation

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published private(set) var configurations: [AIProviderConfiguration]
    @Published private(set) var selectedConfigurationID: UUID?
    @Published private(set) var messages: [AIChatMessage] = []
    @Published private(set) var preset = ""
    @Published var draft = ""
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private var storedMessages: [String: [AIChatMessage]]
    private var storedPresets: [String: String]
    private let service: AIChatService

    init(service: AIChatService = AIChatService()) {
        self.service = service
        configurations = AIChatStorage.loadConfigurations()
        storedMessages = AIChatStorage.loadMessages()
        storedPresets = AIChatStorage.loadPresets()
        let savedID = AIChatStorage.loadSelectedConfigurationID()
        selectedConfigurationID = configurations.contains(where: { $0.id == savedID }) ? savedID : configurations.first?.id
        if let id = selectedConfigurationID {
            messages = storedMessages[id.uuidString] ?? []
            preset = storedPresets[id.uuidString] ?? ""
        }
    }

    var selectedConfiguration: AIProviderConfiguration? {
        guard let id = selectedConfigurationID else { return nil }
        return configurations.first { $0.id == id }
    }

    var canAddConfiguration: Bool { configurations.count < 3 }

    var shareText: String {
        let title = selectedConfiguration.map { "AI Chat — \($0.name)" } ?? "AI Chat"
        let body = messages.map { message in
            let speaker = message.role == .user ? "You" : "Assistant"
            return "\(speaker):\n\(message.content)"
        }.joined(separator: "\n\n")
        return body.isEmpty ? title : "\(title)\n\n\(body)"
    }

    func apiKey(for configuration: AIProviderConfiguration?) -> String {
        guard let configuration else { return "" }
        return AIKeychainStore.apiKey(for: configuration.id)
    }

    func fetchModels(baseURL: String, apiKey: String) async throws -> [String] {
        try await service.fetchModels(baseURL: baseURL, apiKey: apiKey)
    }

    func saveConfiguration(_ configuration: AIProviderConfiguration, apiKey: String) throws {
        if let index = configurations.firstIndex(where: { $0.id == configuration.id }) {
            configurations[index] = configuration
        } else {
            guard canAddConfiguration else { throw AIChatError.maximumConfigurations }
            configurations.append(configuration)
        }
        try AIKeychainStore.save(apiKey: apiKey, for: configuration.id)
        AIChatStorage.saveConfigurations(configurations)
        selectConfiguration(configuration.id)
    }

    func selectConfiguration(_ id: UUID) {
        guard configurations.contains(where: { $0.id == id }) else { return }
        selectedConfigurationID = id
        messages = storedMessages[id.uuidString] ?? []
        preset = storedPresets[id.uuidString] ?? ""
        errorMessage = nil
        AIChatStorage.saveSelectedConfigurationID(id)
    }

    func refreshSelectedModels() async {
        guard let configuration = selectedConfiguration,
              let index = configurations.firstIndex(where: { $0.id == configuration.id }) else { return }
        do {
            let models = try await fetchModels(baseURL: configuration.baseURL, apiKey: apiKey(for: configuration))
            guard !models.isEmpty else { throw AIChatError.noModel }
            configurations[index].availableModels = models
            if !models.contains(configurations[index].selectedModel) {
                configurations[index].selectedModel = models[0]
            }
            AIChatStorage.saveConfigurations(configurations)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSelectedModel(_ model: String) {
        guard let id = selectedConfigurationID,
              let index = configurations.firstIndex(where: { $0.id == id }),
              configurations[index].availableModels.contains(model) else { return }
        configurations[index].selectedModel = model
        AIChatStorage.saveConfigurations(configurations)
    }

    func deleteConfiguration(_ configuration: AIProviderConfiguration) {
        configurations.removeAll { $0.id == configuration.id }
        storedMessages.removeValue(forKey: configuration.id.uuidString)
        storedPresets.removeValue(forKey: configuration.id.uuidString)
        AIKeychainStore.deleteAPIKey(for: configuration.id)
        AIChatStorage.saveConfigurations(configurations)
        AIChatStorage.saveMessages(storedMessages)
        AIChatStorage.savePresets(storedPresets)
        selectedConfigurationID = configurations.first?.id
        if let id = selectedConfigurationID {
            messages = storedMessages[id.uuidString] ?? []
            preset = storedPresets[id.uuidString] ?? ""
        } else {
            messages = []
            preset = ""
        }
        AIChatStorage.saveSelectedConfigurationID(selectedConfigurationID)
    }

    func savePreset(_ value: String) {
        guard let id = selectedConfigurationID else { return }
        preset = value
        storedPresets[id.uuidString] = value
        AIChatStorage.savePresets(storedPresets)
    }

    func clearMessages() {
        guard let id = selectedConfigurationID else { return }
        messages = []
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        storedMessages[id.uuidString] = []
        AIChatStorage.saveMessages(storedMessages)
    }

    func send() async {
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !isSending else { return }
        guard let configuration = selectedConfiguration else {
            errorMessage = AIChatError.noConfiguration.localizedDescription
            return
        }
        guard !configuration.selectedModel.isEmpty else {
            errorMessage = AIChatError.noModel.localizedDescription
            return
        }

        draft = ""
        errorMessage = nil
        let userMessage = AIChatMessage(role: .user, content: content)
        messages.append(userMessage)
        persistCurrentMessages()
        isSending = true
        defer { isSending = false }

        do {
            let response = try await service.complete(
                configuration: configuration,
                apiKey: apiKey(for: configuration),
                messages: messages,
                preset: preset
            )
            messages.append(AIChatMessage(role: .assistant, content: response))
            persistCurrentMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persistCurrentMessages() {
        guard let id = selectedConfigurationID else { return }
        storedMessages[id.uuidString] = messages
        AIChatStorage.saveMessages(storedMessages)
    }
}
