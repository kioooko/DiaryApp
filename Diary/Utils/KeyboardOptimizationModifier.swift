import SwiftUI

struct KeyboardOptimizationModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.keyboardHeight)
            .animation(.easeOut(duration: 0.16), value: keyboardManager.keyboardHeight)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                             to: nil,
                                             from: nil,
                                             for: nil)
            }
    }
}

extension View {
    func optimizedKeyboardHandling() -> some View {
        self.modifier(KeyboardOptimizationModifier())
    }

    func hideKeyboardWhenTappedAround() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                          to: nil,
                                          from: nil,
                                          for: nil)
        }
    }
} 