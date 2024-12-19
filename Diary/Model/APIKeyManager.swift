import Combine
import Foundation

class APIKeyManager: ObservableObject {
    @Published var apiKey: String = ""

    init() {
        loadAPIKey()
    }

    func updateAPIKey(_ newKey: String) {
        apiKey = newKey
        saveAPIKey(newKey)
    }

    private func loadAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "userAPIKey") {
            apiKey = savedKey
        } else {
            loadDefaultAPIKey()
        }
    }

    private func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "userAPIKey")
    }

    private func loadDefaultAPIKey() {
        if let filePath = Bundle.main.path(forResource: "Chatapi", ofType: "txt") {
            do {
                apiKey = try String(contentsOfFile: filePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                print("无法读取默认API密钥: \(error)")
            }
        } else {
            print("Chatapi.txt 文件未找到")
        }
    }
}

func makeRequest(apiKeyManager: APIKeyManager) {
    guard let url = URL(string: "https://api.example.com/endpoint") else { return }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(apiKeyManager.apiKey)", forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("请求错误: \(error)")
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            print("状态码: \(httpResponse.statusCode)")
        }

        if let data = data {
            print("响应数据: \(String(data: data, encoding: .utf8) ?? "")")
        }
    }
    task.resume()
} 
