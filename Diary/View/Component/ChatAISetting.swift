import SwiftUI
import Foundation
import Neumorphic
import Combine

struct ChatAIView: View {
    @State private var userInput: String = ""
    @State private var apiKey: String = ""
    @State private var chatHistory: [String] = []
    @State private var useCustomAPIKey: Bool = false // 控制是否使用自定义 API 密钥

    func sendToChatGPT(prompt: String) {
        let apiKeyToUse = useCustomAPIKey ? apiKey : "默认的API密钥" // 使用自定义或默认 API 密钥

        guard !apiKeyToUse.isEmpty else {
            print("API 密钥不能为空")
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
        request.setValue("Bearer \(apiKeyToUse)", forHTTPHeaderField: "Authorization")
        
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
            Toggle("使用自定义 API 密钥", isOn: $useCustomAPIKey)
                .padding()

            if useCustomAPIKey {
                TextField("输入 API 密钥", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
            }

            TextField("输入你的问题", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                sendToChatGPT(prompt: userInput)
                userInput = ""
            }) {
                Text("发送")
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(chatHistory, id: \.self) { message in
                        Text(message)
                            .padding(.vertical, 4)
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

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