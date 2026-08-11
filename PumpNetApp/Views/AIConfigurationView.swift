import SwiftUI

struct AIConfigurationListView: View {
    @ObservedObject var viewModel: AIChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewConfiguration = false
    @State private var editingConfiguration: AIProviderConfiguration?
    @State private var configurationToDelete: AIProviderConfiguration?
    @State private var showingUnlockPrompt = false
    @State private var showingInvalidUnlockCode = false
    @State private var unlockCode = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.configurations.isEmpty {
                        Text("No AI configurations yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.configurations) { configuration in
                            configurationRow(configuration)
                                .swipeActions {
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        configurationToDelete = configuration
                                    }
                                }
                        }
                    }
                } header: {
                    Text("Configurations")
                } footer: {
                    Text(viewModel.configurationLimitUnlocked ? "The configuration limit is unlocked. API keys are stored securely in Keychain." : "You can save up to three OpenAI-compatible providers. API keys are stored securely in Keychain.")
                }

                Section {
                    if viewModel.canAddConfiguration {
                        Button {
                            showingNewConfiguration = true
                        } label: {
                            Label("Add Configuration", systemImage: "plus.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            unlockCode = ""
                            showingUnlockPrompt = true
                        } label: {
                            Label("Unlock More Configurations", systemImage: "lock.open.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .navigationTitle("AI Configurations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewConfiguration) {
                NavigationStack {
                    AIConfigurationEditorView(viewModel: viewModel, configuration: nil)
                }
            }
            .sheet(item: $editingConfiguration) { configuration in
                NavigationStack {
                    AIConfigurationEditorView(viewModel: viewModel, configuration: configuration)
                }
            }
            .alert("Delete Configuration?", isPresented: Binding(
                get: { configurationToDelete != nil },
                set: { if !$0 { configurationToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let configurationToDelete {
                        viewModel.deleteConfiguration(configurationToDelete)
                    }
                    configurationToDelete = nil
                }
                Button("Cancel", role: .cancel) { configurationToDelete = nil }
            } message: {
                Text("Its API key, preset and chat history will be removed from this device.")
            }
            .alert("Unlock More Configurations", isPresented: $showingUnlockPrompt) {
                SecureField("Unlock Code", text: $unlockCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Unlock") {
                    if !viewModel.unlockConfigurationLimit(with: unlockCode) {
                        showingInvalidUnlockCode = true
                    }
                    unlockCode = ""
                }
                Button("Cancel", role: .cancel) { unlockCode = "" }
            } message: {
                Text("Enter the unlock code to add a fourth configuration and remove the configuration limit on this device.")
            }
            .alert("Incorrect Unlock Code", isPresented: $showingInvalidUnlockCode) {
                Button("OK") {}
            } message: {
                Text("The unlock code is incorrect.")
            }
        }
    }

    private func configurationRow(_ configuration: AIProviderConfiguration) -> some View {
        HStack(spacing: 12) {
            Button {
                viewModel.selectConfiguration(configuration.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.selectedConfigurationID == configuration.id ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(configuration.name).foregroundStyle(.primary)
                        Text(configuration.selectedModel.isEmpty ? "No model selected" : configuration.selectedModel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                editingConfiguration = configuration
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(configuration.name)")
        }
    }
}

struct AIConfigurationEditorView: View {
    @ObservedObject var viewModel: AIChatViewModel
    @Environment(\.dismiss) private var dismiss
    private let configurationID: UUID
    private let isNew: Bool

    @State private var name: String
    @State private var apiKey: String
    @State private var baseURL: String
    @State private var models: [String]
    @State private var selectedModel: String
    @State private var isRefreshing = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(viewModel: AIChatViewModel, configuration: AIProviderConfiguration?) {
        self.viewModel = viewModel
        configurationID = configuration?.id ?? UUID()
        isNew = configuration == nil
        _name = State(initialValue: configuration?.name ?? "")
        _apiKey = State(initialValue: viewModel.apiKey(for: configuration))
        _baseURL = State(initialValue: configuration?.baseURL ?? "https://api.openai.com/v1")
        _models = State(initialValue: configuration?.availableModels ?? [])
        _selectedModel = State(initialValue: configuration?.selectedModel ?? "")
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .onSubmit { Task { await refreshModels() } }
                TextField("Base URL", text: $baseURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .onSubmit { Task { await refreshModels() } }
            } header: {
                Text("Provider")
            } footer: {
                Text("Use the API root URL, for example https://api.openai.com/v1. Only HTTPS endpoints are accepted.")
            }

            Section("Model") {
                if models.isEmpty {
                    Text("Refresh models to continue.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Selected Model", selection: $selectedModel) {
                        ForEach(models, id: \.self) { Text($0).tag($0) }
                    }
                }

                Button {
                    Task { await refreshModels() }
                } label: {
                    HStack {
                        Label("Refresh Models", systemImage: "arrow.clockwise")
                        Spacer()
                        if isRefreshing { ProgressView() }
                    }
                }
                .foregroundStyle(.green)
                .disabled(isRefreshing || baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(isNew ? "New Configuration" : "Edit Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || baseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .task {
            if !isNew { await refreshModels(showError: false) }
        }
    }

    private func refreshModels(showError: Bool = true) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        if showError { errorMessage = nil }
        defer { isRefreshing = false }
        do {
            let refreshedModels = try await viewModel.fetchModels(baseURL: baseURL, apiKey: apiKey)
            guard !refreshedModels.isEmpty else { throw AIChatError.noModel }
            models = refreshedModels
            if !models.contains(selectedModel) { selectedModel = models[0] }
        } catch {
            if showError { errorMessage = error.localizedDescription }
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        if models.isEmpty {
            await refreshModels()
        }
        guard !models.isEmpty, !selectedModel.isEmpty else {
            errorMessage = errorMessage ?? AIChatError.noModel.localizedDescription
            return
        }

        do {
            let configuration = AIProviderConfiguration(
                id: configurationID,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
                availableModels: models,
                selectedModel: selectedModel
            )
            try viewModel.saveConfiguration(configuration, apiKey: apiKey)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AIPresetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String) -> Void
    @State private var preset: String

    init(preset: String, onSave: @escaping (String) -> Void) {
        self.onSave = onSave
        _preset = State(initialValue: preset)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("This instruction is sent before every message in this configuration.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $preset)
                    .padding(8)
                    .frame(minHeight: 220)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            }
            .padding()
            .navigationTitle("Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(preset)
                        dismiss()
                    }
                }
            }
        }
    }
}
