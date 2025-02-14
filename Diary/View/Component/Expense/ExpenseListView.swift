import SwiftUI
import Neumorphic

struct ExpenseListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.date, ascending: false)],
        predicate: NSPredicate(format: "amount != 0")
    ) private var items: FetchedResults<Item>
    
    var body: some View {
        List {
            ForEach(items) { item in
                ExpenseContent(item: item)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 4)
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
