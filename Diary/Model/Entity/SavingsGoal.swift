import Foundation
import CoreData

@objc(SavingsGoal)
public class SavingsGoal: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var targetAmount: Double
    @NSManaged public var currentAmount: Double
    @NSManaged public var deadline: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var expenses: NSSet?
    
    // 兼容旧模型的计算属性
    var startDate: Date? {
        get { createdAt }
        set { createdAt = newValue }
    }
    
    var targetDate: Date? {
        get { deadline }
        set { deadline = newValue }
    }
    
    var isCompleted: Bool {
        get {
            guard let deadline = deadline else { return false }
            return Date() >= deadline || currentAmount >= targetAmount
        }
        set { /* 不支持直接设置 */ }
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

// MARK: - 功能扩展
extension SavingsGoal {
    static func create(
        title: String,
        targetAmount: Double,
        deadline: Date,
        in context: NSManagedObjectContext
    ) -> SavingsGoal {
        let goal = SavingsGoal(context: context)
        goal.id = UUID()
        goal.title = title
        goal.targetAmount = max(0, targetAmount)
        goal.currentAmount = 0
        goal.deadline = deadline
        goal.createdAt = Date()
        goal.updatedAt = Date()
        return goal
    }
    
    // 计算获取相关支出
    func allExpenses() -> [Expense] {
        return (expenses?.allObjects as? [Expense]) ?? []
    }
    
    // 计算剩余天数
    var remainingDays: Int {
        guard let deadline = deadline else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: deadline)
        return max(0, components.day ?? 0)
    }
    
    // 计算进度百分比 (0-100)
    var progressPercentage: Double {
        guard targetAmount > 0 else { return 0 }
        return min(100, (currentAmount / targetAmount) * 100)
    }
    
    // 计算需要的每日存款
    var requiredDailySaving: Double {
        guard let deadline = deadline, remainingDays > 0 else { return 0 }
        let remaining = targetAmount - currentAmount
        return max(0, remaining) / Double(remainingDays)
    }
} 