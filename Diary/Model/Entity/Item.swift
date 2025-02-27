import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var body: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var weather: String?
    @NSManaged public var checkListItems: NSSet?
    
    // 记账相关属性
    @NSManaged public var amount: Double
    @NSManaged public var isExpense: Bool
    @NSManaged public var note: String?
    @NSManaged public var expenseCategory: String?

    public override func validateTitle(_ value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        // 移除标题验证，允许为空
        return
    }

    var amount: Double {
        get { primitiveValue(forKey: "amount") as? Double ?? 0 }
        set { setPrimitiveValue(newValue, forKey: "amount") }
    }

    var isExpense: Bool {
        get { primitiveValue(forKey: "isExpense") as? Bool ?? true }
        set { setPrimitiveValue(newValue, forKey: "isExpense") }
    }

    var note: String? {
        get { primitiveValue(forKey: "note") as? String }
        set { setPrimitiveValue(newValue, forKey: "note") }
    }
}

// MARK: - 记账相关扩展
extension Item {
    // 创建记账记录
    static func createExpenseItem(
        amount: Double,
        isExpense: Bool,
        note: String? = nil,
        context: NSManagedObjectContext
    ) throws {
        let item = Item(context: context)
        item.id = UUID()
        item.amount = amount
        item.isExpense = isExpense
        item.note = note
        item.date = Date()
        item.createdAt = Date()
        item.updatedAt = Date()
        try context.save()
    }
}

// MARK: - 预览扩展
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