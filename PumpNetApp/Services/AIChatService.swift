import Foundation

struct AIChatService {
    private struct CompletionRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        let model: String
        let messages: [Message]
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchModels(baseURL: String, apiKey: String) async throws -> [String] {
        let url = try endpoint(baseURL: baseURL, path: "models")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        authorize(&request, apiKey: apiKey)
        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        let models = try parseModels(from: data)
        guard !models.isEmpty else {
            throw AIChatError.server("The provider returned an empty model list.")
        }
        return Array(Set(models)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func complete(configuration: AIProviderConfiguration, apiKey: String, messages: [AIChatMessage], preset: String) async throws -> String {
        let url = try endpoint(baseURL: configuration.baseURL, path: "chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        authorize(&request, apiKey: apiKey)

        var requestMessages: [CompletionRequest.Message] = []
        let trimmedPreset = preset.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPreset.isEmpty {
            requestMessages.append(.init(role: "system", content: trimmedPreset))
        }
        requestMessages.append(contentsOf: messages.map {
            .init(role: $0.role.rawValue, content: $0.content)
        })
        request.httpBody = try JSONEncoder().encode(CompletionRequest(model: configuration.selectedModel, messages: requestMessages))

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)
        return try parseCompletion(from: data)
    }

    private func endpoint(baseURL: String, path: String) throws -> URL {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed), components.host != nil else {
            throw AIChatError.invalidBaseURL
        }
        guard components.scheme?.lowercased() == "https" else {
            throw AIChatError.insecureBaseURL
        }
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + (basePath.isEmpty ? path : basePath + "/" + path)
        guard let url = components.url else { throw AIChatError.invalidBaseURL }
        return url
    }

    private func authorize(_ request: inout URLRequest, apiKey: String) {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedKey.isEmpty {
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { throw AIChatError.invalidResponse }
        guard (200...299).contains(httpResponse.statusCode) else {
            if let message = providerErrorMessage(from: data) { throw AIChatError.server(message) }
            throw AIChatError.server("The AI provider returned HTTP \(httpResponse.statusCode).")
        }
    }

    private func parseModels(from data: Data) throws -> [String] {
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            throw AIChatError.server("The model endpoint did not return valid JSON.")
        }

        let rawModels: [Any]
        if let dictionary = json as? [String: Any], let dataModels = dictionary["data"] as? [Any] {
            rawModels = dataModels
        } else if let dictionary = json as? [String: Any], let models = dictionary["models"] as? [Any] {
            rawModels = models
        } else if let array = json as? [Any] {
            rawModels = array
        } else {
            throw AIChatError.server("The provider's model list is not in a supported format. Check that the Base URL points to an OpenAI-compatible API root.")
        }

        return rawModels.compactMap { item in
            if let identifier = item as? String { return identifier }
            guard let dictionary = item as? [String: Any] else { return nil }
            return (dictionary["id"] as? String)
                ?? (dictionary["name"] as? String)
                ?? (dictionary["model"] as? String)
        }
    }

    private func parseCompletion(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let dictionary = json as? [String: Any] else {
            throw AIChatError.server("The chat endpoint did not return valid JSON.")
        }

        if let choices = dictionary["choices"] as? [[String: Any]], let choice = choices.first {
            if let message = choice["message"] as? [String: Any] {
                if let content = message["content"] as? String, let result = nonempty(content) { return result }
                if let blocks = message["content"] as? [[String: Any]] {
                    let combined = blocks.compactMap { block -> String? in
                        if let text = block["text"] as? String { return text }
                        if let text = block["text"] as? [String: Any] { return text["value"] as? String }
                        return nil
                    }.joined(separator: "\n")
                    if let result = nonempty(combined) { return result }
                }
                if let reasoning = message["reasoning"] as? String, let result = nonempty(reasoning) { return result }
            }
            if let text = choice["text"] as? String, let result = nonempty(text) { return result }
        }

        if let candidates = dictionary["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]] {
            let combined = parts.compactMap { $0["text"] as? String }.joined(separator: "\n")
            if let result = nonempty(combined) { return result }
        }

        if let message = providerErrorMessage(from: data) { throw AIChatError.server(message) }
        throw AIChatError.server("The provider returned a response, but no text message could be found in it.")
    }

    private func providerErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let dictionary = json as? [String: Any] else { return nil }
        if let error = dictionary["error"] as? [String: Any] {
            return (error["message"] as? String) ?? (error["detail"] as? String)
        }
        if let error = dictionary["error"] as? String { return error }
        return (dictionary["message"] as? String) ?? (dictionary["detail"] as? String)
    }

    private func nonempty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
