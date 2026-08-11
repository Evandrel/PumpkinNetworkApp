import Foundation

struct IPLookupService {
    func fetchAddress() async throws -> IPAddressResponse {
        try await request("https://api64.ipify.org?format=json")
    }

    func fetchDetails() async throws -> IPInfoResponse {
        try await request("https://ipinfo.io/json")
    }

    private func request<T: Decodable>(_ address: String) async throws -> T {
        guard let url = URL(string: address) else { throw IPLookupError.invalidResponse }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw IPLookupError.invalidResponse
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw IPLookupError.invalidResponse }
    }
}
