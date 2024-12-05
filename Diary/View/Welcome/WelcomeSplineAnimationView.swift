import SwiftUI

struct WelcomeSplineAnimationView: View {
    @State private var isActive = false

    var body: some View {
        VStack {
            if isActive {
                // 这里可以切换到主视图
                WelcomeSplineView()
            } else {
                // 这里是启动动画的内容
                Text("欢迎使用")
                    .font(.largeTitle)
                    .opacity(isActive ? 0 : 1)
                    .animation(.easeIn(duration: 1.5))
            }
        }
        .onAppear {
            // 延迟切换到主视图
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
} 