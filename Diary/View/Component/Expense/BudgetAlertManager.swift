import SwiftUI
import CoreData
import UserNotifications

class BudgetAlertManager: ObservableObject {
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    // 预算阈值
    private let warningThreshold = 0.9 // 90%
    private let cautionThreshold = 0.7 // 70%
    
    // 检查预算状态并返回提醒消息
    func checkBudgetStatus(context: NSManagedObjectContext) -> String? {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return nil
        }
        
        // 获取当月支出
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@ AND amount < 0",
            startOfMonth as CVarArg,
            endOfMonth as CVarArg
        )
        
        do {
            let items = try context.fetch(request)
            let totalExpense = abs(items.map { $0.amount }.reduce(0, +))
            
            // 获取月度预算
            let budgetRequest = NSFetchRequest<SavingsGoal>(entityName: "SavingsGoal")
            budgetRequest.predicate = NSPredicate(format: "monthlyDate >= %@ AND monthlyDate <= %@", 
                                                startOfMonth as CVarArg,
                                                endOfMonth as CVarArg)
            
            let budgets = try context.fetch(budgetRequest)
            guard let monthlyBudget = budgets.first?.monthlyAmount, monthlyBudget > 0 else {
                return nil
            }
            
            // 计算预算使用比例
            let usageRatio = totalExpense / monthlyBudget
            
            // 根据使用比例返回不同的提醒消息
            if usageRatio >= 1.0 {
                return "⚠️ 警告：本月支出已超出预算 ¥\(String(format: "%.2f", totalExpense - monthlyBudget))"
            } else if usageRatio >= warningThreshold {
                return "⚠️ 注意：本月支出已达 \(Int(usageRatio * 100))% 预算，请控制支出"
            } else if usageRatio >= cautionThreshold {
                return "📊 提示：本月支出已达 \(Int(usageRatio * 100))% 预算"
            }
            
            return nil
            
        } catch {
            print("获取预算数据失败: \(error)")
            return nil
        }
    }
    
    // 发送每日预算提醒
    func sendDailyBudgetNotification(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // 获取今日支出
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND amount < 0",
            today as CVarArg,
            tomorrow as CVarArg
        )
        
        do {
            let items = try context.fetch(request)
            let todayExpense = abs(items.map { $0.amount }.reduce(0, +))
            
            // 获取剩余预算
            if let remainingBudget = calculateRemainingBudget(context: context) {
                // 创建通知内容
                let content = UNMutableNotificationContent()
                content.title = "今日消费总结"
                content.body = "今日已消费 ¥\(String(format: "%.2f", todayExpense))，剩余预算 ¥\(String(format: "%.2f", remainingBudget))"
                content.sound = .default
                
                // 设置通知触发时间（晚上9点）
                var dateComponents = DateComponents()
                dateComponents.hour = 21
                dateComponents.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                // 创建通知请求
                let request = UNNotificationRequest(identifier: "dailyBudgetSummary",
                                                  content: content,
                                                  trigger: trigger)
                
                // 添加通知请求
                UNUserNotificationCenter.current().add(request)
            }
        } catch {
            print("获取今日支出数据失败: \(error)")
        }
    }
    
    // 计算剩余预算
    private func calculateRemainingBudget(context: NSManagedObjectContext) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return nil
        }
        
        // 获取月度预算
        let budgetRequest = NSFetchRequest<SavingsGoal>(entityName: "SavingsGoal")
        budgetRequest.predicate = NSPredicate(format: "monthlyDate >= %@ AND monthlyDate <= %@",
                                            startOfMonth as CVarArg,
                                            endOfMonth as CVarArg)
        
        do {
            let budgets = try context.fetch(budgetRequest)
            guard let monthlyBudget = budgets.first?.monthlyAmount else { return nil }
            
            // 获取当月总支出
            let expenseRequest = NSFetchRequest<Item>(entityName: "Item")
            expenseRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@ AND amount < 0",
                startOfMonth as CVarArg,
                endOfMonth as CVarArg
            )
            
            let expenses = try context.fetch(expenseRequest)
            let totalExpense = abs(expenses.map { $0.amount }.reduce(0, +))
            
            return monthlyBudget - totalExpense
            
        } catch {
            print("计算剩余预算失败: \(error)")
            return nil
        }
    }
}