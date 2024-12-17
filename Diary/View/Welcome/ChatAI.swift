//
//  ChatAI.swift
//  Chat
//
//  Created by KIOOOKO on 2024/12/16.
//

// MARK: - Imports
import SwiftUI
import Foundation
import Neumorphic
import Combine


struct ChatAIView: View {
  @State private var userInput: String = ""
    @State private var chatHistory: [String] = ["ChatGPT: 你好！我是正念引导助手，准备开始今天的练习吗？"]
    @State private var navigateToDiaryAppSceneDelegate = false // 确保变量声明正确
 
 // 模拟与ChatGPT的对话
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
  // MARK: Chat View   
    var body: some View {
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
            title("你好哇👋！", description: "编织日记是一款用文字记录生活的简单应用")

            featureRow(
                icon: "book",
                color: .orange,
                description: "「编织日记」是一款直观且简洁的日记应用，帮助你用文字和图片编织自己的生活。"
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

struct ChatAIView_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            ChatAIView()
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
