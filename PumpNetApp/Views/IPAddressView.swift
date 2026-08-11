import SwiftUI

struct IPAddressView: View {
    @StateObject private var viewModel = IPLookupViewModel()
    @State private var pendingLookup: IPLookupKind?
    @State private var showingPrivacyWarning = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "network")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.green)
                    Text("IP Lookup").font(.title.bold())
                    Text("Check the public IP address seen by websites and internet services.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 14) {
                    lookupButton("See IP Address Only", systemImage: "number", kind: .addressOnly)
                    Divider()
                    lookupButton("See IP Address and Region, ISP, etc.", systemImage: "map.fill", kind: .details)
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                } else if let details = viewModel.details {
                    detailsCard(details)
                } else if let address = viewModel.address {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Public IP Address").font(.headline)
                        Text(address).font(.title3.monospaced()).textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.green.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(20)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("IP Lookup")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Privacy Warning", isPresented: $showingPrivacyWarning) {
            Button("Continue") {
                guard let lookup = pendingLookup else { return }
                pendingLookup = nil
                Task { await viewModel.lookup(lookup) }
            }
            Button("Cancel", role: .cancel) { pendingLookup = nil }
        } message: {
            Text("Your real IP address will be exposed to the IP lookup provider unless you have Advanced Privacy Protection on or other VPN Proxy software on.")
        }
    }

    private func lookupButton(_ title: String, systemImage: String, kind: IPLookupKind) -> some View {
        Button {
            pendingLookup = kind
            showingPrivacyWarning = true
        } label: {
            Group {
                if viewModel.loadingKind == kind { ProgressView() }
                else { Label(title, systemImage: systemImage) }
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(viewModel.loadingKind != nil)
    }

    private func detailsCard(_ details: IPInfoResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("IP and Network Information").font(.headline)
            detailRow("IP Address", value: details.ip)
            detailRow("City", value: details.city)
            detailRow("Region", value: details.region)
            detailRow("Country", value: details.country)
            detailRow("ISP / Organization", value: details.org)
            detailRow("Postal Code", value: details.postal)
            detailRow("Timezone", value: details.timezone)
            detailRow("Coordinates", value: details.loc)
        }
        .padding()
        .background(.green.opacity(0.09), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder private func detailRow(_ label: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(label).foregroundStyle(.secondary)
                Spacer(minLength: 16)
                Text(value).multilineTextAlignment(.trailing).textSelection(.enabled)
            }
            Divider()
        }
    }
}

#Preview { NavigationStack { IPAddressView() } }
