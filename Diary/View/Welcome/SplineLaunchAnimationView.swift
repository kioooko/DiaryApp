import SwiftUI
import SplineRuntime

struct SplineLaunchAnimationView: View {
    @State private var isActive = false

    var body: some View {
        VStack {
            if isActive {
         //    ContentView() // 使用 ContentView 作为主视图
         //   } else {
                Text("Spline 动画")
                    .font(.largeTitle)
                    .opacity(isActive ? 0 : 1)
                    .animation(.easeIn(duration: 1.5))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.isActive = true
                    print("SplineLaunchAnimationView appeared")
                }
            }
        }
    }
} 
