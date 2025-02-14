import SwiftUI
import Neumorphic

struct ExpenseEditor: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bannerState: BannerState
    
    @State private var amount: String = ""
    @State private var isExpense: Bool = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // 收入/支出选择
                    Picker("类型", selection: $isExpense) {
                        Text("支出").tag(true)
                        Text("收入").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
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
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveExpense()
                    }
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            bannerState.show(of: .error(message: "请输入有效金额"))
            return
        }
        
        let item = Item(context: viewContext)
        item.amount = amountValue
        item.isExpense = isExpense
        item.date = Date()
        item.createdAt = Date()
        item.updatedAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
            bannerState.show(of: .success(message: "记账成功"))
        } catch {
            bannerState.show(of: .error(message: "保存失败"))
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