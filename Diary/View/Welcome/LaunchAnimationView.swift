import SwiftUI

struct LaunchAnimationView: View {
    @State private var isActive = false

    var body: some View {
        VStack {
            if isActive {
                WelcomeSplineView()
                // 这里可以切换到主视图
            //    ContentView()
           // } else {
                // 这里是启动动画的内容
                Text("欢迎")
                    .font(.largeTitle)
                    .opacity(isActive ? 0 : 1)
                    .animation(.easeIn(duration: 1.5))
            }
        }
        .onAppear {
            // 延迟切换到主视图
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.isActive = true
                }
            }
        }
    }
} 
