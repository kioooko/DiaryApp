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
                let lines = fileContent.components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
                
                print("📝 开始导入，总行数: \(lines.count)")
                
                DispatchQueue.main.async {
                    for (index, line) in lines.enumerated() {
                        let components = line.components(separatedBy: ",")
                        guard components.count >= 2 else { continue }
                        
                        let item = Item(context: viewContext)
                        
                        // 设置日期
                        if let date = DateFormatter.yyyyMMdd.date(from: components[0].trimmingCharacters(in: .whitespaces)) {
                            item.date = date
                            item.createdAt = date
                            item.updatedAt = date
                        } else {
                            item.date = Date()
                            item.createdAt = Date()
                            item.updatedAt = Date()
                        }
                        
                        // 设置内容
                        let content = components[1].trimmingCharacters(in: .whitespaces)
                        item.body = content
                        
                        // 设置标题（取内容前10个字符）
                        item.title = String(content.prefix(10))
                        
                        // 设置其他默认值
                        item.isBookmarked = false
                        
                        // 更新进度
                        importProgress = Double(index + 1) / Double(lines.count)
                        
                        // 每处理50条记录保存一次
                        if (index + 1) % 50 == 0 {
                            saveContext()
                        }
                    }
                    
                    // 最后保存一次
                    saveContext()
                    
                    // 完成导入
                    isImporting = false
                    selectedFile = nil
                    importProgress = 0
                    bannerState.show(of: .success(message: "成功导入 \(lines.count) 条日记"))
                }
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
        let rows = content.components(separatedBy: .newlines)
        guard rows.count > 1 else { return }
        
        let headers = rows[0].components(separatedBy: ",")
        print("📝 CSV表头: \(headers)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var importedCount = 0
        var failedCount = 0
        
        // 使用批量插入来提高性能
        viewContext.performAndWait {
            for row in rows.dropFirst() where !row.isEmpty {
                let columns = row.components(separatedBy: ",")
                guard columns.count == headers.count else { continue }
                
                // 创建数据字典
                var rowData: [String: String] = [:]
                for (index, header) in headers.enumerated() {
                    rowData[header] = columns[index]
                }
                
                // 日记数据处理
                let entry = Item(context: viewContext)
                entry.title = (rowData["标题"]?.isEmpty ?? true) ? "未命名记录" : rowData["标题"]
                entry.body = rowData["内容"]
                
                // 处理日期
                if let dateStr = rowData["日期"], let date = dateFormatter.date(from: dateStr) {
                    entry.date = date
                } else {
                    entry.date = Date()
                }
                
                // 处理数值
                entry.amount = Double(rowData["金额"] ?? "0") ?? 0.0
                entry.isExpense = (rowData["是否支出"] ?? "否") == "是"
                
                // 处理其他文本字段
                entry.note = rowData["备注"]
                entry.weather = rowData["天气"]
                entry.isBookmarked = (rowData["是否收藏"] ?? "否") == "是"
                
                // 处理图片数据
                if let imageStr = rowData["图片"], !imageStr.isEmpty {
                    if let imageData = Data(base64Encoded: imageStr) {
                        entry.imageData = imageData
                    }
                }
                
                // 处理待办事项
                if let checkListStr = rowData["待办事项"], !checkListStr.isEmpty {
                    let items = checkListStr.components(separatedBy: "|")
                    for item in items {
                        let checkItem = CheckListItem(context: viewContext)
                        let isCompleted = item.hasPrefix("[✓]")
                        let title = item.replacingOccurrences(of: "[✓] ", with: "")
                                       .replacingOccurrences(of: "[ ] ", with: "")
                        checkItem.title = title
                        checkItem.isCompleted = isCompleted
                      //  checkItem.item = entry
                        checkItem.createdAt = Date()
                        checkItem.updatedAt = Date()
                    }
                }
                
                // 处理时间戳
                if let createdStr = rowData["创建时间"], let created = dateFormatter.date(from: createdStr) {
                    entry.createdAt = created
                } else {
                    entry.createdAt = Date()
                }
                
                if let updatedStr = rowData["更新时间"], let updated = dateFormatter.date(from: updatedStr) {
                    entry.updatedAt = updated
                } else {
                    entry.updatedAt = Date()
                }
                
                importedCount += 1  // 计数日记数据
                
                // 联系人数据处理
                if rowData["联系人姓名"] != nil {
                    let contact = Contact(context: viewContext)
                    contact.id = UUID()
                    contact.name = rowData["联系人姓名"] ?? "未命名"
                    contact.tier = Int16(rowData["关系层级"] ?? "3") ?? 3
                    
                    if let birthdayStr = rowData["生日"],
                       let birthday = dateFormatter.date(from: birthdayStr) {
                        contact.birthday = birthday
                    }
                    
                    contact.notes = rowData["备注"]
                    
                    if let lastInteractionStr = rowData["最近联系时间"],
                       let lastInteraction = dateFormatter.date(from: lastInteractionStr) {
                        contact.lastInteraction = lastInteraction
                    }
                    
                    if let avatarStr = rowData["头像"],
                       let avatarData = Data(base64Encoded: avatarStr) {
                        contact.avatar = avatarData
                    }
                    
                    contact.createdAt = Date()
                    contact.updatedAt = Date()
                    
                    importedCount += 1  // 计数联系人数据
                }
                
                // 每处理50条记录保存一次
                if (importedCount + 1) % 50 == 0 {
                    saveContext()
                }
            }
            
            // 最后保存一次
            saveContext()
            
            // 完成导入
            bannerState.show(of: .success(message: "成功导入 \(importedCount) 条记录"))
        }
    }
    
    private func showImportResult(success: Bool, message: String) {
        DispatchQueue.main.async {
            // 即使有验证错误，只要有成功导入的记录就显示成功信息
            if importedCount > 0 {
                alertMessage = "成功导入 \(importedCount) 条记录"
            } else {
                alertMessage = message
            }
            showAlert = true
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

    private func exportCSVData() -> String {
        // 添加日期格式化器
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter
        }()
        
        var csvContent = ""
        
        // 1. 日记数据表
        csvContent += "=== 日记数据 ===\n"
        csvContent += "标题,内容,日期,金额,是否支出,备注,天气,是否收藏,图片,待办事项,创建时间,更新时间\n"
        let itemRequest: NSFetchRequest<Item> = Item.fetchRequest()
        if let items = try? viewContext.fetch(itemRequest) {
            for item in items {
                // ... 现有的日记导出代码 ...
            }
        }
        csvContent += "\n\n"
        
        // 2. 联系人数据表
        csvContent += "=== 联系人数据 ===\n"
        csvContent += "姓名,关系层级,生日,备注,最近联系时间,头像,创建时间,更新时间\n"
        let contactRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        if let contacts = try? viewContext.fetch(contactRequest) {
            for contact in contacts {
                let birthdayStr = contact.birthday.map { dateFormatter.string(from: $0) } ?? ""
                let lastInteractionStr = contact.lastInteraction.map { dateFormatter.string(from: $0) } ?? ""
                let avatarStr = contact.avatar.map { $0.base64EncodedString() } ?? ""
                
                let row = [
                    contact.name ?? "",
                    String(contact.tier),
                    birthdayStr,
                    contact.notes ?? "",
                    lastInteractionStr,
                    avatarStr,
                //    dateFormatter.string(from: contact.createdAt),
                //   dateFormatter.string(from: contact.updatedAt)
                ].map { "\"\($0)\"" }.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        csvContent += "\n\n"
        
        // 3. 储蓄目标数据表
        csvContent += "=== 储蓄目标数据 ===\n"
        csvContent += "标题,目标金额,当前金额,开始日期,目标日期,创建时间,更新时间\n"
        let goalRequest: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        if let goals = try? viewContext.fetch(goalRequest) {
            for goal in goals {
                let startDateStr = goal.startDate.map { dateFormatter.string(from: $0) } ?? ""
                let targetDateStr = goal.targetDate.map { dateFormatter.string(from: $0) } ?? ""
                let createdAtStr = goal.createdAt.map { dateFormatter.string(from: $0) } ?? ""
                let updatedAtStr = goal.updatedAt.map { dateFormatter.string(from: $0) } ?? ""
                
                let row = [
                    goal.title ?? "",
                    String(goal.targetAmount),
                    String(goal.currentAmount),
                    startDateStr,
                    targetDateStr,
                    createdAtStr,
                    updatedAtStr
                ].map { "\"\($0)\"" }.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        csvContent += "\n\n"
        
        // 4. 清单项目数据表
        csvContent += "=== 清单项目数据 ===\n"
        csvContent += "标题,是否完成,创建时间,更新时间\n"
        let checklistRequest: NSFetchRequest<CheckListItem> = CheckListItem.fetchRequest()
        if let items = try? viewContext.fetch(checklistRequest) {
            for item in items {
                let createdAtStr = item.createdAt.map { dateFormatter.string(from: $0) } ?? ""
                let updatedAtStr = item.updatedAt.map { dateFormatter.string(from: $0) } ?? ""
                
                let row = [
                    item.title ?? "",
                    item.isCompleted ? "是" : "否",
                    createdAtStr,
                    updatedAtStr
                ].map { "\"\($0)\"" }.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        
        return csvContent
    }

    private func shareCSV() {
        // 获取所有数据并生成CSV内容
        let csvContent = downloadCSVData()
        
        // 保存CSV文件
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsPath.appendingPathComponent("DiaryData.csv")
            do {
                // 添加 UTF-8 BOM，解决中文乱码问题
                let bomPrefix = Data([0xEF, 0xBB, 0xBF])
                try bomPrefix.write(to: fileURL)
                try csvContent.data(using: .utf8)?.write(to: fileURL, options: .atomic)
                
                print("✅ 文件已保存: \(fileURL)")
                print("📝 导出数据内容预览:")
                print(csvContent.prefix(200))  // 打印前200个字符用于调试
                
                // 分享文件
                let activityVC = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    activityVC.popoverPresentationController?.sourceView = rootVC.view
                    rootVC.present(activityVC, animated: true)
                }
            } catch {
                print("❌ 保存文件失败: \(error)")
                print("错误详情: \(error.localizedDescription)")
            }
        }
    }

    private func downloadCSVData() -> String {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter
        }()
        
        var csvContent = ""
        
        // 1. 日记数据表
        csvContent += "=== 日记数据 ===\n"
        csvContent += "标题,内容,日期,金额,是否支出,备注,天气,是否收藏,图片,待办事项,创建时间,更新时间\n"
        let itemRequest: NSFetchRequest<Item> = Item.fetchRequest()
        if let items = try? viewContext.fetch(itemRequest) {
            for item in items {
                // 分步处理每个字段
                let fields = [
                    item.title ?? "",
                    item.body ?? "",
                    dateFormatter.string(from: item.date),
                    String(item.amount),
                    item.isExpense ? "是" : "否",
                    item.note ?? "",
                    item.weather ?? "",
                    item.isBookmarked ? "是" : "否",
                    item.imageData?.base64EncodedString() ?? "",
                    "",
                    dateFormatter.string(from: item.createdAt),
                    dateFormatter.string(from: item.updatedAt)
                ]
                
                let quotedFields = fields.map { "\"\($0)\"" }
                let row = quotedFields.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        csvContent += "\n\n"
        
        // 2. 联系人数据表
        csvContent += "=== 联系人数据 ===\n"
        csvContent += "姓名,关系层级,生日,备注,最近联系时间,头像,创建时间,更新时间\n"
        let contactRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
        if let contacts = try? viewContext.fetch(contactRequest) {
            for contact in contacts {
                // 分步处理每个字段
                let birthdayStr = contact.birthday.map { dateFormatter.string(from: $0) } ?? ""
                let lastInteractionStr = contact.lastInteraction.map { dateFormatter.string(from: $0) } ?? ""
                let avatarStr = contact.avatar?.base64EncodedString() ?? ""
                
                let fields = [
                    contact.name ?? "",
                    String(contact.tier),
                    birthdayStr,
                    contact.notes ?? "",
                    lastInteractionStr,
                    avatarStr,
                    dateFormatter.string(from: contact.createdAt), // 非可选
                    dateFormatter.string(from: contact.updatedAt)  // 非可选
                ]
                
                let quotedFields = fields.map { "\"\($0)\"" }
                let row = quotedFields.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        csvContent += "\n\n"
        
        // 3. 储蓄目标数据表
        csvContent += "=== 储蓄目标数据 ===\n"
        csvContent += "标题,目标金额,当前金额,开始日期,目标日期,创建时间,更新时间\n"
        let goalRequest: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
        if let goals = try? viewContext.fetch(goalRequest) {
            for goal in goals {
                // 分步处理每个字段
                let startDateStr = goal.startDate.map { dateFormatter.string(from: $0) } ?? ""
                let targetDateStr = goal.targetDate.map { dateFormatter.string(from: $0) } ?? ""
                let createdAtStr = dateFormatter.string(from: goal.createdAt ?? Date()) // 提供默认值
                let updatedAtStr = dateFormatter.string(from: goal.updatedAt ?? Date()) // 提供默认值
                
                let fields = [
                    goal.title ?? "",
                    String(goal.targetAmount),
                    String(goal.currentAmount),
                    startDateStr,
                    targetDateStr,
                    createdAtStr,
                    updatedAtStr
                ]
                
                let quotedFields = fields.map { "\"\($0)\"" }
                let row = quotedFields.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        csvContent += "\n\n"
        
        // 4. 清单项目数据表
        csvContent += "=== 清单项目数据 ===\n"
        csvContent += "标题,是否完成,创建时间,更新时间\n"
        let checklistRequest: NSFetchRequest<CheckListItem> = CheckListItem.fetchRequest()
        if let items = try? viewContext.fetch(checklistRequest) {
            for item in items {
                // 分步处理每个字段
                let createdAtStr = dateFormatter.string(from: item.createdAt ?? Date()) // 提供默认值
                let updatedAtStr = dateFormatter.string(from: item.updatedAt ?? Date()) // 提供默认值
                
                let fields = [
                    item.title ?? "",
                    item.isCompleted ? "是" : "否",
                    createdAtStr,
                    updatedAtStr
                ]
                
                let quotedFields = fields.map { "\"\($0)\"" }
                let row = quotedFields.joined(separator: ",")
                csvContent += row + "\n"
            }
        }
        
        print("📝 导出数据表单数量: 4")
        print("📝 CSV内容长度: \(csvContent.count) 字符")
        
        return csvContent
    }
}

// 添加 FilePicker 实现
struct FilePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedFile: URL?
    let onFileSelected: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // 使用简单的文件类型定义
        let types: [String] = ["public.comma-separated-values-text", "public.plain-text"]
        let picker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        
        // 基本配置
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
