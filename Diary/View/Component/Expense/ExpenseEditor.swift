import SwiftUI
import Neumorphic

struct ExpenseEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bannerState: BannerState
    
    @State private var amount: String = ""
    @State private var isExpense: Bool = true
    @State private var note: String = ""
    
    var editingItem: Item?
    
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
            .navigationTitle(editingItem == nil ? "记账" : "编辑记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EmptyView()
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            bannerState.show(of: .error(message: "请输入有效金额"))
            return
        }
        
        if let item = editingItem {
            // 更新现有记录
            item.amount = amountValue
            item.isExpense = isExpense
            item.note = note
            item.updatedAt = Date()
        } else {
            // 创建新记录
            let item = Item(context: viewContext)
            item.amount = amountValue
            item.isExpense = isExpense
            item.note = note
            item.date = Date()
            item.createdAt = Date()
            item.updatedAt = Date()
        }
        
        do {
            try viewContext.save()
            dismiss()
            bannerState.show(of: .success(message: editingItem == nil ? "记账成功" : "更新成功"))
        } catch {
            bannerState.show(of: .error(message: editingItem == nil ? "保存失败" : "更新失败"))
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