import Foundation
import CoreData
import Diary  // 导入包含 CoreData 实体的模块

// 重命名以避免冲突
struct DataExport: Codable {
    let items: [ItemExport]
    let contacts: [ContactExport]
    let savingsGoals: [SavingsGoalExport]
    let expenses: [ExpenseExport]
}

// 将所有内部结构体移到外部，避免命名冲突
struct ItemExport: Codable {
    let id: UUID
    let title: String
    let body: String?
    let date: Date
    let amount: Double?
    let isExpense: Bool?
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

struct ContactExport: Codable {
    let id: UUID
    let name: String
    let tier: Int16
    let birthday: Date?
    let notes: String?
    let lastInteraction: Date?
    let avatar: Data?
    let createdAt: Date
    let updatedAt: Date?
}

struct SavingsGoalExport: Codable {
    let id: UUID
    let title: String
    let targetAmount: Double
    let currentAmount: Double
    let deadline: Double?
    let monthlyBudget: Double
    let monthlyAmount: Double  // 修正为 Double 类型
    let startDate: Date?
    let targetDate: Date?
    let isCompleted: Bool
    let completedDate: Date?
    let createdAt: Date
    let updatedAt: Date?
}

struct ExpenseExport: Codable {
    let id: UUID
    let title: String
    let amount: Double
    let date: Date
    let isExpense: Bool
    let note: String?
    let createdAt: Date
    let updatedAt: Date?
    let contactId: UUID?
    let goalId: UUID?
}

// 扩展方法移到单独的扩展中
extension DataExport {
    static func from(
        items: [Item],
        contacts: [Contact],
        savingsGoals: [SavingsGoal],
        expenses: [Expense]
    ) -> DataExport {
        return DataExport(
            items: items.map { item in
                ItemExport(
                    id: item.id ?? UUID(),
                    title: item.title ?? "",
                    body: item.body,
                    date: item.date ?? Date(),
                    amount: item.amount,
                    isExpense: item.isExpense,
                    note: item.note,
                    weather: item.weather,
                    isBookmarked: item.isBookmarked,
                    imageData: item.imageData,
                    checkListItems: (item.checkListItems?.allObjects as? [CheckListItem] ?? []).map { checkListItem in
                        CheckListItemExport(
                            id: checkListItem.id ?? UUID(),
                            title: checkListItem.title ?? "",
                            isCompleted: checkListItem.isCompleted,
                            createdAt: checkListItem.createdAt ?? Date(),
                            updatedAt: checkListItem.updatedAt
                        )
                    },
                    createdAt: item.createdAt ?? Date(),
                    updatedAt: item.updatedAt
                )
            },
            contacts: contacts.map { contact in
                ContactExport(
                    id: contact.id ?? UUID(),
                    name: contact.name ?? "",
                    tier: contact.tier,
                    birthday: contact.birthday,
                    notes: contact.notes,
                    lastInteraction: contact.lastInteraction,
                    avatar: contact.avatar,
                    createdAt: contact.createdAt ?? Date(),
                    updatedAt: contact.updatedAt
                )
            },
            savingsGoals: savingsGoals.map { goal in
                SavingsGoalExport(
                    id: goal.id ?? UUID(),
                    title: goal.title ?? "",
                    targetAmount: (goal.targetAmount as? NSNumber)?.doubleValue ?? 0.0,
                    currentAmount: goal.currentAmount,
                    deadline: goal.deadline,
                    monthlyBudget: goal.monthlyBudget,
                    monthlyAmount: goal.monthlyAmount,  // 直接使用 Double
                    startDate: goal.startDate,
                    targetDate: goal.targetDate,
                    isCompleted: goal.isCompleted,
                    completedDate: goal.completedDate,
                    createdAt: goal.createdAt ?? Date(),
                    updatedAt: goal.updatedAt
                )
            },
            expenses: expenses.map { expense in
                ExpenseExport(
                    id: expense.id ?? UUID(),
                    title: expense.title ?? "",
                    amount: expense.amount,
                    date: expense.date ?? Date(),
                    isExpense: expense.isExpense,
                    note: expense.note,
                    createdAt: expense.createdAt ?? Date(),
                    updatedAt: expense.updatedAt,
                    contactId: expense.contact?.id,
                    goalId: expense.goal?.id
                )
            }
        )
    }
}
