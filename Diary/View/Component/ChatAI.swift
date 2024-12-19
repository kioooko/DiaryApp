import SwiftUI
import Foundation
import Neumorphic
import Combine

struct ChatAI: View {
    @ObservedObject var apiKeyManager: APIKeyManager
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = []
    @State private var navigateToDiaryAppSceneDelegate = false

    private let chatHistoryKey = "chatHistory"

    init(apiKeyManager: APIKeyManager) {
        self.apiKeyManager = apiKeyManager
        loadChatHistory()
    }

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
            saveChatHistory()
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
                        saveChatHistory()
                    }
                }
            } catch {
                print("解析响应错误: \(error)")
            }
        }.resume()
    }

    private func saveChatHistory() {
        do {
            let data = try JSONEncoder().encode(chatHistory)
            UserDefaults.standard.set(data, forKey: chatHistoryKey)
        } catch {
            print("无法保存聊天记录: \(error)")
        }
    }

    private func loadChatHistory() {
        if let data = UserDefaults.standard.data(forKey: chatHistoryKey) {
            do {
                chatHistory = try JSONDecoder().decode([String].self, from: data)
            } catch {
                print("无法加载聊天记录: \(error)")
            }
        } else {
            chatHistory = ["ChatGPT: 你好！我是正念引导助手，准备开始今天的练习吗？"]
        }
    }

    func createMessageView(message: String, isUser: Bool) -> some View {
        let text = Text(message)
            .padding()

        let background = RoundedRectangle(cornerRadius: 12)
            .fill(Color.Neumorphic.main)
            .softInnerShadow(RoundedRectangle(cornerRadius: 12))

        let textWithBackground = text
            .background(background)

        return textWithBackground
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(chatHistory.indices, id: \.self) { index in
                            let message = chatHistory[index]
                            HStack {
                                if message.hasPrefix("You:") {
                                    Spacer()
                                    createMessageView(message: message, isUser: true)
                                } else {
                                    createMessageView(message: message, isUser: false)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 2)
                            .id(index) // 为每个消息设置唯一的 ID
                        }
                    }
                    .padding()
                }
                .onChange(of: chatHistory) { _ in
                    // 当聊天记录更新时，滚动到最新消息
                    if let lastIndex = chatHistory.indices.last {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastIndex, anchor: .bottom)
                        }
                    }
                }
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
            .padding(.bottom, 20)
            .padding(.horizontal)
        }
        .background(Color.Neumorphic.main)
    }
}

#if DEBUG
struct ChatAI_Previews: PreviewProvider {
    static var content: some View {
        NavigationStack {
            ChatAI(apiKeyManager: APIKeyManager())
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
