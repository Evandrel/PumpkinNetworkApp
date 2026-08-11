import SwiftUI

struct SkinStealerView: View {
    @StateObject private var viewModel = SkinSearchViewModel()
    @FocusState private var isSearchFocused: Bool
    @State private var showingHistory = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                hero
                searchForm

                if viewModel.isLoading {
                    loadingCard
                } else if let skin = viewModel.skin {
                    SkinResultCard(skin: skin)
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                } else {
                    EmptySkinCard()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(AppAmbientBackground())
        .navigationTitle("Skin Stealer")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingHistory = true } label: { Image(systemName: "clock.arrow.circlepath") }
                    .accessibilityLabel("Skin search history")
            }
        }
        .sheet(isPresented: $showingHistory) {
            SearchHistoryView(title: "Skin History", systemImage: "person.crop.square", history: viewModel.history) { username in
                isSearchFocused = false
                Task { await viewModel.search(username: username) }
            } onClear: {
                viewModel.clearHistory()
            }
        }
        .animation(.snappy, value: viewModel.isLoading)
        .animation(.snappy, value: viewModel.skin?.profileID)
        .alert(
            "Couldn't Get Skin",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.square.filled.and.at.rectangle")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 76, height: 76)
                .liquidGlassSurface(cornerRadius: 24, tint: .green.opacity(0.12))

            Text("Find any Java Edition skin").font(.title2.bold())
            Text("Enter a Minecraft username to preview and save the player's current skin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var searchForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Minecraft username").font(.subheadline.weight(.semibold))

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("e.g. Notch", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .focused($isSearchFocused)
                    .onSubmit(search)

                if !viewModel.username.isEmpty {
                    Button { viewModel.username = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                    .accessibilityLabel("Clear username")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .liquidGlassSurface(cornerRadius: 14, tint: .green.opacity(0.04), interactive: true)

            Button(action: search) {
                Label("Get Skin", systemImage: "arrow.down.square.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .primaryGlassButton()
            .tint(.green)
            .disabled(!viewModel.canSearch)
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Fetching skin…").font(.headline)
            Text("Checking Minecraft's profile servers").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .liquidGlassSurface(cornerRadius: 22)
    }

    private func search() {
        isSearchFocused = false
        Task { await viewModel.search() }
    }
}

private struct SkinResultCard: View {
    private enum PreviewMode: String, CaseIterable {
        case model = "3D Model"
        case texture = "Texture"
    }

    let skin: MinecraftSkin
    @State private var previewMode: PreviewMode = .model

    var body: some View {
        VStack(spacing: 20) {
            Picker("Preview", selection: $previewMode) {
                ForEach(PreviewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch previewMode {
                case .model:
                    VStack(spacing: 4) {
                        MinecraftSkin3DView(skin: skin).frame(height: 360)
                        Label("Drag in any direction · Double-tap to reset", systemImage: "rotate.3d")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                case .texture:
                    SkinTextureView(imageData: skin.imageData).frame(height: 320).padding(24)
                }
            }
            .frame(maxWidth: .infinity)
            .background(skinBackdrop, in: RoundedRectangle(cornerRadius: 18))
            .liquidGlassSurface(cornerRadius: 18, tint: .green.opacity(0.08))

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(skin.username).font(.title3.bold())
                    Text("\(skin.model.rawValue) model").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                ShareLink(
                    item: SkinFile(data: skin.imageData, filename: skin.filename),
                    preview: SharePreview(skin.filename)
                ) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .secondaryGlassButton()
                .tint(.green)
            }
        }
        .padding(16)
        .liquidGlassSurface(cornerRadius: 22, tint: .green.opacity(0.035))
    }

    private var skinBackdrop: some ShapeStyle {
        LinearGradient(colors: [.green.opacity(0.18), .cyan.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct EmptySkinCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.3x3.square").font(.system(size: 40)).foregroundStyle(.secondary)
            Text("Your skin preview will appear here").font(.headline)
            Text("Minecraft Java Edition usernames are 1–16 characters long.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding()
        .liquidGlassSurface(cornerRadius: 22)
    }
}

#Preview { NavigationStack { SkinStealerView() } }
