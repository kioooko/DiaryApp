import SwiftUI
import CoreData

// SavingsGoal 扩展
extension SavingsGoal {
    var remainingDays: Int {
        guard let targetDate = targetDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day ?? 0
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
    
    var displayProgress: Double {
        if isCompleted {
            return 1.0 // 确保已完成的目标显示 100% 进度
        }
        // 使用原有的进度计算逻辑
        return progress
    }
}

struct SavingsGoalSettingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewGoalSheet = false
    
    // 获取未完成的目标
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == false"),
        animation: .default)
    private var activeGoals: FetchedResults<SavingsGoal>
    
    // 获取已完成的目标
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == true"),
        animation: .default)
    private var completedGoals: FetchedResults<SavingsGoal>
    
    @State private var goalTitle = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date()
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: SavingsGoal? = nil
    
    var body: some View {
        let mainContent = ScrollView {
            VStack(spacing: 20) {
                // 进行中的目标
                if !activeGoals.isEmpty {
                    GoalSection(
                        title: "进行中的目标",
                        goals: activeGoals,
                        onDelete: { goal in
                            goalToDelete = goal
                            showingDeleteAlert = true
                        }
                    )
                }
                
                // 已完成的目标
                if !completedGoals.isEmpty {
                    GoalSection(
                        title: "已完成的目标",
                        goals: completedGoals,
                        onDelete: { goal in
                            goalToDelete = goal
                            showingDeleteAlert = true
                        }
                    )
                }
            }
            .padding(.bottom, 20)
        }
        
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                mainContent
            }
            .navigationTitle("储蓄目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewGoalSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewGoalSheet) {
                NewSavingsGoalView()
            }
        }
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
    
    // MARK: - Helper Functions
    private func deleteGoal(_ goal: SavingsGoal) {
        viewContext.delete(goal)
        do {
            try viewContext.save()
        } catch {
            print("删除目标时出错: \(error)")
        }
    }
    
    private func calculateProgress(for goal: SavingsGoal) -> (Double, Double, Double) {
        print("Debug: 开始计算收支...")
        
        // 获取开始日期和目标日期
        let startDate = goal.startDate ?? Date()
        let targetDate = goal.targetDate ?? Date()
        
        print("Debug: 开始日期 - \(startDate)")
        print("Debug: 目标日期 - \(targetDate)")
        
        // 使用 currentAmount 替代计算总收入和支出
        let actualSavings = goal.currentAmount
        
        print("Debug: 实际存储 - ¥\(actualSavings)")
        print("Debug: 目标金额 - ¥\(goal.targetAmount)")
        
        // 计算总天数和已过天数
        let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: targetDate).day ?? 1
        let elapsedDays = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        print("Debug: 总天数 - \(totalDays)")
        print("Debug: 已过天数 - \(elapsedDays)")
        
        // 计算存储进度和时间进度
        let savingsProgress = min((actualSavings / goal.targetAmount) * 100.0, 100.0)
        let timeProgress = min((Double(elapsedDays) / Double(totalDays)) * 100.0, 100.0)
        
        print("Debug: 存储进度 - \(savingsProgress)%")
        print("Debug: 时间进度 - \(timeProgress)%")
        
        // 计算最终进度 - 使用时间进度和存储进度的较小值
        let finalProgress = min(timeProgress, savingsProgress)
        print("Debug: 最终进度 - \(finalProgress)%")
        
        // 修改完成状态的判断逻辑 - 使用最终进度
        let isCompleted = finalProgress >= 100.0
        
        // 如果状态发生变化，更新目标状态
        if goal.isCompleted != isCompleted {
            goal.isCompleted = isCompleted
            try? viewContext.save()
        }
        
        return (savingsProgress, timeProgress, finalProgress)
    }
}

// 目标列表区域组件
struct GoalSection: View {
    let title: String
    let goals: FetchedResults<SavingsGoal>
    let onDelete: (SavingsGoal) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(goals) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    // 已完成目标显示时间信息
                    if goal.isCompleted {
                        HStack {
                            Text("开始时间：\(formatDate(goal.startDate))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("完成时间：\(formatDate(Date()))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    
                    // 原有卡片和删除按钮
                    HStack {
                        SavingsGoalCard(goal: goal)
                            .frame(maxWidth: .infinity)
                        
                        Button(action: {
                            onDelete(goal)
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 10)
    }
    
    // 格式化日期
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "未知" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// 修改 SavingsGoalCardUI 以支持已完成状态的显示
struct SavingsGoalCardUI: View {
    @ObservedObject var goal: SavingsGoal
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(goal.title ?? "储蓄目标")
                    .font(.headline)
                Spacer()
                Text("¥\(Int(goal.targetAmount))")
                    .font(.subheadline)
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
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
                        .frame(width: geometry.size.width * CGFloat(goal.progress))
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                Spacer()
                if !goal.isCompleted {
                    Text("还剩\(goal.remainingDays)天")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.Neumorphic.main)
        .cornerRadius(15)
        .softOuterShadow()
        .opacity(goal.isCompleted ? 0.8 : 1.0)
    }
}

// 新建储蓄目标设置页面
struct NewSavingsGoalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var goalTitle = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                Form {
                    Section(header: Text("新储蓄目标信息")) {
                        TextField("新储蓄目标名称", text: $goalTitle)
                        TextField("新储蓄目标金额", text: $targetAmount)
                            .keyboardType(.decimalPad)
                        DatePicker("新储蓄目标日期", selection: $targetDate, in: Date()..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("新建储蓄目标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveGoal()
                    }
                    .disabled(goalTitle.isEmpty || targetAmount.isEmpty)
                }
            }
        }
    }
    
    private func saveGoal() {
        let newGoal = SavingsGoal(context: viewContext)
        newGoal.title = goalTitle
        newGoal.targetAmount = Double(targetAmount) ?? 0
        newGoal.currentAmount = 0.0
        newGoal.startDate = Date()
        newGoal.targetDate = targetDate
        newGoal.isCompleted = false
        newGoal.monthlyBudget = 0.0
        newGoal.monthlyAmount = Date() // 设置为当前日期，因为数据模型中是 Date 类型
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("保存储蓄目标失败: \(error)")
        }
    }
}

