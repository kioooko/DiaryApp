import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var body: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var imageURL: String?
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var weather: String?
    @NSManaged public var note: String?
    @NSManaged public var checkListItems: NSSet?

    // 兼容旧数据的计算属性
    @objc public var imageData: Data? {
        get {
            // 如果有imageURL，尝试加载图片
            if let urlString = imageURL, let url = URL(string: urlString) {
                do {
                    let data = try Data(contentsOf: url)
                    return data
                } catch {
                    print("无法从URL加载图片数据: \(error)")
                    return nil
                }
            }
            return nil
        }
        set {
            // 如果设置了新的imageData，保存为本地文件并更新imageURL
            if let newData = newValue {
                saveImageDataToFile(newData)
            } else {
                // 如果设置为nil，清除imageURL
                imageURL = nil
            }
        }
    }
    
    private func saveImageDataToFile(_ data: Data) {
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dirURL = docURL.appendingPathComponent("DiaryImages")
        
        // 确保目录存在
        if !fileManager.fileExists(atPath: dirURL.path) {
            do {
                try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
            } catch {
                print("创建图片目录失败: \(error)")
                return
            }
        }
        
        // 为图片创建唯一文件名
        let uuid = id ?? UUID()
        let imageFileName = "\(uuid.uuidString).jpg"
        let fileURL = dirURL.appendingPathComponent(imageFileName)
        
        do {
            try data.write(to: fileURL)
            imageURL = fileURL.absoluteString
        } catch {
            print("保存图片文件失败: \(error)")
        }
    }
    
    public override func validateTitle(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        // 移除标题验证，允许为空
        return
    }
    
    // 确保在创建时生成UUID
    public override func awakeFromInsert() {
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

// MARK: - 记账相关扩展
extension Item {
    // 记账相关属性
    var amount: Double {
        get { primitiveValue(forKey: "amount") as? Double ?? 0 }
        set { setPrimitiveValue(newValue, forKey: "amount") }
    }
    
    var isExpense: Bool {
        get { primitiveValue(forKey: "isExpense") as? Bool ?? true }
        set { setPrimitiveValue(newValue, forKey: "isExpense") }
    }
     
    var expenseCategory: String? {
        get { primitiveValue(forKey: "expenseCategory") as? String }
        set { setPrimitiveValue(newValue, forKey: "expenseCategory") }
    }
    
    // 创建记账记录
    static func createExpenseItem(
        amount: Double,
        isExpense: Bool,
        context: NSManagedObjectContext
    ) throws {
        let item = Item(context: context)
        item.amount = amount
        item.isExpense = isExpense
        item.note = note
        item.date = Date()
        item.createdAt = Date()
        item.updatedAt = Date()
        try context.save()
    }
    
    // 预览用
    static var preview: Item {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let item = Item(context: context)
        item.id = UUID()
        item.date = Date()
        item.amount = 100
        item.isExpense = true
        item.note = "预览备注"
        return item
    }
}

#if DEBUG
extension Item {
    static var preview: Item {
        let context = PersistenceController.preview.container.viewContext
        let item = Item(context: context)
        item.id = UUID()
        item.date = Date()
        item.createdAt = Date()
        item.updatedAt = Date()
        item.title = "预览标题"
        item.body = "预览内容"
        item.amount = 100
        item.isExpense = true
        item.note = "预览备注"
        return item
    }
    
    static func makeRandom(withImage: Bool = false) -> Item {
        let context = PersistenceController.preview.container.viewContext
        let item = Item(context: context)
        item.id = UUID()
        item.date = Date()
        item.createdAt = Date()
        item.updatedAt = Date()
        item.title = "预览标题"
        item.body = "预览内容"
        item.amount = Double.random(in: 1...1000)
        item.isExpense = Bool.random()
        item.note = "预览备注"
        return item
    }
}
#endif