import Foundation
import CoreData

@objc(Expense)
public class Expense: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var isExpense: Bool
    @NSManaged public var note: String?
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var contact: Contact?
    @NSManaged public var goal: SavingsGoal?
    
    // 确保在创建时生成UUID并设置日期
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
        
        if date == nil {
            date = Date()
        }
    }
}

// MARK: - 扩展功能
extension Expense {
    static func createExpense(
        amount: Double,
        isExpense: Bool,
        title: String,
        note: String? = nil,
        date: Date = Date(),
        contact: Contact? = nil,
        goal: SavingsGoal? = nil,
        in context: NSManagedObjectContext
    ) -> Expense {
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = abs(amount) * (isExpense ? -1 : 1) // 支出为负值，收入为正值
        expense.isExpense = isExpense
        expense.title = title
        expense.note = note
        expense.date = date
        expense.createdAt = Date()
        expense.updatedAt = Date()
        expense.contact = contact
        expense.goal = goal
        
        return expense
    }
    
    // 获取格式化的金额字符串
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_CN")
        
        let value = abs(amount)
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return isExpense ? "-\(formattedValue)" : "+\(formattedValue)"
        }
        
        return isExpense ? "-¥\(abs(amount))" : "+¥\(abs(amount))"
    }
} 