import SwiftUI
import CoreData
import UserNotifications

class BudgetAlertManager: ObservableObject {
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = ""
    
    // 预算阈值
    private let warningThreshold: Double = 0.9  // 90%
    private let cautionThreshold: Double = 0.7  // 70%
    
    // 检查储蓄目标完成状态
    func checkSavingsGoalCompletion(goal: SavingsGoal, context: NSManagedObjectContext) -> String? {
        guard let targetAmount = goal.targetAmount as? Double else { return nil }
        
        let startDate: NSDate = (goal.startDate ?? Date()) as NSDate
        let targetDate: NSDate = (goal.targetDate ?? Date()) as NSDate
        
        let request: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
        request.predicate = NSPredicate(
            format: "amount > 0 AND date >= %@ AND date <= %@",
            startDate,
            targetDate
        )
        
        do {
            let items = try context.fetch(request)
            let totalSaving = items.map { $0.amount }.reduce(0, +)
            
            // 如果达到目标金额且未标记为完成
            if totalSaving >= targetAmount && !goal.isCompleted {
                goal.isCompleted = true
                try? context.save()
                return "🎉 恭喜！您已完成储蓄目标 ¥\(String(format: "%.2f", targetAmount))"
            }
        } catch {
            print("检查储蓄目标完成状态失败: \(error)")
        }
        
        return nil
    }
    
    // 显示提醒
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // 检查预算状态并返回提醒消息
    func checkBudgetStatus(context: NSManagedObjectContext) -> String? {
        // 获取当月预算
        let budgetRequest: NSFetchRequest<SavingsGoal> = NSFetchRequest(entityName: "SavingsGoal")
        budgetRequest.predicate = NSPredicate(format: "isCompleted == false")
        budgetRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)]
        budgetRequest.fetchLimit = 1
        
        do {
            let goals = try context.fetch(budgetRequest)
            guard let currentGoal = goals.first,
                  let monthlyAmount = currentGoal.monthlyAmount as? Double,
                  monthlyAmount > 0 else {
                return nil
            }
            
            // 获取当月支出
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let startOfMonth = calendar.date(from: components),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
                return nil
            }
            
            let expenseRequest: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
            expenseRequest.predicate = NSPredicate(
                format: "amount < 0 AND date >= %@ AND date <= %@",
                startOfMonth as NSDate,
                endOfMonth as NSDate
            )
            
            let expenses = try context.fetch(expenseRequest)
            let totalExpense = abs(expenses.map { $0.amount }.reduce(0, +))
            
            // 计算使用比例
            let usageRatio = totalExpense / monthlyAmount
            
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
            format: "amount < 0 AND date >= %@ AND date < %@",
            today as NSDate,
            tomorrow as NSDate
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

struct SavingsGoalProgressView: View {
    @ObservedObject var goal: SavingsGoal
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingCompletionAlert = false
    
    private var progress: Double {
        let calendar = Calendar.current
        let now = Date()
        
        // 计算时间进度
        let totalDays = max(1, calendar.days(from: goal.startDate ?? now, to: goal.targetDate ?? now))
        let passedDays = min(totalDays, calendar.days(from: goal.startDate ?? now, to: now))
        let timeProgress = (Double(passedDays) / Double(totalDays)) * 100
        
        // 计算存储进度
        let targetAmount = goal.targetAmount
        let actualSaving = calculateActualSaving()
        let savingProgress = (actualSaving / targetAmount) * 100
        
        return min(max(savingProgress, timeProgress), 100)
    }
    
    private func calculateActualSaving() -> Double {
        guard let startDate = goal.startDate,
              let targetDate = goal.targetDate else {
            return 0.0
        }
        
        let request: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
        request.predicate = NSPredicate(
            format: "amount > 0 AND date >= %@ AND date <= %@",
            startDate as NSDate,
            targetDate as NSDate
        )
        
        do {
            let items = try viewContext.fetch(request)
            let totalSaving = items.map { $0.amount }.reduce(0, +)
            return totalSaving
        } catch {
            print("计算实际储蓄金额时出错: \(error)")
            return 0.0
        }
    }
    
    var body: some View {
        VStack {
            // ... 现有的视图代码 ...
        }
        .onChange(of: progress) { newProgress in
            if !goal.isCompleted && newProgress >= 100 {
                goal.isCompleted = true
                showingCompletionAlert = true
                try? viewContext.save()
            }
        }
        .alert("恭喜！", isPresented: $showingCompletionAlert) {
            Button("太棒了", role: .cancel) { }
        } message: {
            Text("您已经达成储蓄目标！")
        }
    }
}

// Calendar 扩展
extension Calendar {
    func days(from startDate: Date, to endDate: Date) -> Int {
        let components = dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
}