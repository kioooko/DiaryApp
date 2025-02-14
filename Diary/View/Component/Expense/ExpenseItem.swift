import CoreData

@objc(ExpenseItem)
public class ExpenseItem: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var amount: Double
    @NSManaged public var isExpense: Bool
    @NSManaged public var category: String?
    @NSManaged public var note: String?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        date = Date()
    }
    
    static func create(
        amount: Double,
        isExpense: Bool,
        category: String,
        note: String
    ) throws {
        let context = PersistenceController.shared.container.viewContext
        let item = ExpenseItem(context: context)
        item.amount = amount
        item.isExpense = isExpense
        item.category = category
        item.note = note
        try context.save()
    }
    
    func delete() throws {
        let context = PersistenceController.shared.container.viewContext
        context.delete(self)
        try context.save()
    }
}