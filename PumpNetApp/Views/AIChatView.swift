import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var showingConfigurations = false
    @State private var showingPreset = false
    @State private var showingClearWarning = false
    @FocusState private var composerFocused: Bool

    var body: some View {
        Group {
            if viewModel.configurations.isEmpty {
                ContentUnavailableView {
                    Label("Set Up AI Chat", systemImage: "bubble.left.and.text.bubble.right.fill")
                } description: {
                    Text("Add an OpenAI-compatible provider to start chatting.")
                } actions: {
                    Button("Add Configuration") { showingConfigurations = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
            } else {
                chatContent
            }
        }
        .background(AppAmbientBackground())
        .navigationTitle("AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { chatToolbar }
        .sheet(isPresented: $showingConfigurations) {
            AIConfigurationListView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingPreset) {
            AIPresetEditorView(preset: viewModel.preset) { viewModel.savePreset($0) }
        }
        .alert("Clear Chat?", isPresented: $showingClearWarning) {
            Button("Clear", role: .destructive) { viewModel.clearMessages() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All messages in this configuration will be removed from this device.")
        }
        .alert("AI Chat Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    configurationHeader

                    if viewModel.messages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 38))
                                .foregroundStyle(.green)
                            Text("Start a Conversation")
                                .font(.title3.bold())
                            Text("Messages are sent to your selected AI provider.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 60)
                    } else {
                        ForEach(viewModel.messages) { message in
                            AIMessageBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if viewModel.isSending {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Thinking…").foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .id("thinking")
                    }
                }
                .padding(16)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    if let last = viewModel.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
        }
    }

    private var configurationHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "server.rack")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedConfiguration?.name ?? "No Configuration")
                    .font(.headline)
                Text(viewModel.selectedConfiguration?.selectedModel ?? "No model")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let configuration = viewModel.selectedConfiguration, !configuration.availableModels.isEmpty {
                Menu {
                    ForEach(configuration.availableModels, id: \.self) { model in
                        Button {
                            viewModel.updateSelectedModel(model)
                        } label: {
                            if configuration.selectedModel == model {
                                Label(model, systemImage: "checkmark")
                            } else {
                                Text(model)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(14)
        .liquidGlassSurface(cornerRadius: 16, tint: .green.opacity(0.08), interactive: true)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $viewModel.draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($composerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.green)
            }
            .disabled(viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    @ToolbarContentBuilder private var chatToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { showingConfigurations = true } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .accessibilityLabel("AI Configurations")
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            ShareLink(item: viewModel.shareText) {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(viewModel.messages.isEmpty)

            Menu {
                Button("Set Preset", systemImage: "text.badge.star") {
                    showingPreset = true
                }
                Button("Refresh Models", systemImage: "arrow.clockwise") {
                    Task { await viewModel.refreshSelectedModels() }
                }
                Button("Clear Chat", systemImage: "trash", role: .destructive) {
                    showingClearWarning = true
                }
                .disabled(viewModel.messages.isEmpty)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .disabled(viewModel.selectedConfiguration == nil)
        }
    }

    private func sendMessage() {
        Task { await viewModel.send() }
    }
}

private struct AIMessageBubble: View {
    let message: AIChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 44) }
            Text(message.content)
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .foregroundStyle(message.role == .user ? AnyShapeStyle(Color.white) : AnyShapeStyle(.primary))
                .background(
                    message.role == .user ? AnyShapeStyle(Color.green) : AnyShapeStyle(.thinMaterial),
                    in: RoundedRectangle(cornerRadius: 17, style: .continuous)
                )
            if message.role == .assistant { Spacer(minLength: 44) }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview { NavigationStack { AIChatView() } }
