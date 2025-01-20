import SwiftUI
import Foundation
import Neumorphic
import Combine
import GoogleGenerativeAI

struct ChatAI: View {
    @ObservedObject var apiKeyManager: APIKeyManager
    @State private var userInput: String = ""
    @State private var chatHistory: [String] = []
    @State private var navigateToDiaryAppSceneDelegate = false
    @State private var chat: Chat? // 用于存储 Gemini Chat 对象

    let chatHistoryKey = "chatHistory"

    init(apiKeyManager: APIKeyManager) {
        self.apiKeyManager = apiKeyManager
        loadChatHistory()
        setupChat()
    }

    func setupChat() {
        let config = GenerationConfig(maxOutputTokens: 100)
        let model = GenerativeModel(
            name: "models/gemini-2.0-flash-exp",
            apiKey: APIKey.default, // 使用 APIKey.default
            generationConfig: config
        )

        let history = [
            ModelContent(role: "user", parts: "你好！我是你的正念引导小助手。"),
            ModelContent(role: "model", parts: "你好！很高兴为你服务。")
        ]

        chat = model.startChat(history: history)
    }

    func sendToChatGPT(prompt: String) {
        DispatchQueue.main.async {
            chatHistory.append("You: \(prompt)")
            saveChatHistory()
        }

        Task {
            do {
                guard let chat = chat else {
                    print("Chat object is not initialized.")
                    return
                }
                let response = try await chat.sendMessage(prompt)
                if let text = response.text {
                    DispatchQueue.main.async {
                        chatHistory.append("你的正念助手: \(text.trimmingCharacters(in: .whitespacesAndNewlines))")
                        saveChatHistory()
                    }
                }
            } catch {
                print("API 请求错误: \(error)")
            }
        }
    }

    func saveChatHistory() {
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
            chatHistory = ["你的正念助手: 你好！我是正念引导助手，准备开始今天的练习吗？"]
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
                        createMessageView(
                            message:"你的正念助手: 你好！我是你的正念引导小助手，准备开始今天的练习吗？",
                            isUser: false)
                            Spacer()
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
