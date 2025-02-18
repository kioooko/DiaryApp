import SwiftUI
import CoreData

struct SavingsGoalSettingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var goalTitle = ""
    @State private var targetAmount = ""
    @State private var targetDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("目标设置") {
                    TextField("目标名称", text: $goalTitle)
                    TextField("目标金额", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    DatePicker("目标日期", selection: $targetDate, displayedComponents: .date)
                }
            }
            .navigationTitle("储蓄目标")
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
                }
            }
        }
    }
    
    private func saveGoal() {
        guard let amount = Double(targetAmount), amount > 0 else { return }
        
        let goal = SavingsGoal(context: viewContext)
        goal.title = goalTitle
        goal.targetAmount = amount
        goal.startDate = Date()
        goal.targetDate = targetDate
        
        try? viewContext.save()
        dismiss()
    }
} 
