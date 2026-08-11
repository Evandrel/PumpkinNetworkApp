import SwiftUI

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Minecraft") {
                    NavigationLink {
                        SkinStealerView()
                    } label: {
                        toolLabel("Skin Stealer", subtitle: "Find, preview and save Java Edition skins", systemImage: "person.crop.square.filled.and.at.rectangle")
                    }
                }

                Section("Apple") {
                    NavigationLink {
                        SHSHView()
                    } label: {
                        toolLabel("SHSH2 Checker", subtitle: "Check saved SHSH blobs by ECID", systemImage: "checkmark.shield.fill")
                    }
                }

                Section("Network") {
                    NavigationLink {
                        IPAddressView()
                    } label: {
                        toolLabel("IP Lookup", subtitle: "See your public IP and network information", systemImage: "network")
                    }
                }
            }
            .navigationTitle("Tools")
        }
    }

    private func toolLabel(_ title: String, subtitle: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage).foregroundStyle(.green)
        }
    }
}

#Preview { ToolsView() }
