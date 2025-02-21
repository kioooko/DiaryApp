import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var body: String?
    @NSManaged public var date: Date
    @NSManaged public var weather: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var amount: Double
    @NSManaged public var note: String?
    @NSManaged public var isExpense: Bool
    @NSManaged public var checkListItems: Set<CheckListItem>?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
        date = Date()
        isBookmarked = false
        isExpense = false
        amount = 0
        title = ""
    }
}

// MARK: - Generated accessors for checkListItems
extension Item {
    @objc(addCheckListItemsObject:)
    @NSManaged public func addToCheckListItems(_ value: CheckListItem)
    
    @objc(removeCheckListItemsObject:)
    @NSManaged public func removeFromCheckListItems(_ value: CheckListItem)
    
    @objc(addCheckListItems:)
    @NSManaged public func addToCheckListItems(_ values: NSSet)
    
    @objc(removeCheckListItems:)
    @NSManaged public func removeFromCheckListItems(_ values: NSSet)
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
     
    var note: String? {
        get { primitiveValue(forKey: "note") as? String }
        set { setPrimitiveValue(newValue, forKey: "note") }
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