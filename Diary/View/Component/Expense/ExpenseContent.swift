import SwiftUI
import Neumorphic

struct ExpenseContent: View {
    @ObservedObject var item: ExpenseItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.category ?? "其他")
                    .font(.system(size: 18))
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            Text(String(format: "%.2f", item.amount))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(item.isExpense ? .red : .green)
        }
        .padding()
        .background(Color.Neumorphic.main)
        .cornerRadius(10)
        .softOuterShadow()
    }
}
