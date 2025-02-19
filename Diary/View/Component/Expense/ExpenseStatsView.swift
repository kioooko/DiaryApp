import SwiftUI
import CoreData
import Neumorphic

struct ExpenseStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showSavingsGoal = false
    
    @FetchRequest private var items: FetchedResults<Item>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == false"),
        animation: .default)
    private var goals: FetchedResults<SavingsGoal>
    
    init() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            fatalError("无法计算月份日期范围")
        }
        
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.date, ascending: false)]
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@ AND amount != 0",
            startOfMonth as CVarArg,
            endOfMonth as CVarArg
        )
        
        _items = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 修改储蓄目标卡片的显示逻辑
                if let currentGoal = goals.first {
                    SavingsGoalCard(goal: currentGoal)
                        .padding(.horizontal)
                }
                
                List {
                    Section("月度收支") {
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
            .navigationTitle("记账本")
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
            Text("¥\(calculateMonthlyIncome(), specifier: "%.2f")")
                .foregroundColor(.green)
        }
    }
    
    private var expenseRow: some View {
        HStack {
            Text("支出")
            Spacer()
            Text("¥\(calculateMonthlyExpense(), specifier: "%.2f")")
                .foregroundColor(.red)
        }
    }
    
    private var balanceRow: some View {
        let balance = calculateMonthlyBalance()
        return HStack {
            Text("结余")
            Spacer()
            Text("¥\(balance, specifier: "%.2f")")
                .foregroundColor(balance >= 0 ? .green : .red)
        }
    }
    
    private func calculateMonthlyIncome() -> Double {
        items.filter { $0.amount > 0 }.map { $0.amount }.reduce(0, +)
    }
    
    private func calculateMonthlyExpense() -> Double {
        items.filter { $0.amount < 0 }.map { $0.amount }.reduce(0, +)
    }
    
    private func calculateMonthlyBalance() -> Double {
        items.map { $0.amount }.reduce(0, +)
    }
    
    private var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: Date())
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
