import SwiftUI
import CoreData
import Neumorphic

struct ExpenseStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showSavingsGoal = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@ AND date <= %@ AND amount != 0", 
                             Date().startOfDay as CVarArg,
                             Date().endOfDay as CVarArg)
    ) private var items: FetchedResults<Item>
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 添加储蓄目标卡片
                SavingsGoalCard()
                    .padding(.horizontal)
                
                List {
                    Section("今日收支") {
                        incomeRow
                        expenseRow
                        balanceRow
                    }

                    
                    Section("收支明细") {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(item.isExpense ? "支出" : "收入")
                                    Spacer()
                                    Text("¥\(item.amount, specifier: "%.2f")")
                                        .foregroundColor(item.isExpense ? .red : .green)
                                }
                                
                                if let note = item.note, !note.isEmpty {
                                    Text("备注：\(note)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                if let date = item.date {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.Neumorphic.main)
                    )
                }
                .scrollContentBackground(.hidden)
                .background(Color.Neumorphic.main)
            }
            .background(Color.Neumorphic.main)
            .navigationTitle("账单统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSavingsGoal = true
                    } label: {
                        Image(systemName: "target")
                        Text("储蓄目标")
                    }
                }
            }
            .sheet(isPresented: $showSavingsGoal) {
                SavingsGoalSettingView()
            }
        }
    }
    
    private var incomeRow: some View {
        HStack {
            Text("收入")
            Spacer()
            Text("¥\(calculateIncome(), specifier: "%.2f")")
                .foregroundColor(.green)
        }
    }
    
    private var expenseRow: some View {
        HStack {
            Text("支出")
            Spacer()
            Text("¥\(calculateExpense(), specifier: "%.2f")")
                .foregroundColor(.red)
        }
    }
    
    private var balanceRow: some View {
        let balance = calculateBalance()
        return HStack {
            Text("结余")
            Spacer()
            Text("¥\(balance, specifier: "%.2f")")
                .foregroundColor(balance >= 0 ? .green : .red)
        }
    }
    
    private func calculateIncome() -> Double {
        items.filter { !$0.isExpense }.map { $0.amount }.reduce(0, +)
    }
    
    private func calculateExpense() -> Double {
        items.filter { $0.isExpense }.map { $0.amount }.reduce(0, +)
    }
    
    private func calculateBalance() -> Double {
        calculateIncome() - calculateExpense()
    }
}

#if DEBUG
struct ExpenseStatsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        return ExpenseStatsView()
            .environment(\.managedObjectContext, context)
    }
}
#endif
