import Foundation

struct DeviceMonitorSnapshot {
    let deviceName: String
    let modelIdentifier: String
    let systemVersion: String
    let processorCount: Int
    let physicalMemory: UInt64
    let appMemoryFootprint: UInt64?
    let totalStorage: Int64?
    let availableStorage: Int64?
    let importantStorage: Int64?
    let appStorage: UInt64
    let batteryLevel: Float
    let batteryState: DeviceBatteryState
    let lowPowerModeEnabled: Bool
    let thermalState: DeviceThermalState
    let uptime: TimeInterval
    let refreshedAt: Date
}

enum DeviceBatteryState: String {
    case charging = "Charging"
    case full = "Fully Charged"
    case unplugged = "Unplugged"
    case unknown = "Unavailable"
}

enum DeviceThermalState: String {
    case nominal = "Nominal"
    case fair = "Fair"
    case serious = "Serious"
    case critical = "Critical"
}
