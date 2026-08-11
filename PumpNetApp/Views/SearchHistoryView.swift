import SwiftUI

struct SearchHistoryView: View {
    let title: String
    let systemImage: String
    let history: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    ContentUnavailableView("No History", systemImage: systemImage, description: Text("Successful searches will appear here."))
                } else {
                    List(history, id: \.self) { item in
                        Button {
                            onSelect(item)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath").foregroundStyle(.secondary)
                                Text(item).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !history.isEmpty { Button("Clear", role: .destructive, action: onClear) }
                }
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
