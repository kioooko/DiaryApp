import Foundation
import CoreData

extension Expense {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var isExpense: Bool
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var contact: Contact?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension Expense {
    static func create(in context: NSManagedObjectContext) -> Expense {
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.createdAt = Date()
        expense.updatedAt = Date()
        return expense
    }
} 