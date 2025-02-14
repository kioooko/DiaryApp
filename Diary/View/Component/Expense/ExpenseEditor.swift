import SwiftUI
import Neumorphic

struct ExpenseEditor: View {
    @EnvironmentObject private var bannerState: BannerState
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var isExpense: Bool = true
    @State private var category: String = "其他"
    @State private var note: String = ""
    
    let categories = ["餐饮", "交通", "购物", "娱乐", "其他"]
    
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
                    
                    // 分类选择
                    Picker("分类", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // 备注输入
                    TextField("备注", text: $note)
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
        
        do {
            try ExpenseItem.create(
                amount: amountValue,
                isExpense: isExpense,
                category: category,
                note: note
            )
            dismiss()
            bannerState.show(of: .success(message: "记账成功"))
        } catch {
            bannerState.show(of: .error(message: "保存失败"))
        }
    }
}