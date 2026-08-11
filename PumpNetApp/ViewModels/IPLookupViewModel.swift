import Foundation

@MainActor
final class IPLookupViewModel: ObservableObject {
    @Published private(set) var address: String?
    @Published private(set) var details: IPInfoResponse?
    @Published private(set) var errorMessage: String?
    @Published private(set) var loadingKind: IPLookupKind?
    private let service: IPLookupService

    init(service: IPLookupService = IPLookupService()) {
        self.service = service
    }

    func lookup(_ kind: IPLookupKind) async {
        guard loadingKind == nil else { return }
        loadingKind = kind
        address = nil
        details = nil
        errorMessage = nil
        defer { loadingKind = nil }

        do {
            switch kind {
            case .addressOnly: address = try await service.fetchAddress().ip
            case .details: details = try await service.fetchDetails()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
