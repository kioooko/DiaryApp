import SwiftUI
import UniformTypeIdentifiers
import CoreData
import UIKit

struct DataImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bannerState: BannerState
    @State private var isImporting: Bool = false
    @State private var importProgress: Double = 0
    @State private var selectedFile: URL?
    @State private var isDropTargeted: Bool = false
    @State private var importedCount = 0
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color.Neumorphic.main
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(isDropTargeted ? .blue : .gray)
                        .frame(height: 200)
                    
                    VStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 30))
                        Text("拖拽文件到这里或点击选择")
                            .padding(.top, 8)
                        Text("支持的格式：CSV、TXT")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 40)
                .onTapGesture {
                    isImporting = true
                }
                .onDrop(
                    of: [.text, .plainText, .utf8PlainText, .commaSeparatedText],
                    isTargeted: $isDropTargeted
                ) { providers in
                    print("📝 接收到拖拽项目")
                    guard let provider = providers.first else { return false }
                    
                    // 打印支持的类型
                    print("📝 提供者支持的类型：")
                    provider.registeredTypeIdentifiers.forEach { print("- \($0)") }
                    
                    // 尝试不同的类型标识符
                    let typeIdentifiers = [
                        UTType.plainText.identifier,
                        UTType.utf8PlainText.identifier,
                        UTType.text.identifier,
                        UTType.commaSeparatedText.identifier,
                        "public.data",
                        "public.content"
                    ]
                    
                    for identifier in typeIdentifiers {
                        if provider.hasItemConformingToTypeIdentifier(identifier) {
                            print("📝 尝试加载类型: \(identifier)")
                            provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, error in
                                if let error = error {
                                    print("❌ 加载类型 \(identifier) 失败: \(error)")
                                    return
                                }
                                
                                guard let data = data else {
                                    print("❌ 类型 \(identifier) 数据为空")
                                    return
                                }
                                
                                if let content = String(data: data, encoding: .utf8) {
                                    print("✅ 成功读取文件内容（类型：\(identifier)）")
                                    DispatchQueue.main.async {
                                        importCSVData(content)
                                    }
                                    return
                                } else {
                                    print("❌ 无法将数据转换为字符串（类型：\(identifier)）")
                                }
                            }
                            return true
                        }
                    }
                    
                    print("❌ 未找到支持的文件类型")
                    return false
                }

                if isImporting {
                    FilePicker(isPresented: $isImporting, selectedFile: $selectedFile) { url in
                        if let url = url {
                            handleFileSelection(url)
                        }
                    }
                }

                if let selectedFile = selectedFile {
                    Text("已选择文件：\(selectedFile.lastPathComponent)")
                        .padding()
                }
                
                if importProgress > 0 {
                    ProgressView("导入中...", value: importProgress, total: 1.0)
                        .padding()
                }
            }
        }
        .navigationTitle("导入日记数据")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("导入结果"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    private func handleFileSelection(_ url: URL) {
        print("📝 处理文件: \(url)")
        let fileExtension = url.pathExtension.lowercased()
        
        guard fileExtension == "csv" || fileExtension == "txt" else {
            print("❌ 不支持的文件格式: \(fileExtension)")
            bannerState.show(of: .error(message: "不支持的文件格式，请选择 CSV 或 TXT 文件"))
            return
        }
        
        selectedFile = url
        importData(fileURL: url)
    }
    
    private func importData(fileURL: URL) {
        isImporting = true
        importProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
                importCSVData(fileContent)
            } catch {
                print("❌ 导入失败: \(error)")
                DispatchQueue.main.async {
                    isImporting = false
                    selectedFile = nil
                    importProgress = 0
                    bannerState.show(of: .error(message: "导入失败：\(error.localizedDescription)"))
                }
            }
        }
    }
    
    private func importCSVData(_ content: String) {
        let sections = content.components(separatedBy: "=== ")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var totalImported = 0
        var currentSection = ""
        var headers: [String] = []
        var rows: [String] = []
        
        viewContext.performAndWait {
            for section in sections {
                let lines = section.components(separatedBy: .newlines)
                guard !lines.isEmpty else { continue }
                
                currentSection = lines[0].replacingOccurrences(of: " ===", with: "")
                headers = lines[1].components(separatedBy: ",")
                rows = Array(lines.dropFirst(2))
                
                switch currentSection {
                case "日记数据":
                    importDiaryData(headers: headers, rows: rows)
                case "储蓄目标数据":
                    importSavingsGoalData(headers: headers, rows: rows)
                case "联系人数据":
                    importContactData(headers: headers, rows: rows)
                case "支出数据":
                    importExpenseData(headers: headers, rows: rows)
                case "待办事项数据":
                    importCheckListItemData(headers: headers, rows: rows)
                default:
                    print("⚠️ 未知的数据类型: \(currentSection)")
                }
                
                totalImported += rows.count
                
                // 每处理50条记录保存一次
                if totalImported % 50 == 0 {
                    saveContext()
                }
            }
            
            // 最后保存一次
            saveContext()
            
            // 完成导入
            DispatchQueue.main.async {
                isImporting = false
                selectedFile = nil
                importProgress = 0
                bannerState.show(of: .success(message: "成功导入 \(totalImported) 条记录"))
            }
        }
    }
    
    private func importDiaryData(headers: [String], rows: [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            guard columns.count == headers.count else { continue }
            
            let entry = Item(context: viewContext)
            
            for (index, header) in headers.enumerated() {
                let value = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch header {
                case "标题":
                    entry.title = value
                case "内容":
                    entry.body = value
                case "日期":
                    if let date = dateFormatter.date(from: value) {
                        entry.date = date
                    }
                case "天气":
                    entry.weather = value
                case "是否收藏":
                    entry.isBookmarked = value == "是"
                case "图片":
                    if !value.isEmpty, let imageData = Data(base64Encoded: value) {
                        entry.imageData = imageData
                    }
                case "创建时间":
                    if let date = dateFormatter.date(from: value) {
                        entry.createdAt = date
                    }
                case "更新时间":
                    if let date = dateFormatter.date(from: value) {
                        entry.updatedAt = date
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func importSavingsGoalData(headers: [String], rows: [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            guard columns.count == headers.count else { continue }
            
            let goal = SavingsGoal(context: viewContext)
            
            for (index, header) in headers.enumerated() {
                let value = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch header {
                case "标题":
                    goal.title = value
                case "目标金额":
                    goal.targetAmount = Double(value) ?? 0.0
                case "当前金额":
                    goal.currentAmount = Double(value) ?? 0.0
                case "截止日期":
                    if let date = dateFormatter.date(from: value) {
                        goal.targetDate = date
                    }
                case "创建时间":
                    if let date = dateFormatter.date(from: value) {
                        goal.createdAt = date
                    }
                case "更新时间":
                    if let date = dateFormatter.date(from: value) {
                        goal.updatedAt = date
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func importContactData(headers: [String], rows: [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            guard columns.count == headers.count else { continue }
            
            let contact = Contact(context: viewContext)
            
            for (index, header) in headers.enumerated() {
                let value = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch header {
                case "姓名":
                    contact.name = value
                case "关系层级":
                    contact.tier = Int16(value) ?? 0
                case "生日":
                    if let date = dateFormatter.date(from: value) {
                        contact.birthday = date
                    }
                case "备注":
                    contact.notes = value
                case "最近联系时间":
                    if let date = dateFormatter.date(from: value) {
                        contact.lastInteraction = date
                    }
                case "头像":
                    if !value.isEmpty, let imageData = Data(base64Encoded: value) {
                        contact.avatar = imageData
                    }
                case "创建时间":
                    if let date = dateFormatter.date(from: value) {
                        contact.createdAt = date
                    }
                case "更新时间":
                    if let date = dateFormatter.date(from: value) {
                        contact.updatedAt = date
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func importExpenseData(headers: [String], rows: [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            guard columns.count == headers.count else { continue }
            
            let expense = Expense(context: viewContext)
            
            for (index, header) in headers.enumerated() {
                let value = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch header {
                case "标题":
                    expense.title = value
                case "金额":
                    expense.amount = Double(value) ?? 0.0
                case "是否支出":
                    expense.isExpense = value == "是"
                case "日期":
                    if let date = dateFormatter.date(from: value) {
                        expense.date = date
                    }
                case "备注":
                    expense.note = value
                case "联系人":
                    // 查找或创建联系人
                    let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "name == %@", value)
                    if let contact = try? viewContext.fetch(fetchRequest).first {
                        expense.contact = contact
                    }
                case "创建时间":
                    if let date = dateFormatter.date(from: value) {
                        expense.createdAt = date
                    }
                case "更新时间":
                    if let date = dateFormatter.date(from: value) {
                        expense.updatedAt = date
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func importCheckListItemData(headers: [String], rows: [String]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for row in rows {
            let columns = row.components(separatedBy: ",")
            guard columns.count == headers.count else { continue }
            
            let item = CheckListItem(context: viewContext)
            
            for (index, header) in headers.enumerated() {
                let value = columns[index].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch header {
                case "标题":
                    item.title = value
                case "是否完成":
                    item.isCompleted = value == "是"
                case "日记":
                    // 查找对应的日记
                    let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "title == %@", value)
                    if let diary = try? viewContext.fetch(fetchRequest).first {
                        // 创建新的 NSSet 并添加 item
                        let checkListItems = NSMutableSet()
                        checkListItems.add(item)
                        diary.checkListItems = checkListItems
                    }
                case "创建时间":
                    if let date = dateFormatter.date(from: value) {
                        item.createdAt = date
                    }
                case "更新时间":
                    if let date = dateFormatter.date(from: value) {
                        item.updatedAt = date
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("❌ 保存失败: \(error)")
            bannerState.show(of: .error(message: "保存失败：\(error.localizedDescription)"))
        }
    }
}

// 添加 FilePicker 实现
struct FilePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedFile: URL?
    let onFileSelected: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [String] = ["public.comma-separated-values-text", "public.plain-text"]
        let picker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePicker
        
        init(_ parent: FilePicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("📝 选择文件：\(urls)")
            if let url = urls.first {
                DispatchQueue.main.async {
                    self.parent.selectedFile = url
                    self.parent.onFileSelected(url)
                    self.parent.isPresented = false
                }
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("📝 取消选择")
            DispatchQueue.main.async {
                self.parent.isPresented = false
                self.parent.onFileSelected(nil)
            }
        }
    }
}

// 添加 DateFormatter 扩展
private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

// 📌 `importedCount` 是导入的联系人数量，而不是总记录数。
