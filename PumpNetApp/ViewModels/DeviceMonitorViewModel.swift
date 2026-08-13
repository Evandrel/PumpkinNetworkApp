import Foundation

@MainActor
final class DeviceMonitorViewModel: ObservableObject {
    @Published private(set) var snapshot: DeviceMonitorSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: DeviceMonitorService

    init() {
        service = DeviceMonitorService()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        snapshot = await service.loadSnapshot()
    }
}
