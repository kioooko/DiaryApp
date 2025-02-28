//
//  CoreDataProvider.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/23.
//

import CoreData// 导入 CoreData 框架
import Foundation

public class CoreDataProvider: ObservableObject {// 定义一个 CoreDataProvider 类，继承自 ObservableObject
    static let shared = CoreDataProvider()// 定义一个静态属性 shared，用于存储 CoreDataProvider 的实例

    @Published var coreDataProviderError: CoreDataProviderError?// 定义一个 @Published 属性 coreDataProviderError，用于存储 CoreDataProviderError 的实例

    let container: NSPersistentCloudKitContainer

    init() {
        // 使用正确的模型名称 "Diary"
        container = NSPersistentCloudKitContainer(name: "Diary")
        
        print("尝试加载 Core Data 模型: Diary")

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
                print("错误域: \(error.domain)")
                print("错误代码: \(error.code)")
                print("错误用户信息: \(error.userInfo)")
            } else {
                print("成功加载 Core Data 模型: Diary")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
     // 新增：导出所有 DiaryEntry 数据
    func exportAllDiaryEntries() -> [Item] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
        do {
            let diaryEntries = try container.viewContext.fetch(fetchRequest)
            return diaryEntries.compactMap { $0 as? Item }
        } catch {
            print("Failed to fetch DiaryEntry: \(error)")
            return []
        }
    }

    func fetchAllSavingsGoals() -> [SavingsGoal] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "SavingsGoal")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        do {
            let objects = try container.viewContext.fetch(request)
            return objects.compactMap { $0 as? SavingsGoal }
        } catch {
            print("❌ 获取储蓄目标失败: \(error)")
            return []
        }
    }

    func exportAllData() -> ExportData {
        let context = container.viewContext
        
        // 获取所有实体数据
        let items = fetchEntities(Item.self, in: context)
        let contacts = fetchEntities(Contact.self, in: context)
        let savingsGoals = fetchEntities(SavingsGoal.self, in: context)
        let expenses = fetchEntities(Expense.self, in: context)
        
        return ExportData(
            items: items.map { convertItemToExport($0) },
            contacts: contacts.map { convertContactToExport($0) },
            savingsGoals: savingsGoals.map { convertSavingsGoalToExport($0) },
            expenses: expenses.map { convertExpenseToExport($0) }
        )
    }
    
    private func fetchEntities<T: NSManagedObject>(_ type: T.Type, in context: NSManagedObjectContext) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        return (try? context.fetch(request)) ?? []
    }
}

extension CoreDataProvider {// 扩展 CoreDataProvider 类 
    static var preview: CoreDataProvider = {// 定义一个静态方法 preview，用于创建一个 CoreDataProvider 的实例
        let result = CoreDataProvider()// 创建一个 CoreDataProvider 的实例
        let viewContext = result.container.viewContext// 获取 viewContext

        // 每次在预览中加载时，这里都会触发并增加元素。为了避免这种情况，删除所有元素。
        deleteAll(container: result.container)
        
        for _ in 0..<10 {
            // 使用 NSEntityDescription 创建实体以避免歧义
            let newItem = NSEntityDescription.insertNewObject(forEntityName: "Item", into: viewContext)
            newItem.setValue(UUID(), forKey: "id")
            newItem.setValue(Date(), forKey: "date")
            newItem.setValue(Date(), forKey: "createdAt")
            newItem.setValue(Date(), forKey: "updatedAt")
            newItem.setValue("预览标题", forKey: "title")
            newItem.setValue("预览内容", forKey: "body")
            newItem.setValue(Double.random(in: 1...1000), forKey: "amount")
            newItem.setValue(Bool.random(), forKey: "isExpense")
            newItem.setValue("预览备注", forKey: "note")
            print("newItem: \(newItem)")
        }

        for _ in 0..<5 {// 创建 5 个 CheckListItem 的实例
            // 使用 NSEntityDescription 创建实体以避免歧义
            let newCheckList = NSEntityDescription.insertNewObject(forEntityName: "CheckListItem", into: viewContext)
            newCheckList.setValue(UUID(), forKey: "id")
            newCheckList.setValue("预览待办事项", forKey: "title")
            newCheckList.setValue(Bool.random(), forKey: "isCompleted")
            newCheckList.setValue(Date(), forKey: "createdAt")
            newCheckList.setValue(Date(), forKey: "updatedAt")
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
        // 使用字符串实体名称避免类型歧义
        let itemFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
        let batchDeleteRequestForItem = NSBatchDeleteRequest(fetchRequest: itemFetchRequest)

        let checkListItemFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CheckListItem")
        let batchDeleteRequestForCheckListItem = NSBatchDeleteRequest(fetchRequest: checkListItemFetchRequest)

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

// 为了兼容性，添加 PersistenceController 别名
typealias PersistenceController = CoreDataProvider

// 导出数据结构
struct ExportData: Codable {
    let items: [ItemExport]
    let contacts: [ContactExport]
    let savingsGoals: [SavingsGoalExport]
    let expenses: [ExpenseExport]
    
    struct ItemExport: Codable {
        let id: UUID
        let title: String
        let body: String?
        let date: Date
        let amount: Double
        let isExpense: Bool
        let note: String?
        let weather: String?
        let isBookmarked: Bool
        let imageData: Data?
        let checkListItems: [CheckListItemExport]
        let createdAt: Date
        let updatedAt: Date?
    }
    
    struct CheckListItemExport: Codable {
        let id: UUID
        let title: String
        let isCompleted: Bool
        let createdAt: Date
        let updatedAt: Date?
    }
    
    // ... 其他导出结构体定义
}
