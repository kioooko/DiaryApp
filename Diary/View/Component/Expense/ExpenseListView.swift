import SwiftUI
import Neumorphic

struct ExpenseListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date, ascending: false)],
        predicate: NSPredicate(format: "amount != 0")
    ) private var items: FetchedResults<Item>
    
    private func formatAmount(_ item: Item) -> (String, Color) {
        let amount = abs(item.amount)
        let formattedAmount = String(format: "¥%.2f", amount)
        
        // 根据金额正负判断类型和颜色
        if item.amount < 0 {
            return ("-" + formattedAmount, .red) // 支出显示为红色
        } else {
            return (formattedAmount, .green) // 收入显示为绿色
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    var body: some View {
        List {
            ForEach(items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.amount < 0 ? "支出" : "收入")
                            .font(.headline)
                        if let note = item.note, !note.isEmpty {
                            Text(note)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Text(formatDate(item.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    let (formattedAmount, color) = formatAmount(item)
                    Text(formattedAmount)
                        .foregroundColor(color)
                        .font(.headline)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.Neumorphic.main)
    }
}

#if DEBUG
struct ExpenseListView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseListView()
    }
}
#endif 
