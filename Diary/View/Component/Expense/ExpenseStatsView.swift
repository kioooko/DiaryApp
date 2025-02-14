import SwiftUI
import Charts

struct ExpenseStatsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ExpenseItem.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@ AND date <= %@", 
                             Date().startOfDay as CVarArg,
                             Date().endOfDay as CVarArg)
    ) private var items: FetchedResults<ExpenseItem>
    
    var body: some View {
        List {
            // 今日统计
            Section("今日收支") {
                HStack {
                    Text("收入")
                    Spacer()
                    Text("¥\(todayIncome, specifier: "%.2f")")
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("支出")
                    Spacer()
                    Text("¥\(todayExpense, specifier: "%.2f")")
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("结余")
                    Spacer()
                    Text("¥\(todayBalance, specifier: "%.2f")")
                        .foregroundColor(todayBalance >= 0 ? .green : .red)
                }
            }
            
            // 支出饼图
            Section("支出分布") {
                if !expenseData.isEmpty {
                    Chart(expenseData) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", item.category))
                    }
                    .frame(height: 200)
                } else {
                    Text("暂无支出数据")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var todayIncome: Double {
        items.filter { !$0.isExpense }.map { $0.amount }.reduce(0, +)
    }
    
    private var todayExpense: Double {
        items.filter { $0.isExpense }.map { $0.amount }.reduce(0, +)
    }
    
    private var todayBalance: Double {
        todayIncome - todayExpense
    }
    
    private var expenseData: [ExpenseChartData] {
        Dictionary(grouping: items.filter { $0.isExpense }) { $0.category ?? "其他" }
            .map { category, items in
                ExpenseChartData(
                    category: category,
                    amount: items.map { $0.amount }.reduce(0, +)
                )
            }
            .filter { $0.amount > 0 }
    }
}

struct ExpenseChartData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}