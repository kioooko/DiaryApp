import SplineRuntime
import SwiftUI
import Foundation
import Neumorphic

struct WelcomeView: View {
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = ["你的正念助手: 你好！我是正念引导助手，准备开始今天的练习吗？"]
    @State private var navigateToNextPage = false
    @State private var navigateToHomeView = false
    @State private var navigateToDiaryAppSceneDelegate = false
    
    @EnvironmentObject private var notificationSetting: NotificationSetting
    @EnvironmentObject private var weatherData: WeatherData
    
    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue)
    private var hasBeenLaunchedBefore: Bool = false
    @State private var selectedPage = 1
    @State private var selectedDate: Date = Date()

    private let maxPageCount = 5

    // 修改后的 sendToChatGPT 方法，包含实际 API 请求
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
                    localImageView
                        .tag(4)
                    DividerWithShadow
                        .tag(5)
                }
                .contentShape(Rectangle()).gesture(DragGesture()) // 禁止滑动切换页面
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            nextButton
                .padding(.bottom)
        }
    }
}

private extension WelcomeView {

    var nextButton: some View {
        Button(action: {
            if selectedPage == 2 {
                // weatherData.requestLocationAuth()
            }

            if selectedPage == 3 {
                Task {
                    // try await notificationSetting.setNotification(date: selectedDate)
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
            Text(selectedPage == maxPageCount ? "完成" : "下一步")
        }
        .buttonStyle(ActionButtonStyle(size: .medium))
    }

    var appIntroduction: some View {
        VStack(spacing: 40) {
            title("你好哇👋！", description: "编织日记是一款用文字记录生活的简单应用")
            featureRow(icon: "book", color: .orange, description: "「编织日记」是一款直观且简洁的日记应用，帮助你用文字和图片编织自己的生活。")
            featureRow(icon: "checkmark", color: .green, description: "帮助追踪日常习惯的CheckList。通过可视化目标，查看每天的微小进步。")
            featureRow(icon: "icloud", color: .blue, description: "与 iCloud 完全同步。您可以轻松访问所有设备上的内容。重要记录将始终安全存储。")
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
            title("请允许访问您的位置信息", description: "允许位置访问，开始更加丰富的日记体验吧！")
            HStack(spacing: 24) {
                IconWithRoundedBackground(systemName: "mappin", backgroundColor: .green)
                Text("在「编织日记」中，我们会自动添加天气信息。\n位置信息仅用于获取天气信息。您随时可以更改设置。")
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
            title("设置提醒事项", description: "让写日记成为一种习惯。我们不会发送任何烦人的通知。")
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
        VStack {      
            // 聊天记录
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(chatHistory, id: \.self) { message in
                        HStack {
                            if message.hasPrefix("You:") {
                                Spacer() // 将用户消息推到右边
                                Text(message)
                                    .padding()
                                    .background(Color.purple.opacity(0.2))
                                    .cornerRadius(6)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else {
                                Text(message)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Spacer() // 将助手消息推到左边
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
            }

            // 输入框发送按钮
            HStack {
                TextField("分享今天的心情吧", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: userInput) { newValue in
                        // 在这里监听输入框变化（可选）
                        print("当前输入: \(newValue)")
                    }

                Button(action: {
                    sendToChatGPT(prompt: userInput)
                    userInput = ""  // 清空输入框
                }) {
                    Text("发送")
                     
                }
                 .buttonStyle(ActionButtonStyle(size: .small))
                .padding()
            }
        }
        .padding()
    }

     var DividerWithShadow: some View {
          let cornerRadius : CGFloat = 15
        let mainColor = Color.Neumorphic.main
        let secondaryColor = Color.Neumorphic.secondary
        
        return ZStack {
            mainColor.edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 30) {
                Text("Neumorphic Soft UI").font(.headline).foregroundColor(secondaryColor)
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
                        
                    //Circle Button
                    Button(action: {}) {
                        Image(systemName: "heart.fill")
                    }.softButtonStyle(Circle(), mainColor: Color.red, textColor: Color.white, darkShadowColor: Color("redButtonDarkShadow"), lightShadowColor:Color("redButtonLightShadow"))
                    
                }
                  
            }
        }
     }
}

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
