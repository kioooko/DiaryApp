// MARK: - Imports
import SplineRuntime
import SwiftUI
import Foundation
import Neumorphic
import Combine

// MARK: - WelcomeView
struct WelcomeView: View {
    // MARK: - Properties

    // Environment Properties
    @EnvironmentObject private var notificationSetting: NotificationSetting
    @EnvironmentObject private var weatherData: WeatherData

    // App Storage
    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue)
    private var hasBeenLaunchedBefore: Bool = false
    // State Properties
    @State private var selectedPage = 1
    @State private var selectedDate: Date = Date()
    @State private var navigateToHomeView = false
 
    // Constants
    private let maxPageCount = 3
// MARK: - Body
var body: some View {
        VStack {
            TabView(selection: $selectedPage) {
                Group {
                    appIntroduction.tag(1)
                    requestLocation.tag(2)
                    setReminder.tag(3)  
                  //  localImageView.tag(4)
                }
                .contentShape(Rectangle()).gesture(DragGesture())
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // HStack 包含跳过和下一步按钮
            HStack(spacing: 20) { // 设置按钮之间的间距为20
                // 跳过按钮
                Button(action: {
                    hasBeenLaunchedBefore = true
                    navigateToHomeView = true
                }) {
                    Text("跳过")
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .softButtonStyle(RoundedRectangle(cornerRadius: 12))
                .frame(width: 80, height: 44) // 设置跳过按钮的宽度为80，高度为44
                .background(
                    NavigationLink(destination: HomeView(), isActive: $navigateToHomeView) {
                        EmptyView()
                    }
                    .hidden()
                
                )
                
                // 原有的下一步按钮
                nextButton
            }
            .padding(.bottom, 80) // 为按钮组添加底部内边距50像素
           
        }
            .onAppear {
             print("WelcomeView appeared with weatherData: \(weatherData)")
        }
          .frame(maxWidth: .infinity, alignment: .center) // 确保 HStack 水平居中
        .background(Color.Neumorphic.main.edgesIgnoringSafeArea(.all))
    
      
    }
}
private extension WelcomeView {
// MARK: Navigation Button
var nextButton: some View {
            Button(actionWithHapticFB: {
        if selectedPage == 2 {
             weatherData.requestLocationAuth()
        }

        if selectedPage == 3 {
            Task {
                do {
                        try await notificationSetting.setNotification(date: selectedDate)
                    }
            }
        }

        if selectedPage >= maxPageCount {
            hasBeenLaunchedBefore = true
           // navigateToNextPage = true
          //  navigateToDiaryAppSceneDelegate = true
        } else {
            withAnimation {
                selectedPage += 1
            }
        }
    }) {
        Text(selectedPage == maxPageCount ? "完成" : "保存")
            .fontWeight(.bold)
    }
    .softButtonStyle(RoundedRectangle(cornerRadius: 12))
    .frame(width: 120, height: 44) // 设置下一步按钮的宽度为120，高度为44
}
    // MARK: Introduction Page
    var appIntroduction: some View {
        VStack(spacing: 40) {
            title("你好哇👋！", description: "编织日记是一款用文字记录生活的简单应用")
            featureRow(icon: "book", color: .orange, description: "「编织日记」是一款直观且简洁的日记应用，帮助你用文字和图片编织自己的生活。")
            featureRow(icon: "checkmark", color: .green, description: "帮助追踪日常习惯的CheckList。通过可视化目标，查看每天的微小进步。")
            featureRow(icon: "icloud", color: .blue, description: "与iCloud全同步。您可以轻松访问所有设备上的内容。重要记录将始终安全存储。")
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }
    
    func featureRow(icon: String, color: Color, description: String) -> some View {
        HStack(spacing: 24) {
            Image(systemName: icon)
                .foregroundColor(color)
                .padding()
                .background(Color.Neumorphic.main)
                .clipShape(Circle())
                .softOuterShadow()
            Text(description)
                .foregroundColor(.primary.opacity(0.8))
                .font(.system(size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    func title(_ text: String, description: String) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .bold()
                .font(.system(size: 24))
            Text(description)
                .font(.system(size: 18))
        }
    }
    
    // MARK: Location Page
    var requestLocation: some View {
        VStack(spacing: 40) {
            title("请允许访问您的位置信息", description: "允许位置访问，开始更加丰富的日记体验吧！")
            HStack(spacing: 24) {
                featureRow(icon: "mappin", color: .orange, description: "在「编织日记」中，我们会自动添加天气信息。\n位置信息仅用于获取天气信息。您随时可以更改设置。")
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }
    
    // MARK: Reminder Page
    var setReminder: some View {
        VStack(spacing: 40) {
            Spacer()  // 添加顶部空间
            VStack(spacing: 40) {
                title("设置提醒事项", description: "让写日记成为一种习惯。我们不会发送任何烦人的垃圾通知。")
                    .multilineTextAlignment(.center)  // 文本居中
                
                HStack {
                    featureRow(icon: "alarm", color: .red, description: "设置你每日的编织时间吧")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            hourAndMinutePicker 
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()  // 添加底部空间
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // 使用最大宽度和高度
        .padding(.horizontal)
    }
    
    var hourAndMinutePicker: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
            .datePickerStyle(WheelDatePickerStyle())
  
    }
}

// MARK: - Preview
#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var content: some View {
        NavigationStack {
            WelcomeView()
        }
    }
    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light)
            content
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif
