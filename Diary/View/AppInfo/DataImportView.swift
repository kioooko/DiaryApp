import SwiftUI
import UniformTypeIdentifiers
import CoreData
import UIKit

struct DataImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Button(action: { showingDocumentPicker = true }) {
            Label("导入数据", systemImage: "square.and.arrow.down")
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(completion: importData)
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    private func importData(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let jsonData = jsonData else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的数据格式"])
            }
            
            try viewContext.performAndWait {
                // 清除现有数据
                try deleteAllEntities()
                
                // 导入分类
                if let categories = jsonData["categories"] as? [[String: Any]] {
                    for categoryData in categories {
                        let category = Category(context: viewContext)
                        category.id = UUID(uuidString: categoryData["id"] as? String ?? "") ?? UUID()
                        category.name = categoryData["name"] as? String
                        category.icon = categoryData["icon"] as? String
                        category.color = categoryData["color"] as? String
                        category.type = categoryData["type"] as? String
                    }
                }
                
                // 导入记录
                if let items = jsonData["items"] as? [[String: Any]] {
                    for itemData in items {
                        let item = Item(context: viewContext)
                        item.id = UUID(uuidString: itemData["id"] as? String ?? "") ?? UUID()
                        item.amount = itemData["amount"] as? Double ?? 0.0
                        item.date = itemData["date"] as? Date ?? Date()
                        item.note = itemData["note"] as? String
                        item.type = itemData["type"] as? String
                        
                        // 关联分类
                        if let categoryID = itemData["categoryID"] as? String {
                            let request: NSFetchRequest<Category> = Category.fetchRequest()
                            request.predicate = NSPredicate(format: "id == %@", categoryID)
                            item.category = try viewContext.fetch(request).first
                        }
                    }
                }
                
                // 导入储蓄目标
                if let goals = jsonData["savingsGoals"] as? [[String: Any]] {
                    for goalData in goals {
                        let goal = SavingsGoal(context: viewContext)
                        goal.id = UUID(uuidString: goalData["id"] as? String ?? "") ?? UUID()
                        goal.startDate = goalData["startDate"] as? Date ?? Date()
                        goal.targetDate = goalData["targetDate"] as? Date ?? Date()
                        goal.targetAmount = goalData["targetAmount"] as? Double ?? 0.0
                        goal.monthlyAmount = goalData["monthlyAmount"] as? Double ?? 0.0
                        goal.note = goalData["note"] as? String
                        goal.isCompleted = goalData["isCompleted"] as? Bool ?? false
                    }
                }
                
                try viewContext.save()
                alertMessage = "数据导入成功"
            }
        } catch {
            print("导入数据失败: \(error)")
            alertMessage = "导入数据失败：\(error.localizedDescription)"
        }
        showingAlert = true
    }
    
    private func deleteAllEntities() throws {
        // 删除所有记录
        let itemRequest: NSFetchRequest<NSFetchRequestResult> = Item.fetchRequest()
        let itemDelete = NSBatchDeleteRequest(fetchRequest: itemRequest)
        try viewContext.execute(itemDelete)
        
        // 删除所有分类
        let categoryRequest: NSFetchRequest<NSFetchRequestResult> = Category.fetchRequest()
        let categoryDelete = NSBatchDeleteRequest(fetchRequest: categoryRequest)
        try viewContext.execute(categoryDelete)
        
        // 删除所有储蓄目标
        let goalRequest: NSFetchRequest<NSFetchRequestResult> = SavingsGoal.fetchRequest()
        let goalDelete = NSBatchDeleteRequest(fetchRequest: goalRequest)
        try viewContext.execute(goalDelete)
    }
}

// 文档选择器
struct DocumentPicker: UIViewControllerRepresentable {
    let completion: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (URL) -> Void
        
        init(completion: @escaping (URL) -> Void) {
            self.completion = completion
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            completion(url)
        }
    }
}

    }()
}

// 📌 `importedCount` 是导入的联系人数量，而不是总记录数。
