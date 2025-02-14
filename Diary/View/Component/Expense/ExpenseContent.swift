import SwiftUI
import Neumorphic
import CoreData

struct ExpenseContent: View {
    let item: Item
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(item.isExpense ? "支出" : "收入")
                    .font(.system(size: 18))
                Spacer()
                Text(String(format: "¥%.2f", item.amount))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(item.isExpense ? .red : .green)
            }
            
            if let date = item.date {
                HStack {
                      Spacer()
                    Text("记录时间：")
                        .foregroundColor(.gray)
                    Text(date, style: .date)
                        .foregroundColor(.gray)
                    Text(date, style: .time)
                        .foregroundColor(.gray)
                }
                .font(.caption)
            }
            
            if let body = item.body, !body.isEmpty {
                Text(body)
                    .font(.subheadline)
                    .foregroundColor(.gray)
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
