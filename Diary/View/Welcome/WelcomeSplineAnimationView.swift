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
                    // WelcomeSplineView() // 背景画面
            
                Text("深呼吸\n让我们开始今天的\n编织日记\n")
                    .font(.largeTitle)
                    .bold() // 添加粗体效果
                    .foregroundColor(.gray) // 添加文本颜色
                    .opacity(isActive ? 0 : 1)
                    .animation(.easeIn(duration: 1.5), value: isActive)
                                  .onTapGesture {
                                      isActive.toggle()
                                  }

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
