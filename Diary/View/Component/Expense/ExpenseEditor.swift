import SwiftUI
import Neumorphic
import CoreData

struct ExpenseEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bannerState: BannerState
    
    @StateObject private var budgetAlert = BudgetAlertManager()
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var date = Date()
    @State private var isExpense = true
    
    var item: Item?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == false"),
        animation: .default)
    private var goals: FetchedResults<SavingsGoal>
    
    init(item: Item? = nil) {
        self.item = item
        if let item = item {
            _amount = State(initialValue: String(format: "%.2f", item.amount))
            _isExpense = State(initialValue: item.isExpense)
            _note = State(initialValue: item.note ?? "")
            _date = State(initialValue: item.date ?? Date())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // 添加储蓄目标卡片
                    if let currentGoal = goals.first {
                        SavingsGoalCard(goal: currentGoal)
                    }
                    
                    // 收入/支出选择
                    VStack(spacing: 10) {
                        HStack {
                            Text("支出")
                            Spacer()
                            Toggle(isOn: Binding(
                                get: { isExpense },
                                set: { newValue in
                                    if newValue {
                                        isExpense = true
                                    }
                                }
                            )) {
                                EmptyView()
                            }
                            .labelsHidden()
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("收入")
                            Spacer()
                            Toggle(isOn: Binding(
                                get: { !isExpense },
                                set: { newValue in
                                    if newValue {
                                        isExpense = false
                                    }
                                }
                            )) {
                                EmptyView()
                            }
                            .labelsHidden()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                    
                    // 金额输入
                    HStack {
                        Text(isExpense ? "-" : "+")
                            .foregroundColor(isExpense ? .red : .green)
                        TextField("金额", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Color.Neumorphic.main)
                    .cornerRadius(10)
                    .softOuterShadow()
                    
                    // 备注输入
                    TextField("添加备注", text: $note)
                        .padding()
                        .background(Color.Neumorphic.main)
                        .cornerRadius(10)
                        .softOuterShadow()
                    
                    Spacer()
                    
                    // 底部按钮
                    HStack(spacing: 20) {
                        Button("取消") {
                            dismiss()
                        }
                        .softButtonStyle(RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: .infinity)
                        
                        Button("保存") {
                            saveExpense()
                        }
                        .softButtonStyle(RoundedRectangle(cornerRadius: 10))
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 140)
                }
                .padding()
            }
            .navigationTitle(item == nil ? "" : "编辑记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EmptyView()
                }
            }
            .padding(.top, 20)
            .background(Color.Neumorphic.main)
        }
        .alert(budgetAlert.alertTitle, isPresented: $budgetAlert.showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(budgetAlert.alertMessage)
        }
    }
    
    private func saveExpense() {
        withAnimation {
            let amountValue = Double(amount) ?? 0
            let finalAmount = isExpense ? -abs(amountValue) : abs(amountValue)
            
            if let item = item {
                // 编辑现有支出
                if item.id == nil {
                    item.id = UUID()
                }
                item.amount = finalAmount
                item.note = note
                item.date = date
                item.updatedAt = Date()
            } else {
                // 创建新支出
                let newItem = Item(context: viewContext)
                newItem.id = UUID()  // 确保设置新的 UUID
                newItem.amount = finalAmount
                newItem.note = note
                newItem.date = date
                newItem.createdAt = Date()
                newItem.updatedAt = Date()
            }
            
            do {
                try viewContext.save()
                print("支出记录保存成功")
                
                // 检查预算状态
                if isExpense {
                    if let budgetMessage = budgetAlert.checkBudgetStatus(context: viewContext) {
                        budgetAlert.showAlert(title: "预算提醒", message: budgetMessage)
                    }
                }
                
                // 检查储蓄目标完成状态
                let goalRequest = NSFetchRequest<SavingsGoal>(entityName: "SavingsGoal")
                goalRequest.predicate = NSPredicate(format: "isCompleted == false")
                
                if let currentGoal = try? viewContext.fetch(goalRequest).first {
                    print("检查储蓄目标完成状态...")
                    if let completionMessage = budgetAlert.checkSavingsGoalCompletion(goal: currentGoal, context: viewContext) {
                        print("显示储蓄目标完成提示")
                        budgetAlert.showAlert(title: "储蓄目标", message: completionMessage)
                    }
                }
                
                dismiss()
            } catch let error as NSError {
                print("保存支出失败: \(error), \(error.userInfo)")
            }
        }
    }
}

#if DEBUG
struct ExpenseEditor_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseEditor()
            .environmentObject(BannerState())
    }
}
#endif
