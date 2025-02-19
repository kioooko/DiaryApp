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
        print("开始检查月度预算状态...")
        
        // 获取当月预算
        let budgetRequest = NSFetchRequest<SavingsGoal>(entityName: "SavingsGoal")
        budgetRequest.predicate = NSPredicate(format: "isCompleted == false")
        budgetRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)]
        budgetRequest.fetchLimit = 1
        
        do {
            let goals = try context.fetch(budgetRequest)
            guard let currentGoal = goals.first else {
                print("未找到有效的月度预算")
                return nil
            }
            
            let monthlyBudget = currentGoal.monthlyAmount ?? 0
            if monthlyBudget <= 0 {
                print("月度预算金额无效")
                return nil
            }
            
            print("月度预算: ¥\(monthlyBudget)")
            
            // 获取当月支出
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.year, .month], from: now)
            
            guard let startOfMonth = calendar.date(from: components) else {
                print("获取月初日期失败")
                return nil
            }
            
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                .addingTimeInterval(-1)
            
            print("统计周期: \(startOfMonth) 至 \(endOfMonth)")
            
            let expenseRequest = NSFetchRequest<Item>(entityName: "Item")
            expenseRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@ AND amount < 0",
                startOfMonth as CVarArg,
                endOfMonth as CVarArg
            )
            
            let expenses = try context.fetch(expenseRequest)
            let totalExpense = abs(expenses.map { $0.amount }.reduce(0, +))
            print("当月总支出: ¥\(totalExpense)")
            
            // 计算使用比例
            let usageRatio = totalExpense / monthlyBudget
            print("预算使用比例: \(usageRatio * 100)%")
            
            // 返回提醒消息
            if usageRatio >= 1.0 {
                return "⚠️ 警告：本月支出 ¥\(String(format: "%.2f", totalExpense)) 已超出预算"
            } else if usageRatio >= warningThreshold {
                return "⚠️ 注意：本月支出已达 \(Int(usageRatio * 100))% 预算，请控制支出"
            } else if usageRatio >= cautionThreshold {
                return "📊 提示：本月支出已达 \(Int(usageRatio * 100))% 预算"
            }
            
        } catch {
            print("检查预算状态失败: \(error)")
        }
        
        return nil
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