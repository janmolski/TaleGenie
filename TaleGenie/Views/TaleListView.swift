import SwiftUI

struct TaleListView: View {
    @EnvironmentObject var taleStore: TaleStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(taleStore.tales) { tale in
                VStack(alignment: .leading, spacing: 8) {
                    Text(tale.prompt)
                        .font(.headline)
                    
                    Text(tale.content)
                        .font(.body)
                        .lineLimit(3)
                    
                    Text(tale.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Saved Tales")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 