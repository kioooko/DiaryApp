import SwiftUI
import Neumorphic

struct ExpenseEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bannerState: BannerState
    
    @StateObject private var budgetAlert = BudgetAlertManager()
    
    @State private var amount: String = ""
    @State private var isExpense: Bool = true
    @State private var note: String = ""
    
    var editingItem: Item?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == false"),
        animation: .default)
    private var goals: FetchedResults<SavingsGoal>
    
    init(editingItem: Item? = nil) {
        self.editingItem = editingItem
        if let item = editingItem {
            _amount = State(initialValue: String(format: "%.2f", item.amount))
            _isExpense = State(initialValue: item.isExpense)
            _note = State(initialValue: item.note ?? "")
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
                        
                        Button(editingItem == nil ? "保存" : "更新") {
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
            .navigationTitle(editingItem == nil ? "" : "编辑记账")
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
        .alert("预算提醒", isPresented: $budgetAlert.showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(budgetAlert.alertMessage)
        }
    }
    
    private func saveExpense() {
        let newAmount = (Double(amount) ?? 0) * (isExpense ? -1 : 1)
        
        if let editingItem = editingItem {
            editingItem.amount = newAmount
            editingItem.note = note
        } else {
            let newItem = Item(context: viewContext)
            //newItem.id = UUID()
            newItem.date = Date()
            newItem.amount = newAmount
            newItem.note = note
        }
        
        print("开始保存支出记录...")
        
        do {
            try viewContext.save()
            print("支出记录保存成功")
            
            if isExpense {
                print("检查预算状态...")
                if let alertMessage = budgetAlert.checkBudgetStatus(context: viewContext) {
                    print("需要显示预算提醒: \(alertMessage)")
                    budgetAlert.alertMessage = alertMessage
                    budgetAlert.showingAlert = true
                    
                    // 发送每日支出总结
                    print("发送每日支出总结...")
                    budgetAlert.sendDailyBudgetNotification(context: viewContext)
                } else {
                    print("无需显示预算提醒")
                }
            }
            
            dismiss()
        } catch {
            print("保存失败: \(error)")
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
