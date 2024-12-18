import Combine

class APIKeyManager: ObservableObject {
    @Published var apiKey: String = ""

    init() {
        loadDefaultAPIKey()
    }

    private func loadDefaultAPIKey() {
        let filePath = "/Users/kokio/DiaryApp/Chatapi.txt"
        do {
            apiKey = try String(contentsOfFile: filePath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("无法读取默认API密钥: \(error)")
        }
    }
} 
