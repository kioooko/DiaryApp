import CoreData
import Foundation

extension Contact {
    var id: UUID? {
        get { primitiveValue(forKey: "id") as? UUID }
        set { setPrimitiveValue(newValue, forKey: "id") }
    }
    
    var name: String? {
        get { primitiveValue(forKey: "name") as? String }
        set { setPrimitiveValue(newValue, forKey: "name") }
    }
    
    var tier: Int16 {
        get { (primitiveValue(forKey: "tier") as? Int16) ?? 0 }
        set { setPrimitiveValue(newValue, forKey: "tier") }
    }
    
    var notes: String? {
        get { primitiveValue(forKey: "notes") as? String }
        set { setPrimitiveValue(newValue, forKey: "notes") }
    }
    
    var birthday: Date? {
        get { primitiveValue(forKey: "birthday") as? Date }
        set { setPrimitiveValue(newValue, forKey: "birthday") }
    }
    
    var lastInteraction: Date? {
        get { primitiveValue(forKey: "lastInteraction") as? Date }
        set { setPrimitiveValue(newValue, forKey: "lastInteraction") }
    }
    
    var avatarURL: String? {
        get { primitiveValue(forKey: "avatarURL") as? String }
        set { setPrimitiveValue(newValue, forKey: "avatarURL") }
    }
    
    var createdAt: Date? {
        get { primitiveValue(forKey: "createdAt") as? Date }
        set { setPrimitiveValue(newValue, forKey: "createdAt") }
    }
    
    var updatedAt: Date? {
        get { primitiveValue(forKey: "updatedAt") as? Date }
        set { setPrimitiveValue(newValue, forKey: "updatedAt") }
    }
    
    var expenses: NSSet? {
        get { primitiveValue(forKey: "expenses") as? NSSet }
        set { setPrimitiveValue(newValue, forKey: "expenses") }
    }
    
    // 兼容旧数据的计算属性
    @objc var avatar: Data? {
        get {
            // 如果有avatarURL，尝试加载头像
            if let urlString = avatarURL, let url = URL(string: urlString) {
                do {
                    let data = try Data(contentsOf: url)
                    return data
                } catch {
                    print("无法从URL加载头像数据: \(error)")
                    return nil
                }
            }
            return nil
        }
        set {
            // 如果设置了新的avatar，保存为本地文件并更新avatarURL
            if let newData = newValue {
                saveAvatarToFile(newData)
            } else {
                // 如果设置为nil，清除avatarURL
                avatarURL = nil
            }
        }
    }
    
    private func saveAvatarToFile(_ data: Data) {
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dirURL = docURL.appendingPathComponent("ContactAvatars")
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: dirURL.path) {
            do {
                try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
            } catch {
                print("创建头像目录失败: \(error)")
                return
            }
        }
        
        // 为头像创建唯一文件名
        let uuid = id ?? UUID()
        let imageFileName = "\(uuid.uuidString).jpg"
        let fileURL = dirURL.appendingPathComponent(imageFileName)
        
        do {
            try data.write(to: fileURL)
            avatarURL = fileURL.absoluteString
        } catch {
            print("保存头像文件失败: \(error)")
        }
    }
    
    // 确保在创建时生成UUID
    @objc func awakeFromInsert() {
        super.awakeFromInsert()
        
        if id == nil {
            id = UUID()
        }
        
        if createdAt == nil {
            createdAt = Date()
        }
        
        if updatedAt == nil {
            updatedAt = Date()
        }
    }
} 