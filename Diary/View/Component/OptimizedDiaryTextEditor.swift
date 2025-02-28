import SwiftUI

struct OptimizedDiaryTextEditor: View {
    @Binding var bodyText: String
    @FocusState private var isFocused: Bool
    @StateObject private var keyboardManager = KeyboardManager()
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            TextEditor(text: $bodyText)
                .focused($isFocused)
                .padding()
                .task {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    isFocused = true
                }
                .navigationBarItems(
                    trailing: Button("完成") {
                        isFocused = false
                        onDismiss()
                    }
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("完成") {
                            isFocused = false
                            onDismiss()
                        }
                    }
                }
                .padding(.bottom, keyboardManager.keyboardHeight)
        }
    }
} 