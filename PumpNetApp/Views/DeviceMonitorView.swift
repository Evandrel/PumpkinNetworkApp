import SwiftUI

struct DeviceMonitorView: View {
    @StateObject private var viewModel = DeviceMonitorViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                if let snapshot = viewModel.snapshot {
                    overviewCard(snapshot)
                    storageCard(snapshot)
                    memoryCard(snapshot)
                    powerCard(snapshot)
                    privacyNote
                } else if viewModel.isLoading {
                    ProgressView("Reading device information…")
                        .frame(maxWidth: .infinity, minHeight: 260)
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView("Unable to Read Device Information", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                }
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(AppAmbientBackground())
        .navigationTitle("Device Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await viewModel.refresh() } } label: {
                    if viewModel.isLoading { ProgressView() }
                    else { Image(systemName: "arrow.clockwise") }
                }
                .disabled(viewModel.isLoading)
                .accessibilityLabel("Refresh device information")
            }
        }
        .task { await viewModel.refresh() }
    }

    private var header: some View {
        VStack(spacing: 9) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.green)
            Text("Device Monitor").font(.title.bold())
            Text("Storage, memory, power and system information for this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func overviewCard(_ snapshot: DeviceMonitorSnapshot) -> some View {
        monitorCard("Overview", systemImage: "iphone.gen3") {
            monitorRow("Device", snapshot.deviceName)
            monitorRow("Model", snapshot.modelIdentifier, monospaced: true)
            monitorRow("System", snapshot.systemVersion)
            monitorRow("CPU Cores", "\(snapshot.processorCount)")
            monitorRow("Uptime", durationString(snapshot.uptime))
        }
    }

    private func storageCard(_ snapshot: DeviceMonitorSnapshot) -> some View {
        monitorCard("Storage", systemImage: "internaldrive.fill") {
            if let total = snapshot.totalStorage, let available = snapshot.availableStorage {
                let used = max(0, total - available)
                storageProgress(used: used, total: total)
                monitorRow("Used", byteString(used))
                monitorRow("Available", byteString(available))
                monitorRow("Total", byteString(total))
                if let important = snapshot.importantStorage {
                    monitorRow("Important Usage Available", byteString(important))
                }
            } else {
                Text("Storage capacity is unavailable on this device.").foregroundStyle(.secondary)
            }
            Divider()
            monitorRow("PumpNet Data", byteString(snapshot.appStorage))
        }
    }

    private func memoryCard(_ snapshot: DeviceMonitorSnapshot) -> some View {
        monitorCard("Memory", systemImage: "memorychip.fill") {
            monitorRow("Device Memory", byteString(snapshot.physicalMemory))
            if let footprint = snapshot.appMemoryFootprint {
                monitorRow("PumpNet Memory", byteString(footprint))
            } else {
                monitorRow("PumpNet Memory", "Unavailable")
            }
        }
    }

    private func powerCard(_ snapshot: DeviceMonitorSnapshot) -> some View {
        monitorCard("Power & Temperature", systemImage: "bolt.batteryblock.fill") {
            if snapshot.batteryLevel >= 0 {
                monitorRow("Battery", "\(Int((snapshot.batteryLevel * 100).rounded()))%")
            } else {
                monitorRow("Battery", "Unavailable")
            }
            monitorRow("Battery State", snapshot.batteryState.rawValue)
            monitorRow("Low Power Mode", snapshot.lowPowerModeEnabled ? "On" : "Off")
            monitorRow("Thermal State", snapshot.thermalState.rawValue)
            monitorRow("Last Updated", snapshot.refreshedAt.formatted(date: .omitted, time: .shortened))
        }
    }

    private var privacyNote: some View {
        Label("iOS protects other apps’ data. This tool shows device-wide capacity and PumpNet’s own usage, but cannot inspect other apps or background processes.", systemImage: "lock.shield.fill")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .liquidGlassSurface(cornerRadius: 18, tint: .green.opacity(0.04))
    }

    private func monitorCard<Content: View>(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.green)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .liquidGlassSurface(cornerRadius: 22, tint: .green.opacity(0.045))
    }

    private func monitorRow(_ title: String, _ value: String, monospaced: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            if monospaced { Text(value).font(.subheadline.monospaced()).multilineTextAlignment(.trailing) }
            else { Text(value).multilineTextAlignment(.trailing) }
        }
    }

    private func storageProgress(used: Int64, total: Int64) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ProgressView(value: Double(used), total: Double(total)).tint(.green)
            Text("\(Int((Double(used) / Double(total) * 100).rounded()))% used")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func byteString(_ bytes: Int64) -> String { ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) }
    private func byteString(_ bytes: UInt64) -> String { ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .file) }
    private func durationString(_ duration: TimeInterval) -> String { Duration.seconds(duration).formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated, maximumUnitCount: 2)) }
}

#Preview { NavigationStack { DeviceMonitorView() } }
