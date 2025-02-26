//
//  WelcomeView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/01.
// Change by kioooko 2024/12/22

// MARK: - Imports
import SplineRuntime
import SwiftUI
import Foundation
import Neumorphic
import Combine

// MARK: - WelcomeView
struct WelcomeView: View {
    // MARK: - Properties
    // State Properties
    @State private var selectedPage = 1
    @State private var selectedDate: Date = Date()
    @State private var navigateToNextPage = false
    @State private var navigateToHomeView = false
    @State private var navigateToDiaryAppSceneDelegate = false
    @ObservedObject var apiKeyManager: APIKeyManager
    @State private var showChatAISetting = false
    @State private var ReminderSettingView = false

    
    // Environment Properties
    @EnvironmentObject private var notificationSetting: NotificationSetting
    @EnvironmentObject private var weatherData: WeatherData
    @EnvironmentObject private var bannerState: BannerState
    
    // App Storage
    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue)
    private var hasBeenLaunchedBefore: Bool = false
    
    // Constants
    private let maxPageCount = 4
// MARK: - Body
var body: some View {
    NavigationView {
        VStack {
            TabView(selection: $selectedPage) {
                Group {
                    appIntroduction.tag(1)
                    requestLocation.tag(2)
//ReminderSettingView().tag(3)
                    setReminder.tag(3)  
                   // DividerWithShadow.tag(4)
                    ChatAISetting(apiKeyManager: apiKeyManager).tag(4)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture())
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // HStack 包含跳过和下一步按钮
            HStack(spacing: 50) { // 设置按钮之间的间距为20
            HStack(alignment: .center) { // 设置按钮之间的间距为20
                // 跳过按钮
                Button(action: {
                    hasBeenLaunchedBefore = true
                    navigateToHomeView = true
                }) {
                    Text("跳过")
                        .fontWeight(.bold)
                        //.foregroundColor(.gray)
                }
                .softButtonStyle(RoundedRectangle(cornerRadius: 12))
                .frame(width: 80, height: 44) // 设置跳过按钮的宽度为80，高度为44
                .padding(.leading, 20) // 向左移动2个像素以补偿阴影
                 .background(
                    NavigationLink(destination: HomeView(apiKeyManager: apiKeyManager), isActive: $navigateToHomeView) {
                        EmptyView()
                    }
                    .hidden()
                )
                // 原有的下一步按钮
                nextButton
            }
            }
            .padding(.bottom, 80) // 为按钮组添加底部内边距50像素
        }
        .background(Color.Neumorphic.main.edgesIgnoringSafeArea(.all))
        .onAppear {
             print("WelcomeView appeared with weatherData: \(weatherData)")
        }
    }
}

// MARK: Navigation Button
var nextButton: some View {
    Button(action: {
            // 打印当前页面索引
                    print("Current selectedPage: \(selectedPage)")
                    
        if selectedPage == 2 {
             weatherData.requestLocationAuth()
        }

        if selectedPage == 3 {
            Task {
                do {
                        try await notificationSetting.setNotification(date: selectedDate)
                    }
            }
         if selectedPage == 4 {
             print("Navigating to HomeView: \(navigateToHomeView)")
                NavigationLink(
                    destination: HomeView(apiKeyManager: apiKeyManager),
                    isActive: $navigateToHomeView
                ) {
                    EmptyView()
                }
                .hidden()
            }
        }

        if selectedPage >= maxPageCount {
            hasBeenLaunchedBefore = true
            navigateToNextPage = true
            navigateToDiaryAppSceneDelegate = true
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
         title("你好哇👋！", description: "编织生活是一款专注于探索普通人如何满足自身生活需求的应用，致力于填补学校教育中缺失的部分。它主要聚焦于心灵成长与基本生活支援，帮助每个人在日常生活中找到力量与方向。")
featureRow(icon: "book", color: .orange, description: "直观简洁的日记工具，用文字和图片记录生活点滴，编织属于你的故事。")
featureRow(icon: "message", color: purple, description: "与ChatAI对话，理清思路、释放压力，记录一天的心情感悟。支持自定义ChatAI的API接口，打造专属智能体验。")
featureRow(icon: "checkmark", color: .cyan, description: "轻松追踪日常习惯的CheckList，通过可视化目标感受每天的进步与成长。")
featureRow(icon: "dollarsign.circle", color: .green, description: "养成记账的好习惯，为自己的财务负责，设置储蓄目标，提高自己的生活质量。")
featureRow(icon: "person.2", color: .blue, description: "基于邓巴数的社交圈层概念，高效管理人际关系，更好地维持和改善社交互动。")
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

   // WelcomeView 视图中的辅助方法，用于创建带图标和描述的行
  func featureRow(icon: String, color: Color, description: String) -> some View {
    HStack(spacing: 24) {
        // 图标，带有背景和阴影
        Image(systemName: icon)
            .foregroundColor(color) // 设置图标颜色
            .padding() // 添加内边距
            .background(Color.Neumorphic.main) // 设置背景颜色
            .clipShape(Circle()) // 将背景裁剪为圆形
            .softOuterShadow() // 添加柔和的外部阴影
        // 描述文本
        Text(description)
            .foregroundColor(.primary.opacity(0.8)) // 设置文本颜色和不透明度
            .font(.system(size: 18)) // 设置字体大小
            .frame(maxWidth: .infinity, alignment: .leading) // 设置最大宽度和对齐方式
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
                featureRow(icon: "mappin", color: .orange, description: "在「编织生活」中，我们会自动添加天气信息。\n位置信息仅用于获取天气信息。您随时可以更改设置。")
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
                title("设置提醒事项", description: "让书写成为一种习惯。我们不会发送任何烦人的垃圾通知。")
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
    // MARK: Shadow Demo
    var DividerWithShadow: some View {
        let cornerRadius : CGFloat = 15
        let mainColor = Color.Neumorphic.main
        let secondaryColor = Color.Neumorphic.secondary
        
        return ZStack {
            mainColor.edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 30) {
               
                //Create simple shapes with soft inner shadow
                HStack(spacing: 40){
                    RoundedRectangle(cornerRadius: cornerRadius).fill(mainColor).frame(width: 150, height: 150)
                        .softInnerShadow(RoundedRectangle(cornerRadius: cornerRadius))
                    
                    Circle().fill(mainColor).frame(width: 150, height: 150)
                        .softInnerShadow(Circle())
                }
                //You can customize shadow by changing its color, spread, and shadow radius.
                HStack(spacing: 40) {
                    ZStack {
                        Circle().fill(mainColor)
                            .softInnerShadow(Circle(), spread: 0.6)
                        
                        Circle().fill(mainColor).frame(width: 80, height: 80)
                            .softOuterShadow(offset: 8, radius: 8)
                    }.frame(width: 150, height: 150)
                    
                    ZStack {
                        Circle().fill(mainColor)
                            .softOuterShadow()
                        
                        Circle().fill(mainColor).frame(width: 80, height: 80)
                            .softInnerShadow(Circle(), radius: 5)
                    }.frame(width: 150, height: 150)
                }
                //Rectanlges with soft outer shadow
                HStack(spacing: 30) {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(mainColor).frame(width: 90, height: 90)
                        .softOuterShadow()
                    
                    RoundedRectangle(cornerRadius: cornerRadius).fill(mainColor).frame(width: 90, height: 90)
                        .softInnerShadow(RoundedRectangle(cornerRadius: cornerRadius))
                    
                    Rectangle().fill(mainColor).frame(width: 90, height: 90)
                        .softOuterShadow()
                    
                }
                
                //You can simply create soft button with softButtonStyle method.
                Button(action: {}) {
                    Text("Soft Button").fontWeight(.bold)
                }.softButtonStyle(RoundedRectangle(cornerRadius: cornerRadius))
                
                HStack(spacing: 20) {
                    //Circle Button
                    Button(action: {}) {
                        Image(systemName: "heart.fill")
                    }.softButtonStyle(Circle())
                    
                    
                    //Ellipse Button
                    Button(action: {}) {
                        Text("Thanks").fontWeight(.bold).frame(width: 150, height: 20)
                    }.softButtonStyle(Ellipse())
                        
}
                  
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var content: some View {
        NavigationStack {
            WelcomeView(apiKeyManager: APIKeyManager())
            .environmentObject(BannerState())
            .environmentObject(NotificationSetting())
            .environmentObject(WeatherData())
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
