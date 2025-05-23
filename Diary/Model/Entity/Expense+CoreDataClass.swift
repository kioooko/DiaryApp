import Foundation
import CoreData

@objc(Expense)
public class Expense: NSManagedObject {
    // 所有属性都由 Core Data 自动生成
}

extension Expense {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }
} 