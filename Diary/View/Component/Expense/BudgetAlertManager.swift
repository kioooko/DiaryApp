import SwiftUI
import CoreData
import UserNotifications

class BudgetAlertManager: ObservableObject {
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = ""
    @Published var isShowingCompletionModal = false
    @Published var currentGoal: SavingsGoal?
    @Published var context: NSManagedObjectContext?
    @Published var shouldDismissParentView = false  // 添加控制父视图关闭的状态
    
    // 预算阈值
    private let warningThreshold: Double = 0.9  // 90%
    private let cautionThreshold: Double = 0.7  // 70%
    
    // 检查储蓄目标完成状态
    func checkSavingsGoalCompletion(goal: SavingsGoal, context: NSManagedObjectContext) -> String? {
        let targetAmount = goal.targetAmount  // 直接使用，不需要解包
        
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
            
            print("目标金额: \(targetAmount), 实际储蓄: \(totalSaving)")
            
            // 如果达到目标金额且未标记为完成
            if totalSaving >= targetAmount && !goal.isCompleted {
                goal.isCompleted = true
                try context.save()  // 确保保存状态
                print("储蓄目标已完成！")
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
            guard let currentGoal = goals.first else { return nil }
            let monthlyBudget = currentGoal.monthlyBudget  // 直接使用，不需要解包
            
            if monthlyBudget <= 0 { return nil }  // 单独检查是否大于0
            
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
            let usageRatio = totalExpense / monthlyBudget
            
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
        budgetRequest.predicate = NSPredicate(format: "isCompleted == false")
        budgetRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)]
        budgetRequest.fetchLimit = 1
        
        do {
            let budgets = try context.fetch(budgetRequest)
            guard let currentGoal = budgets.first else { return nil }
            let monthlyBudget = currentGoal.monthlyBudget  // 直接使用，不需要解包
            
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

    func showCompletionModal(for goal: SavingsGoal, in context: NSManagedObjectContext) {
        print("准备显示完成弹窗 - 目标：\(goal.title ?? "")")
        self.currentGoal = goal
        self.context = context
        self.isShowingCompletionModal = true
        self.shouldDismissParentView = false
    }

    func checkSavingGoalCompletion(goal: SavingsGoal, in context: NSManagedObjectContext) {
        print("检查储蓄目标完成状态...")
        
        // 检查时间是否达到目标日期
        guard let targetDate = goal.targetDate else { return }
        let currentDate = Date()
        
        // 如果还未到目标日期，不触发完成状态
        if currentDate < targetDate {
            print("未到目标日期，不触发完成状态")
            return
        }
        
        // 获取实际储蓄金额
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(
            format: "amount > 0 AND date >= %@ AND date <= %@",
            goal.startDate! as NSDate,
            targetDate as NSDate
        )
        
        do {
            let items = try context.fetch(request)
            let actualSaving = items.reduce(0.0) { $0 + $1.amount }
            print("目标金额: \(goal.targetAmount), 实际储蓄: \(actualSaving)")
            
            // 只有在达到目标日期且达到目标金额时才标记为完成
            if actualSaving >= goal.targetAmount && !goal.isCompleted {
                print("检测到储蓄目标达成且时间已到，显示完成弹窗")
                DispatchQueue.main.async {
                    self.showCompletionModal(for: goal, in: context)
                }
            } else if actualSaving < goal.targetAmount {
                print("未达到目标金额，不触发完成状态")
            }
        } catch {
            print("检查储蓄目标完成状态失败: \(error)")
        }
    }

    func checkSavingGoalCompletion(goal: SavingsGoal, context: NSManagedObjectContext) -> Bool {
        guard let startDate = goal.startDate,
              let targetDate = goal.targetDate else {
            return false
        }
        
        let targetAmount = goal.targetAmount  // 直接使用，不需要解包
        
        // 计算时间进度
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 0
        let passedDays = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        // 获取收支数据
        let request: NSFetchRequest<Item> = NSFetchRequest(entityName: "Item")
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            targetDate as NSDate
        )
        
        do {
            let items = try context.fetch(request)
            let income = items.filter { $0.amount > 0 }.map { $0.amount }.reduce(0, +)
            let expense = items.filter { $0.amount < 0 }.map { abs($0.amount) }.reduce(0, +)
            let actualSavings = income - expense
            
            // 计算进度
            let savingsProgress = min(1.0, actualSavings / targetAmount)
            let timeProgress = Double(passedDays) / Double(totalDays)
            let finalProgress = savingsProgress * timeProgress
            
            return finalProgress >= 1.0
        } catch {
            print("获取收支数据失败: \(error)")
            return false
        }
    }
}

struct SavingsGoalsView: View {
    @FetchRequest(
        entity: SavingsGoal.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \SavingsGoal.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \SavingsGoal.targetDate, ascending: true)
        ]
    ) private var goals: FetchedResults<SavingsGoal>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 进行中的目标
            if !inProgressGoals.isEmpty {
                Text("进行中的目标")
                    .font(.headline)
                ForEach(inProgressGoals) { goal in
                    SavingsGoalProgressView(goal: goal)
                }
            }
            
            // 已完成的目标
            if !completedGoals.isEmpty {
                Text("已完成的目标")
                    .font(.headline)
                    .padding(.top)
                ForEach(completedGoals) { goal in
                    SavingsGoalProgressView(goal: goal)
                }
            }
        }
        .padding()
    }
    
    private var inProgressGoals: [SavingsGoal] {
        goals.filter { !$0.isCompleted }
    }
    
    private var completedGoals: [SavingsGoal] {
        goals.filter { $0.isCompleted }
    }
}

struct SavingsGoalProgressView: View {
    @ObservedObject var goal: SavingsGoal
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var alertManager = BudgetAlertManager()
    
    var body: some View {
        VStack {
            // ... existing progress view code ...
        }
        .opacity(goal.isCompleted ? 0.7 : 1.0)
        .onAppear {
            // 视图出现时检查完成状态
            alertManager.checkSavingGoalCompletion(goal: goal, in: viewContext)
        }
        .onChange(of: goal.isCompleted) { oldValue, newValue in
            // 当完成状态改变时检查
            if !newValue {
                alertManager.checkSavingGoalCompletion(goal: goal, in: viewContext)
            }
        }
        .sheet(isPresented: $alertManager.isShowingCompletionModal) {
            if let currentGoal = alertManager.currentGoal {
                CompletionModalView(
                    goal: currentGoal,
                    isPresented: $alertManager.isShowingCompletionModal,
                    shouldDismissParentView: $alertManager.shouldDismissParentView
                )
            }
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

// 扩展 SavingsGoal 实体
extension SavingsGoal {
    var isTimeCompleted: Bool {
        guard let targetDate = targetDate else { return false }
        return Date() >= targetDate
    }
    
    var isAmountCompleted: Bool {
        guard let startDate = startDate,
              let targetDate = targetDate else { return false }
        
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(
            format: "amount > 0 AND date >= %@ AND date <= %@",
            startDate as NSDate,
            targetDate as NSDate
        )
        
        do {
            if let context = self.managedObjectContext {
                let items = try context.fetch(request)
                let actualSaving = items.reduce(0.0) { $0 + $1.amount }
                return actualSaving >= targetAmount
            }
        } catch {
            print("计算储蓄金额失败: \(error)")
        }
        return false
    }
    
    var shouldComplete: Bool {
        return isTimeCompleted && isAmountCompleted
    }
}

struct CompletionModalView: View {
    @ObservedObject var goal: SavingsGoal
    @Environment(\.managedObjectContext) var context
    @Binding var isPresented: Bool
    @Binding var shouldDismissParentView: Bool
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 点击背景不关闭弹窗
                }
            
            // 弹窗内容
            VStack(spacing: 20) {
                // 顶部图标
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.green)
                
                // 标题
                Text("储蓄目标完成")
                    .font(.title2)
                    .bold()
                
                // 内容
                VStack(spacing: 10) {
                    Text("恭喜！您已经完成了储蓄目标")
                        .font(.body)
                    Text(goal.title ?? "")
                        .font(.headline)
                    Text("目标金额：¥\(String(format: "%.2f", goal.targetAmount))")
                        .font(.body)
                }
                .multilineTextAlignment(.center)
                
                // 确认按钮
                Button(action: {
                    // 只有在时间和金额都达标时才允许完成
                    if goal.shouldComplete {
                        goal.isCompleted = true
                        try? context.save()
                        isPresented = false
                        shouldDismissParentView = true
                    }
                }) {
                    Text("确认")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(goal.shouldComplete ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!goal.shouldComplete)
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
    }
}

// 在记账页面中使用
struct ExpenseInputView: View {
    @StateObject private var alertManager = BudgetAlertManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            // ... 现有的记账输入界面 ...
        }
        .sheet(isPresented: $alertManager.isShowingCompletionModal) {
            if let currentGoal = alertManager.currentGoal {
                CompletionModalView(
                    goal: currentGoal,
                    isPresented: $alertManager.isShowingCompletionModal,
                    shouldDismissParentView: $alertManager.shouldDismissParentView
                )
            }
        }
        .onChange(of: alertManager.shouldDismissParentView) { oldValue, newValue in
            if newValue {
                dismiss()  // 只有在确认按钮点击后才关闭记账页面
            }
        }
    }
}