import SwiftUI

struct OptimizedInputTitle: View {
    @Binding var title: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("标题", text: $title)
            .focused($isFocused)
            .font(.title2.bold())
            .textFieldStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isFocused = false
                    }
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 100_000_000)
                isFocused = true
            }
    }
} 