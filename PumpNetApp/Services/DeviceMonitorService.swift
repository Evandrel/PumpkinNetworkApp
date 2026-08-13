import Foundation
import MachO
import UIKit

@MainActor
struct DeviceMonitorService {
    func loadSnapshot() async -> DeviceMonitorSnapshot {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        let storageValues = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])
        let appStorage = await Task.detached(priority: .utility) {
            await Self.applicationStorageBytes()
        }.value

        return DeviceMonitorSnapshot(
            deviceName: device.name,
            modelIdentifier: Self.modelIdentifier(),
            systemVersion: "\(device.systemName) \(device.systemVersion)",
            processorCount: ProcessInfo.processInfo.processorCount,
            physicalMemory: ProcessInfo.processInfo.physicalMemory,
            appMemoryFootprint: Self.appMemoryFootprint(),
            totalStorage: storageValues?.volumeTotalCapacity.map { Int64($0) },
            availableStorage: storageValues?.volumeAvailableCapacity.map { Int64($0) },
            importantStorage: storageValues?.volumeAvailableCapacityForImportantUsage.map { Int64($0) },
            appStorage: appStorage,
            batteryLevel: device.batteryLevel,
            batteryState: Self.batteryState(for: device.batteryState),
            lowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermalState: Self.thermalState(for: ProcessInfo.processInfo.thermalState),
            uptime: ProcessInfo.processInfo.systemUptime,
            refreshedAt: .now
        )
    }

    private static func appMemoryFootprint() -> UInt64? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? info.phys_footprint : nil
    }

    private static func applicationStorageBytes() -> UInt64 {
        let roots: [URL] = [
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        ].compactMap { $0 }
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]

        var total: UInt64 = 0
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let file as URL in enumerator {
                guard let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true else {
                    continue
                }
                total += UInt64(values.fileSize ?? 0)
            }
        }
        return total
    }

    private static func modelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }

    private static func batteryState(for state: UIDevice.BatteryState) -> DeviceBatteryState {
        switch state {
        case .charging: .charging
        case .full: .full
        case .unplugged: .unplugged
        case .unknown: .unknown
        @unknown default: .unknown
        }
    }

    private static func thermalState(for state: ProcessInfo.ThermalState) -> DeviceThermalState {
        switch state {
        case .nominal: .nominal
        case .fair: .fair
        case .serious: .serious
        case .critical: .critical
        @unknown default: .nominal
        }
    }
}
