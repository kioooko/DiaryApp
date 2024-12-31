//
//  WelcomeView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/07/05.
//

import SplineRuntime
import SwiftUI
import Foundation

/*
 1. アプリ全体の機能紹介
 2. 位置情報取得依頼
 3. リマインダー設定
 */
struct WelcomeView: View {
  @State private var userInput: String = ""
    @State private var chatHistory: [String] = ["ChatGPT: 你好！我是正念引导助手，准备开始今天的练习吗？"]
    

    @State private var navigateToNextPage = false // 确保变量声明正确
    @State private var navigateToHomeView = false // 确保变量声明正确
     @State private var navigateToDiaryAppSceneDelegate = false // 确保变量声明正确
    
    @EnvironmentObject private var notificationSetting: NotificationSetting
    @EnvironmentObject private var weatherData: WeatherData

    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue)
    private var hasBeenLaunchedBefore: Bool = false
    @State private var selectedPage = 1
    @State private var selectedDate: Date = Date()

    private let maxPageCount = 4
 // 模拟与ChatGPT的对话
    func sendToChatGPT(prompt: String) {
        // 模拟的API请求，替换为实际API调用
        let response = ？
        chatHistory.append("You: \(prompt)")
        chatHistory.append(response)
    }
    
    var body: some View {
        VStack {
            TabView(selection: $selectedPage) {
                Group {
                    appIntroduction
                        .tag(1)
                    requestLocation
                        .tag(2)
                    setReminder
                        .tag(3)  
                    localImageView // 使用自定义视图展示本地图片
                        .tag(4)
                }
                .contentShape(Rectangle()).gesture(DragGesture()) // スワイプでのページ遷移をしない
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            nextButton
                .padding(.bottom)
              
        }           
       //  .fullScreenCover(isPresented: $navigateToHomeView) {
       //    HomeView() }
    }
}

private extension WelcomeView {

    var nextButton: some View {

        // TODO: refactoring
        Button(actionWithHapticFB: {
            if selectedPage == 2 {
               // weatherData.requestLocationAuth()
            }

            if selectedPage == 3 {
                Task {
                    do {
                     //   try await notificationSetting.setNotification(date: selectedDate)
               //     try await notificationSetting.setNotification(date: selectedDate)
//} catch {
//    print("Failed to set notification: \(error)")                        
                    }
                }
            }
           
          

   if selectedPage >= maxPageCount {
                hasBeenLaunchedBefore = true
                navigateToNextPage = true // 设置为 true 以触发导航
                navigateToDiaryAppSceneDelegate = true // 跳转到 DiaryAppSceneDelegate



            } else {
                withAnimation {
                    selectedPage += 1
                }
            }
        }) {
              Text(selectedPage == maxPageCount ? "完成" : "下一步")
       
        }
        .buttonStyle(ActionButtonStyle(size: .medium))
      //  .fullScreenCover(isPresented: $navigateToDiaryAppSceneDelegate) {
      //      DiaryAppSceneDelegate() // 跳转的目标页面
      //  }
    }

    var appIntroduction: some View {
        VStack(spacing: 40) {
            title("你好哇👋！", description: "编织生活是一款用文字记录生活的简单应用")

            featureRow(
                icon: "book",
                color: .orange,
                description: "「编织生活」是一款直观而简洁的生活助手应用，帮助你用记录和规划编织属于自己的美好时光。"
            )
            featureRow(
                icon: "checkmark",
                color: .green,
                description: "帮助追踪日常习惯的CheckList。通过可视化目标，查看每天的微小进步。"
            )
            featureRow(
                icon: "icloud",
                color: .blue,
                description: "与 iCloud 完全同步。您可以轻松访问所有设备上的内容。重要的记录将始终安全存储。")

        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

    func featureRow(icon: String, color: Color, description: String) -> some View {
        HStack(spacing: 24) {
            IconWithRoundedBackground(systemName: icon, backgroundColor: color)

            Text(description)
                .foregroundColor(.adaptiveBlack.opacity(0.8))
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

    var requestLocation: some View {
        VStack(spacing: 40) {
            title(
                "请允许访问您的位置信息",
                description: "允许位置访问，开始更加丰富的日记体验吧！"
            )

            HStack(spacing: 24) {
                IconWithRoundedBackground(systemName: "mappin", backgroundColor: .green)

                Text("在「编织生活」中，我们会自动添加天气信息。\n位置信息仅用于获取天气信息。您随时可以更改设置。")
                    .foregroundColor(.adaptiveBlack.opacity(0.8))
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

    var setReminder: some View {
        VStack(spacing: 40) {
            title(
                "设置提醒事项",
                description: "让写日记成为一种习惯。我们不会发送任何烦人的通知。"
            )

            HStack {
                IconWithRoundedBackground(systemName: "alarm", backgroundColor: .red)
                Text("我们不会发送任何垃圾信息")
            }

            hourAndMinutePicker
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

    var hourAndMinutePicker: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
            .datePickerStyle(WheelDatePickerStyle())
    }
       var localImageView: some View {
        // 使用UIImage加载本地图片
     //   if let uiImage = UIImage(contentsOfFile: "/Users/kokio/DiaryApp/Diary/View/Welcome/Nextimg.png") {
      //      return AnyView(Image(uiImage: uiImage)
     //           .resizable()
     //           .scaledToFit())
     //   } else {
     //       return AnyView(Text("无法加载图片"))
     //   }

   VStack {      
           // 聊天记录
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(chatHistory, id: \.self) { message in
                        Text(message)
                            .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            
            // 输入框和发送按钮
            HStack {
                TextField("输入你的问题", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    sendToChatGPT(prompt: userInput)
                    userInput = ""  // 清空输入框
                }) {
                    Text("发送")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
    }
}




//    }
  
//}

#if DEBUG

struct WelcomeView_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
       //     WelcomeView()
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
