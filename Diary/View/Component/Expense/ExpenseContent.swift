import SwiftUI
import Neumorphic
import CoreData

struct ExpenseContent: View {
    let item: Item
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            // 左侧：收入/支出
            Text(item.isExpense ? "支出" : "收入")
                .font(.system(size: 18))
            
            Spacer()
            
            // 右侧：金额、备注和时间
            VStack(alignment: .trailing, spacing: 8) {
                Text(String(format: "¥%.2f", item.amount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(item.isExpense ? .red : .green)
                
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let date = item.date {
                    HStack(spacing: 4) {
                        Text(date, style: .date)
                        Text(date, style: .time)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.Neumorphic.main)
        .cornerRadius(10)
        .softOuterShadow()
    }
}

#if DEBUG
struct ExpenseContent_Previews: PreviewProvider {
    static var previews: some View {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let item = Item(context: context)
        item.amount = 100
        item.isExpense = true
        item.date = Date()
        
        return ExpenseContent(item: item)
            .padding()
            .background(Color.Neumorphic.main)
    }
}
#endif
