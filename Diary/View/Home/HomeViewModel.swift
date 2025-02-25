import SwiftUI
import CoreData

class HomeViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var diaryListInterval: DateInterval = Date.currentMonthInterval ?? DateInterval(start: Date(), end: Date())
    @Published var dateItemCount: [Date: Int] = [:]
    
    private let calendar = Calendar.current
    
    func loadItems(of dateInterval: DateInterval, in context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ && date <= %@",
            dateInterval.start as CVarArg,
            dateInterval.end as CVarArg
        )
        
        do {
            let fetchedItems = try context.fetch(fetchRequest)
            var countDict: [Date: Int] = [:]
            
            for item in fetchedItems {
                guard let date = item.date else { continue }
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                guard let startOfDay = calendar.date(from: components) else { continue }
                
                if let count = countDict[startOfDay] {
                    countDict[startOfDay] = count + 1
                } else {
                    countDict[startOfDay] = 1
                }
            }
            
            self.dateItemCount = countDict
        } catch {
            print("⚠️ 加载数据失败: \(error)")
        }
    }
} 