//
//  ChatAISetting.swift
//  Diary
//
//  Created by kioooko on 2024/12/18.
//
import SwiftUI
import Foundation
import Neumorphic
import Combine

struct ChatAIView: View {
    @ObservedObject var apiKeyManager: APIKeyManager
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = ["ChatGPT: 你好！我是正念引导助手，准备开始今天的练习吗？"]
    @State private var navigateToDiaryAppSceneDelegate = false

    func sendToChatGPT(prompt: String) {
        let apiKey = apiKeyManager.apiKey
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
           .padding(.bottom, 80) // 添加底部边距80
.padding(.horizontal) // 保持水平内边距
        }
        .background(Color.Neumorphic.main)
    }
}

#if DEBUG
struct ChatAIView_Previews: PreviewProvider {
    static var content: some View {
        NavigationStack {
            ChatAIView(apiKeyManager: APIKeyManager())
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