//
//  ChatAISetting.swift
//  Diary
//
//  Created by kioooko on 2024/12/18.
//  Change by kioooko on 2024/12/20

import SwiftUI
import Neumorphic

struct ChatAISetting: View {
    @ObservedObject var apiKeyManager: APIKeyManager
    @State private var useCustomAPIKey: Bool = false // 控制是否使用自定义 API 密钥
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var userInputKey: String = ""

    var body: some View {
        VStack {
            attention // 显示 ChatAI 提示信息
                .padding(.horizontal) // 添加水平内边距
                .padding(.vertical) // 添加垂直内边距

            Toggle("使用自定义 API 密钥", isOn: $useCustomAPIKey)
                .toggleStyle(SwitchToggleStyle(tint:.greenLight))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.Neumorphic.main)
                        .softInnerShadow(RoundedRectangle(cornerRadius: 12))
                )
                .padding(.horizontal)

            if useCustomAPIKey {
                TextField("输入 API 密钥", text: $userInputKey)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.Neumorphic.main)
                            .softInnerShadow(RoundedRectangle(cornerRadius: 12))
                    )
                    .padding(.horizontal)

                if !userInputKey.isEmpty {
                    Button(action: {
                        validateAPIKey(userInputKey)
                    }) {
                        Text("确认")
                            .fontWeight(.bold)
                            .frame(width: 150, height: 24)
                    }
                    .softButtonStyle(RoundedRectangle(cornerRadius: 12)) // 使用 Neumorphic 风格
                    .padding(.top, 100)
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.Neumorphic.main.ignoresSafeArea()) // 使用 Neumorphic 风格的背景色
        .alert(isPresented: $showAlert) {
            Alert(title: Text("API 密钥验证"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("确定")))
        }
        .onAppear {
            userInputKey = apiKeyManager.apiKey
        }
    }

    @ViewBuilder
    var attention: some View { // 显示 ChatAI 提示信息
        Text("您可以灵活配置ChatAI的API接口，轻松切换为您自有的专属API服务\n（*目前仅支持X.AI的API接口）")
            .padding()
            .foregroundColor(.gray)
            .font(.system(size: 14))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func validateAPIKey(_ key: String) {
       // let url = URL(string: "https://api.x.ai/v1/chat/completions")!
        let url = URL(string:"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-pro:generateContent")!
        let parameters: [String: Any] = [
           // "model": "grok-beta",
            "model": "models/gemini-2.0-flash-exp",
            "contents": [["parts": [["text": "你好"]]]],
            "stream": false,
            "temperature": 0
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            alertMessage = "请求编码错误: \(error.localizedDescription)"
            showAlert = true
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                alertMessage = "API 请求错误: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let data = data else {
                alertMessage = "没有收到数据"
                showAlert = true
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   !choices.isEmpty {
                    alertMessage = "API 密钥有效，已启用。"
                    DispatchQueue.main.async {
                        self.apiKeyManager.updateAPIKey(key)
                    }
                } else {
                    alertMessage = "API 密钥无效，请检查后重试。"
                }
            } catch {
                alertMessage = "解析响应错误: \(error.localizedDescription)"
            }
            showAlert = true
        }.resume()
    }
}

#if DEBUG
struct ChatAISetting_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatAISetting(apiKeyManager: APIKeyManager())
                .environment(\.colorScheme, .light)
            ChatAISetting(apiKeyManager: APIKeyManager())
                .environment(\.colorScheme, .dark)
        }
    }
}
#endif

