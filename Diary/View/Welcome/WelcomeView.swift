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
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = ["你的正念助手: 你好！我是正念引导助手，准备开始今天的练习吗？"]
    @State private var selectedPage = 1
    @State private var selectedDate: Date = Date()
    @State private var navigateToNextPage = false
    @State private var navigateToHomeView = false
    @State private var navigateToDiaryAppSceneDelegate = false

    

    
    // Constants
    private let maxPageCount = 5
    
    // MARK: - Chat GPT Integration
    func sendToChatGPT(prompt: String) {
        let filePath = "/Users/kokio/DiaryApp/Chatapi.txt"
        var apiKey: String = ""

        do {
            apiKey = try String(contentsOfFile: filePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("无法读取API密钥: \(error)")
            return
        }

        let url = URL(string: "https://api.x.ai/v1/chat/completions")!

        let parameters: [String: Any] = [
            "model": "grok-beta",
            "messages": [["role": "user", "content": prompt]],
            "stream": false,
            "temperature": 0
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("请求编码错误: \(error)")
            return
        }
        
        // 立即将用户输入添加到聊天记录中
        DispatchQueue.main.async {
            chatHistory.append("You: \(prompt)")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API 请求错误: \(error)")
                return
            }
            
            guard let data = data else {
                print("没有收到数据")
                return
            }
            
            // 打印原始响应数据
            if let responseString = String(data: data, encoding: .utf8) {
                print("服务器响应: \(responseString)")
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                    chatHistory.append("你的正念助手: \(content.trimmingCharacters(in: .whitespacesAndNewlines))")
                    }
                }
            } catch {
                print("解析响应错误: \(error)")
            }
        }.resume()
    }
    
// MARK: - Body
var body: some View {
    NavigationView {
        VStack {
            TabView(selection: $selectedPage) {
                Group {
                    appIntroduction.tag(1)
                    requestLocation.tag(2)
                    setReminder.tag(3)  
                    localImageView.tag(4)
                    DividerWithShadow.tag(5)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture())
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
          //   print("WelcomeView appeared with weatherData: \(weatherData)")
        }
          .frame(maxWidth: .infinity, alignment: .center) // 确保 HStack 水平居中
        .background(Color.Neumorphic.main.edgesIgnoringSafeArea(.all))
    
      
    }
}

// MARK: Navigation Button
var nextButton: some View {
  //  Button(action: {
            Button(actionWithHapticFB: {
        if selectedPage == 2 {
          //   weatherData.requestLocationAuth()
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
    
    // MARK: Chat View
    var localImageView: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(chatHistory, id: \.self) { message in
                        HStack {
                            if message.hasPrefix("You:") {
                                Spacer()
                                Text(message)
                                    .padding()
                                    .background(Color.Neumorphic.main)
                                    .softOuterShadow()
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else {
                                Text(message)
                                    .padding()
                                    .background(Color.Neumorphic.main)
                                    .softInnerShadow(RoundedRectangle(cornerRadius: 12))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
            }

            HStack {
                TextField("分享今天的心情吧", text: $userInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.Neumorphic.main)
                            .softInnerShadow(RoundedRectangle(cornerRadius: 12))
                    )
                    .accentColor(.primary)
                
                Button(action: {
                    sendToChatGPT(prompt: userInput)
                    userInput = ""
                }) {
                    Text("发送")
                        .fontWeight(.bold)
                }
                .softButtonStyle(RoundedRectangle(cornerRadius: 12))
                .frame(width: 80, height: 44)
            }
            .padding()
        }
        .background(Color.Neumorphic.main)
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
