//
//  CoreDataProvider.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/23.
//

import CoreData// 导入 CoreData 框架

public class CoreDataProvider: ObservableObject {// 定义一个 CoreDataProvider 类，继承自 ObservableObject
    static let shared = CoreDataProvider()// 定义一个静态属性 shared，用于存储 CoreDataProvider 的实例

    @Published var coreDataProviderError: CoreDataProviderError?// 定义一个 @Published 属性 coreDataProviderError，用于存储 CoreDataProviderError 的实例

    let container: NSPersistentCloudKitContainer

    init() {
        container = NSPersistentCloudKitContainer(name: "Diary")// 创建一个 NSPersistentCloudKitContainer 对象，用于存储 CoreData 数据

        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in// 加载持久化存储
            if let self,// 如果 self 存在
               let error = error as NSError? {// 如果 error 存在
                 /*
                 这里的典型错误原因包括：
                 * 父目录不存在，无法创建或不允许写入。
                 * 持久化存储不可访问，可能是由于权限或设备锁定时的数据保护。
                 * 设备空间不足。
                 * 存储无法迁移到当前模型版本。
                 检查错误信息以确定实际问题。
                 */
                self.coreDataProviderError = .failedToInit(error: error)// 将错误信息传递给 coreDataProviderError
                print("Failed to load persistent stores: \(error), \(error.userInfo)")// 打印错误信息
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
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
