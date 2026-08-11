import SwiftUI

struct SettingsView: View {
    @State private var showingClearCacheWarning = false

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    NavigationLink {
                        AdvancedPrivacyProtectionView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Advanced Privacy Protection")
                                Text("Tor protection for in-app network requests")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "shield.lefthalf.filled")
                                .foregroundStyle(.green)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingClearCacheWarning = true
                    } label: {
                        Label("Clear Cache", systemImage: "trash.fill")
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Removes cached articles and network responses. Search history is not affected.")
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Clear Cache?", isPresented: $showingClearCacheWarning) {
            Button("Clear Cache", role: .destructive) { AppCache.clear() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Cached articles will be removed and must be downloaded again. This action cannot be undone.")
        }
    }
}

#Preview { SettingsView() }
