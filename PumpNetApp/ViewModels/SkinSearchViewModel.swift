import Foundation

@MainActor
final class SkinSearchViewModel: ObservableObject {
    @Published var username = ""
    @Published private(set) var skin: MinecraftSkin?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var history: [String] = []

    private let service: MinecraftSkinService
    private static let historyKey = "skinSearchHistory.v1"

    init(service: MinecraftSkinService = MinecraftSkinService()) {
        self.service = service
        history = UserDefaults.standard.stringArray(forKey: Self.historyKey) ?? []
    }

    var canSearch: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func search() async {
        guard canSearch else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            skin = try await service.fetchSkin(for: username)
            username = skin?.username ?? username
            if let name = skin?.username { recordHistory(name) }
        } catch is CancellationError {
            return
        } catch {
            skin = nil
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Something went wrong. Check your connection and try again."
        }
    }

    func search(username selectedUsername: String) async {
        username = selectedUsername
        await search()
    }

    func clearHistory() {
        history = []
        UserDefaults.standard.removeObject(forKey: Self.historyKey)
    }

    private func recordHistory(_ username: String) {
        history.removeAll { $0.caseInsensitiveCompare(username) == .orderedSame }
        history.insert(username, at: 0)
        history = Array(history.prefix(20))
        UserDefaults.standard.set(history, forKey: Self.historyKey)
    }

    func clearError() {
        errorMessage = nil
    }
}
