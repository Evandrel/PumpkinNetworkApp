import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var showingConfigurations = false
    @State private var conversationToDelete: AIConversation?
    @State private var newConversationID: UUID?
    @State private var openingNewConversation = false

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
            } else if viewModel.conversations.isEmpty {
                ContentUnavailableView {
                    Label("No Conversations", systemImage: "bubble.left.and.bubble.right")
                } description: {
                    Text("Create a conversation, then choose its provider and model inside the chat.")
                } actions: {
                    Button("New Conversation") { createConversation() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
            } else {
                conversationList
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("AI Chat")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showingConfigurations = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("AI Configurations")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { createConversation() } label: {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(viewModel.configurations.isEmpty)
                .accessibilityLabel("New Conversation")
            }
        }
        .sheet(isPresented: $showingConfigurations) {
            AIConfigurationListView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $openingNewConversation) {
            if let newConversationID {
                AIConversationView(viewModel: viewModel, conversationID: newConversationID)
            }
        }
        .alert("Delete Conversation?", isPresented: Binding(
            get: { conversationToDelete != nil },
            set: { if !$0 { conversationToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let conversationToDelete { viewModel.deleteConversation(conversationToDelete.id) }
                conversationToDelete = nil
            }
            Button("Cancel", role: .cancel) { conversationToDelete = nil }
        } message: {
            Text("This conversation and all of its messages will be removed from this device.")
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

    private var conversationList: some View {
        List {
            Section {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink {
                        AIConversationView(viewModel: viewModel, conversationID: conversation.id)
                    } label: {
                        conversationRow(conversation)
                    }
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            conversationToDelete = conversation
                        }
                    }
                }
            } header: {
                Text("Conversations")
            } footer: {
                Text("Each conversation keeps its own messages, preset, provider and model.")
            }
        }
    }

    private func conversationRow(_ conversation: AIConversation) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(conversationSubtitle(conversation))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(conversation.updatedAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 3)
    }

    private func conversationSubtitle(_ conversation: AIConversation) -> String {
        let provider = viewModel.configurations.first(where: { $0.id == conversation.configurationID })?.name ?? "No provider"
        let model = conversation.selectedModel.isEmpty ? "No model" : conversation.selectedModel
        return "\(provider) · \(model)"
    }

    private func createConversation() {
        guard let id = viewModel.createConversation() else { return }
        newConversationID = id
        openingNewConversation = true
    }
}

struct AIConversationView: View {
    @ObservedObject var viewModel: AIChatViewModel
    let conversationID: UUID
    @State private var draft = ""
    @State private var showingConfigurations = false
    @State private var showingPreset = false
    @State private var showingClearWarning = false
    @FocusState private var composerFocused: Bool

    private var conversation: AIConversation? { viewModel.conversation(id: conversationID) }
    private var configuration: AIProviderConfiguration? { viewModel.configuration(for: conversationID) }

    var body: some View {
        Group {
            if conversation == nil {
                ContentUnavailableView("Conversation Not Found", systemImage: "exclamationmark.bubble")
            } else {
                chatContent
            }
        }
        .background(AppAmbientBackground())
        .navigationTitle(conversation?.title ?? "AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { chatToolbar }
        .sheet(isPresented: $showingConfigurations) {
            AIConfigurationListView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingPreset) {
            AIPresetEditorView(preset: conversation?.preset ?? "") {
                viewModel.savePreset($0, for: conversationID)
            }
        }
        .alert("Clear Conversation?", isPresented: $showingClearWarning) {
            Button("Clear", role: .destructive) { viewModel.clearConversation(conversationID) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All messages in this conversation will be removed from this device.")
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

                    if conversation?.messages.isEmpty != false {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 38))
                                .foregroundStyle(.green)
                            Text("Start This Conversation")
                                .font(.title3.bold())
                            Text("You can switch the provider and model above without clearing this conversation.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 56)
                    } else if let messages = conversation?.messages {
                        ForEach(messages) { message in
                            AIMessageBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if viewModel.isSending(conversationID) {
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
            .onChange(of: conversation?.messages.count ?? 0) { _, _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    if let last = conversation?.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
        }
    }

    private var configurationHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Provider and Model", systemImage: "server.rack")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    providerMenu
                    modelMenu
                    refreshModelsButton
                }
                VStack(spacing: 10) {
                    providerMenu
                    modelMenu
                    refreshModelsButton
                }
            }
            Text("The selected provider receives this conversation when you send the next message.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .liquidGlassSurface(cornerRadius: 16, tint: .green.opacity(0.08), interactive: true)
    }

    private var providerMenu: some View {
        Menu {
            ForEach(viewModel.configurations) { item in
                Button {
                    viewModel.selectConfiguration(item.id, for: conversationID)
                } label: {
                    if item.id == conversation?.configurationID {
                        Label(item.name, systemImage: "checkmark")
                    } else {
                        Text(item.name)
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "network")
                Text(configuration?.name ?? "Choose Provider").lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.green)
    }

    private var modelMenu: some View {
        Menu {
            if let models = configuration?.availableModels, !models.isEmpty {
                ForEach(models, id: \.self) { model in
                    Button {
                        viewModel.selectModel(model, for: conversationID)
                    } label: {
                        if model == conversation?.selectedModel {
                            Label(model, systemImage: "checkmark")
                        } else {
                            Text(model)
                        }
                    }
                }
            } else {
                Text("Refresh models first")
            }
        } label: {
            HStack {
                Image(systemName: "cpu")
                Text(conversation?.selectedModel.isEmpty == false ? conversation?.selectedModel ?? "Model" : "Choose Model")
                    .lineLimit(1)
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down")
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.green)
        .disabled(configuration == nil)
    }

    private var refreshModelsButton: some View {
        Button {
            Task { await viewModel.refreshModels(for: conversationID) }
        } label: {
            Image(systemName: "arrow.clockwise")
                .frame(width: 42, height: 42)
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .foregroundStyle(.green)
        .disabled(configuration == nil)
        .accessibilityLabel("Refresh Models")
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($composerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .frame(minHeight: 44)
                .liquidGlassSurface(
                    cornerRadius: 20,
                    tint: .green.opacity(0.06),
                    interactive: true
                )
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.green)
                    .frame(width: 50, height: 50)
                    .contentShape(Circle())
                    .circularLiquidGlass(
                        tint:.green.opacity(0.12),
                        interactive:true
                    )

            }
            .buttonStyle(.plain)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.sendingConversationID != nil)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ToolbarContentBuilder private var chatToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            ShareLink(item: viewModel.shareText(for: conversationID)) {
                Image(systemName: "square.and.arrow.up")
            }
            .disabled(conversation?.messages.isEmpty != false)

            Menu {
                Button("Set Preset", systemImage: "text.badge.star") {
                    showingPreset = true
                }
                Button("Manage Configurations", systemImage: "slider.horizontal.3") {
                    showingConfigurations = true
                }
                Button("Clear Conversation", systemImage: "trash", role: .destructive) {
                    showingClearWarning = true
                }
                .disabled(conversation?.messages.isEmpty != false)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func sendMessage() {
        let message = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        draft = ""
        Task { await viewModel.send(message, in: conversationID) }
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
