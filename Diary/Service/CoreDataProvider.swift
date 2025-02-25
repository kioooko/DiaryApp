import CoreData// 导入 CoreData 框架

public class CoreDataProvider: ObservableObject {// 定义一个 CoreDataProvider 类，继承自 ObservableObject
    static let shared = CoreDataProvider()// 定义一个静态属性 shared，用于存储 CoreDataProvider 的实例

    @Published var coreDataProviderError: CoreDataProviderError?// 定义一个 @Published 属性 coreDataProviderError，用于存储 CoreDataProviderError 的实例

    let container: NSPersistentCloudKitContainer

    init() {
        container = NSPersistentCloudKitContainer(name: "Diary")
        
        // 添加迁移选项
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            // 如果迁移失败，删除并重建存储
            NSPersistentStoreRemoveUbiquitousMetadataOption: true
        ]
        
        // 获取存储URL
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            fatalError("Failed to get store URL")
        }
        
        // 如果存在旧的存储文件，先删除
        if FileManager.default.fileExists(atPath: storeURL.path) {
            do {
                try FileManager.default.removeItem(at: storeURL)
            } catch {
                print("Failed to delete old store: \(error)")
            }
        }
        
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            if let self,
               let error = error as NSError? {
                // 处理错误
                self.coreDataProviderError = .failedToInit(error: error)
                print("Failed to load persistent stores: \(error), \(error.userInfo)")
                
                // 尝试删除并重建存储
                do {
                    try FileManager.default.removeItem(at: storeURL)
                    self.container.loadPersistentStores { (_, error) in
                        if let error = error {
                            print("Failed to recreate store: \(error)")
                        }
                    }
                } catch {
                    print("Failed to delete corrupted store: \(error)")
                }
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 确保所有实体都有 ID
        ensureEntityIDs()
        
        // 验证实体
        validateEntities()
    }
     // 新增：导出所有 DiaryEntry 数据
    func exportAllDiaryEntries() -> [Item] {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        do {
            let diaryEntries = try container.viewContext.fetch(fetchRequest)
            return diaryEntries
        } catch {
            print("Failed to fetch DiaryEntry: \(error)")
            return []
        }
    }

    func fetchAllSavingsGoals() -> [SavingsGoal] {
        let request = NSFetchRequest<SavingsGoal>(entityName: "SavingsGoal")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("❌ 获取储蓄目标失败: \(error)")
            return []
        }
    }

    // 获取所有待办事项
    func fetchAllCheckListItems() -> [CheckListItem] {
        let request = NSFetchRequest<CheckListItem>(entityName: "checkListItem")
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("❌ 获取待办事项失败: \(error)")
            return []
        }
    }
    
    // 获取所有联系人
    func fetchAllContacts() -> [Contact] {
        let request = NSFetchRequest<Contact>(entityName: "contact")
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("❌ 获取联系人失败: \(error)")
            return []
        }
    }

    private func validateEntities() {
        let context = container.viewContext
        
        // 检查并修复缺失的 ID
        let entities = ["Item", "CheckListItem", "Contact", "SavingsGoal"]
        
        for entityName in entities {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            
            do {
                let objects = try context.fetch(request)
                for object in objects {
                    if object.value(forKey: "id") == nil {
                        object.setValue(UUID(), forKey: "id")
                    }
                }
            } catch {
                print("Failed to validate \(entityName): \(error)")
            }
        }
        
        // 保存更改
        do {
            try context.save()
        } catch {
            print("Failed to save validation changes: \(error)")
        }
    }

    // 添加一个辅助方法来确保所有实体都有 id
    private func ensureEntityIDs() {
        let context = container.viewContext
        
        // 检查所有实体类型
        let entities = ["Item", "CheckListItem", "Contact", "SavingsGoal"]
        
        for entityName in entities {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            
            do {
                let objects = try context.fetch(request)
                var needsSave = false
                
                for object in objects {
                    if object.value(forKey: "id") == nil {
                        object.setValue(UUID(), forKey: "id")
                        needsSave = true
                    }
                }
                
                if needsSave {
                    try context.save()
                }
            } catch {
                print("检查 \(entityName) ID 时出错: \(error)")
            }
        }
    }

    func validateAllEntities() {
        let context = container.viewContext
        
        do {
            // 验证 Item
            let items = try context.fetch(Item.fetchRequest())
            for item in items where item.id == nil {
                item.id = UUID()
            }
            
            // 验证 CheckListItem
            let checkListItems = try context.fetch(CheckListItem.fetchRequest())
            for item in checkListItems where item.id == nil {
                item.id = UUID()
            }
            
            // 验证 Contact
            let contacts = try context.fetch(Contact.fetchRequest())
            for contact in contacts where contact.id == nil {
                contact.id = UUID()
            }
            
            // 验证 SavingsGoal
            let goals = try context.fetch(SavingsGoal.fetchRequest())
            for goal in goals where goal.id == nil {
                goal.id = UUID()
            }
            
            // 保存更改
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("验证实体时出错：", error)
        }
    }
}

extension CoreDataProvider {// 扩展 CoreDataProvider 类 
    static var preview: CoreDataProvider = {// 定义一个静态方法 preview，用于创建一个 CoreDataProvider 的实例
        let result = CoreDataProvider()// 创建一个 CoreDataProvider 的实例
        let viewContext = result.container.viewContext// 获取 viewContext

        // 每次在预览中加载时，这里都会触发并增加元素。为了避免这种情况，删除所有元素。
        deleteAll(container: result.container)
        
        for _ in 0..<10 {
            let newItem: Item = .makeRandom(context: viewContext)// 创建一个 Item 的实例
            print("newItem: \(newItem)")
        }

        for _ in 0..<5 {// 创建 5 个 CheckListItem 的实例
            let newCheckList: CheckListItem = .makeRandom(context: viewContext)// 创建一个 CheckListItem 的实例
            print("newCheckList: \(newCheckList)")
        }

        do {// 保存 viewContext
            try viewContext.save()// 保存 viewContext
        } catch {// 如果保存失败
            let nsError = error as NSError// 将 error 转换为 NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")// 打印错误信息
        }// 如果保存成功
        return result// 返回 result
    }()

    static func deleteAll(container: NSPersistentContainer) {// 定义一个静态方法 deleteAll，用于删除所有数据
        let itemFetchRequest: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()// 创建一个 NSFetchRequest 对象，用于获取 Item 实体
        let batchDeleteRequestForItem = NSBatchDeleteRequest(fetchRequest: itemFetchRequest)// 创建一个 NSBatchDeleteRequest 对象，用于删除 Item 实体

        let checkListItemFetchRequest: NSFetchRequest<NSFetchRequestResult> = CheckListItem.fetchRequest()// 创建一个 NSFetchRequest 对象，用于获取 CheckListItem 实体
        let batchDeleteRequestForCheckListItem = NSBatchDeleteRequest(fetchRequest: checkListItemFetchRequest)// 创建一个 NSBatchDeleteRequest 对象，用于删除 CheckListItem 实体

        _ = try? container.viewContext.execute(batchDeleteRequestForItem)// 执行删除 Item 实体的请求
        _ = try? container.viewContext.execute(batchDeleteRequestForCheckListItem)// 执行删除 CheckListItem 实体的请求

    }
}

public enum CoreDataProviderError: Error, LocalizedError {// 定义一个 CoreDataProviderError 枚举，用于存储错误信息
    case failedToInit(error: Error?)// 定义一个 failedToInit 枚举，用于存储错误信息

    public var errorDescription: String? {// 定义一个 errorDescription 属性，用于存储错误信息 
        switch self {// 根据 self 的值返回不同的错误信息
        case .failedToInit:// 如果 self 是 failedToInit
            return "Failed to setup"// 返回 "Failed to setup"
        }
    }

    public var recoverySuggestion: String? {// 定义一个 recoverySuggestion 属性，用于存储错误信息 
        switch self {// 根据 self 的值返回不同的错误信息
        case .failedToInit(let error):
            return "Sorry, please check message👇\n\(error?.localizedDescription ?? "")"// 返回 "Sorry, please check message👇\n\(error?.localizedDescription ?? "")"
        }
    }
}
