import SwiftUI
import CoreData

// SavingsGoal 扩展
extension SavingsGoal {
    var progress: Double {
        return currentAmount / targetAmount
    }
    
    var remainingDays: Int {
        guard let targetDate = targetDate else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return components.day ?? 0
    }
}

struct SavingsGoalSettingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)],
        animation: .default)
    private var goals: FetchedResults<SavingsGoal>
    
    @State private var goalTitle = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date()
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: SavingsGoal? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 目标设置表单
                        VStack(spacing: 20) {
                            Section("新储蓄目标设置") {
                                TextField("储蓄目标名称", text: $goalTitle)
                                TextField("储蓄目标金额", text: $targetAmount)
                                    .keyboardType(.decimalPad)
                                DatePicker("预计完成目标日期", selection: $targetDate, displayedComponents: .date)
                            }
                        }
                        .padding()
                        
                        // 取消和保存按钮
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
                        
                        // 已保存的目标列表
                        if !goals.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("进行中的目标")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(goals) { goal in
                                    VStack(spacing: 12) {
                                        HStack {
                                            Text(goal.title ?? "未命名目标")
                                                .font(.subheadline)
                                            Spacer()
                                            Text("¥\(Int(goal.targetAmount))")
                                                .font(.subheadline)
                                            
                                            // 删除按钮
                                            Button {
                                                goalToDelete = goal
                                                showingDeleteAlert = true
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.gray)
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
                            }
                        }
                    }
                }
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
