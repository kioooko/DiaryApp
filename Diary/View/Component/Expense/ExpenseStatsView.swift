import SwiftUI
import CoreData

struct ExpenseStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@ AND date <= %@ AND amount != 0", 
                             Date().startOfDay as CVarArg,
                             Date().endOfDay as CVarArg)
    ) private var items: FetchedResults<Item>
    
    var body: some View {
        NavigationView {
            VStack {
                summarySection
                recordsSection
            }
            .navigationTitle("记账统计")
            .background(Color.Neumorphic.main)
        }
    }
    
    private var summarySection: some View {
        List {
            Section("今日收支") {
                incomeRow
                expenseRow
                balanceRow
            }
        }
    }
    
    private var recordsSection: some View {
        ExpenseListView()
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
