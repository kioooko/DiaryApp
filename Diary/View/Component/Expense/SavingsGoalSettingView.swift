import SwiftUI
import CoreData

// SavingsGoal 扩展
extension SavingsGoal {
    var remainingDays: Int {
        // 拆分计算步骤
        guard let targetDate = targetDate else { 
            return 0 
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        let days = components.day ?? 0
        
        return days
    }
    
    var progress: Double {
        // 防止除以零
        guard targetAmount > 0 else { return 0 }
        
        // 计算时间进度
        guard let startDate = startDate,
              let targetDate = targetDate else { return 0 }
        
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
        let passedDays = calendar.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        // 防止除以零
        guard totalDays > 0 else { return 0 }
        
        // 计算时间进度比例
        let timeProgress = Double(passedDays) / Double(totalDays)
        
        // 计算金额进度比例
        let savingsProgress = currentAmount / targetAmount
        
        // 综合计算最终进度
        let finalProgress = savingsProgress * timeProgress
        
        // 确保进度在 0-1 之间
        return max(0, min(1, finalProgress))
    }
}

struct SavingsGoalSettingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \SavingsGoal.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)
        ],
        predicate: NSPredicate(format: "isCompleted == false"), // 只显示未完成的目标
        animation: .default)
    private var goals: FetchedResults<SavingsGoal>
    
    @State private var goalTitle = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date()
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: SavingsGoal? = nil
    
    var body: some View {
        let mainContent = ScrollView {
            VStack(spacing: 20) {
                formSection
                buttonSection
                if !goals.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("进行中的目标")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(goals) { goal in
                            SavingsGoalCardUI(goal: goal)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                mainContent
            }
            .navigationTitle("储蓄目标")
            .navigationBarTitleDisplayMode(.inline)
            .alert("确认删除", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    if let goal = goalToDelete {
                        deleteGoal(goal)
                    }
                }
            } message: {
                Text("确定要删除这个储蓄目标吗？")
            }
        }
    }
    
    // MARK: - View Components
    private var formSection: some View {
        VStack(spacing: 20) {
            Section("新储蓄目标设置") {
                TextField("储蓄目标名称", text: $goalTitle)
                TextField("储蓄目标金额", text: $targetAmount)
                    .keyboardType(.decimalPad)
                DatePicker("预计完成目标日期", selection: $targetDate, displayedComponents: .date)
            }
            .font(.subheadline)
        }
        .padding()
    }
    
    private var buttonSection: some View {
        HStack(spacing: 20) {
            Button("取消") {
                dismiss()
            }
            .softButtonStyle(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity)
            
            Button("保存") {
                saveGoal()
            }
            .softButtonStyle(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    private func deleteGoal(_ goal: SavingsGoal) {
        viewContext.delete(goal)
        try? viewContext.save()
    }
    
    private func saveGoal() {
        guard let amount = Double(targetAmount), amount > 0 else { return }
        
        let goal = SavingsGoal(context: viewContext)
        goal.title = goalTitle
        goal.targetAmount = amount
        goal.currentAmount = 0
        goal.startDate = Date()
        goal.targetDate = targetDate
        goal.createdAt = Date()
        goal.updatedAt = Date()
        goal.isCompleted = false
        
        try? viewContext.save()
        
        // 重置表单
        goalTitle = ""
        targetAmount = ""
        targetDate = Date()
        
        dismiss()
    }
}

// 将卡片抽取为单独的组件
struct SavingsGoalCardUI: View {
    let goal: SavingsGoal
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // 获取所有收入支出记录
    @FetchRequest
    private var items: FetchedResults<Item>
    
    init(goal: SavingsGoal) {
        self.goal = goal
        // 初始化 FetchRequest
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.date, ascending: true)]
        request.predicate = NSPredicate(format: "amount != 0")
        _items = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(goal.title ?? "储蓄目标")
                    .font(.headline)
                Spacer()
                Text("¥\(Int(goal.targetAmount))")
                    .font(.subheadline)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * CGFloat(calculateProgress()))
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(calculateProgress() * 100))%")
                    .font(.caption)
                Spacer()
                Text("还剩\(goal.remainingDays)天")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.Neumorphic.main)
        .cornerRadius(15)
        .softOuterShadow()
        .padding(.horizontal)
    }
    
    private func calculateProgress() -> Double {
        var totalIncome: Double = 0
        var totalExpense: Double = 0
        
        debugPrint("Debug: 开始计算收支...")
        
        // 确保目标日期存在且有效
        guard let startDate = goal.startDate,
              let targetDate = goal.targetDate else {
            debugPrint("Debug: 日期为空")
            return 0
        }
        
        debugPrint("Debug: 开始日期 - \(startDate)")
        debugPrint("Debug: 目标日期 - \(targetDate)")
        
        // 计算在目标开始日期之后的收入和支出
        let calendar = Calendar.current
        let now = Date()
        
        for item in items {
            guard let itemDate = item.date else { continue }
            
            // 只计算开始日期到当前日期之间的收支
            if itemDate >= startDate && itemDate <= now {
                if item.amount > 0 {
                    totalIncome += item.amount
                } else {
                    totalExpense += abs(item.amount)
                }
            }
        }
        
        debugPrint("Debug: 总收入 - ¥\(totalIncome)")
        debugPrint("Debug: 总支出 - ¥\(totalExpense)")
        
        // 计算实际存储的金额（收入-支出）
        let actualSavings = totalIncome - totalExpense
        debugPrint("Debug: 实际存储 - ¥\(actualSavings)")
        debugPrint("Debug: 目标金额 - ¥\(goal.targetAmount)")
        
        // 计算时间进度
        let totalDays = max(1, calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 1)
        // 设置已过天数最小为1，确保第一天就有进度
        let passedDays = max(1, min(totalDays, calendar.dateComponents([.day], from: startDate, to: now).day ?? 1))
        
        debugPrint("Debug: 总天数 - \(totalDays)")
        debugPrint("Debug: 已过天数 - \(passedDays)")
        
        // 计算进度：(收入-支出)/目标金额 × 已过去天数/总天数
        let savingsProgress = min(1.0, actualSavings / goal.targetAmount) // 限制最大为 100%
        let timeProgress = Double(passedDays) / Double(totalDays)
        let finalProgress = savingsProgress * timeProgress
        
        debugPrint("Debug: 存储进度 - \(savingsProgress * 100)%")
        debugPrint("Debug: 时间进度 - \(timeProgress * 100)%")
        debugPrint("Debug: 最终进度 - \(finalProgress * 100)%")
        
        // 确保进度在 0-1 之间
        return max(0, min(1, finalProgress))
    }

    }
