import Foundation
import Security

enum AIChatStorage {
    private static let configurationsKey = "aiChat.configurations.v1"
    private static let selectedConfigurationKey = "aiChat.selectedConfiguration.v1"
    private static let messagesKey = "aiChat.messages.v1"
    private static let presetsKey = "aiChat.presets.v1"

    static func loadConfigurations() -> [AIProviderConfiguration] {
        guard let data = UserDefaults.standard.data(forKey: configurationsKey) else { return [] }
        return (try? JSONDecoder().decode([AIProviderConfiguration].self, from: data)) ?? []
    }

    static func saveConfigurations(_ configurations: [AIProviderConfiguration]) {
        guard let data = try? JSONEncoder().encode(configurations) else { return }
        UserDefaults.standard.set(data, forKey: configurationsKey)
    }

    static func loadSelectedConfigurationID() -> UUID? {
        guard let value = UserDefaults.standard.string(forKey: selectedConfigurationKey) else { return nil }
        return UUID(uuidString: value)
    }

    static func saveSelectedConfigurationID(_ id: UUID?) {
        UserDefaults.standard.set(id?.uuidString, forKey: selectedConfigurationKey)
    }

    static func loadMessages() -> [String: [AIChatMessage]] {
        guard let data = UserDefaults.standard.data(forKey: messagesKey) else { return [:] }
        return (try? JSONDecoder().decode([String: [AIChatMessage]].self, from: data)) ?? [:]
    }

    static func saveMessages(_ messages: [String: [AIChatMessage]]) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: messagesKey)
    }

    static func loadPresets() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: presetsKey) else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }

    static func savePresets(_ presets: [String: String]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: presetsKey)
    }
}

enum AIKeychainStore {
    private static let service = Bundle.main.bundleIdentifier.map { "\($0).ai-chat" } ?? "PumpNet.ai-chat"

    static func apiKey(for configurationID: UUID) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: configurationID.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else { return "" }
        return key
    }

    static func save(apiKey: String, for configurationID: UUID) throws {
        let accountQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: configurationID.uuidString
        ]
        let value = Data(apiKey.utf8)
        let status: OSStatus
        if SecItemCopyMatching(accountQuery as CFDictionary, nil) == errSecSuccess {
            status = SecItemUpdate(accountQuery as CFDictionary, [kSecValueData as String: value] as CFDictionary)
        } else {
            var newItem = accountQuery
            newItem[kSecValueData as String] = value
            status = SecItemAdd(newItem as CFDictionary, nil)
        }
        guard status == errSecSuccess else {
            throw AIChatError.server("The API key could not be saved securely (\(status)).")
        }
    }

    static func deleteAPIKey(for configurationID: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: configurationID.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }
}
