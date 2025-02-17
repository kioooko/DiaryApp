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
                                        importContent(content)
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
    
    private func importContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        var successCount = 0
        
        // 跳过CSV头部
        let dataLines = Array(lines.dropFirst())
        
        for line in dataLines where !line.isEmpty {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 11 else { continue } // 确保有足够的字段（包括图片）
            
            let item = Item(context: viewContext)
            
            // 解析日期
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            item.date = dateFormatter.date(from: fields[0]) ?? Date()
            item.createdAt = item.date
            item.updatedAt = Date()
            
            // 基本信息
            item.title = fields[1]
            item.body = fields[2]
            
            // 记账信息
            item.amount = Double(fields[3]) ?? 0
            item.isExpense = fields[4] == "是"
            item.expenseCategory = fields[5]
            item.expenseNote = fields[6]
            
            // 其他信息
            item.weather = fields[7]
            item.isBookmarked = fields[8] == "是"
            
            // 处理图片数据
            if !fields[9].isEmpty {
                if let imageData = Data(base64Encoded: fields[9]) {
                    item.imageData = imageData
                }
            }
            
            // 处理待办事项
            if fields.count > 10 {
                let checkListItems = fields[10].components(separatedBy: "|")
                for checkListStr in checkListItems where !checkListStr.isEmpty {
                    let checkListItem = CheckListItem(context: viewContext)
                    let isCompleted = checkListStr.contains("[✓]")
                    let title = checkListStr.replacingOccurrences(of: "[✓]", with: "")
                        .replacingOccurrences(of: "[ ]", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    checkListItem.title = title
                    checkListItem.isCompleted = isCompleted
                    checkListItem.createdAt = item.date
                    item.addToCheckListItems(checkListItem)
                }
            }
            
            do {
                try viewContext.save()
                successCount += 1
            } catch {
                print("❌ 导入单条记录失败: \(error)")
                // 继续处理下一条记录
                viewContext.rollback()
            }
        }
        
        // 更新导入结果
        importedCount = successCount
        if successCount > 0 {
            showImportResult(success: true, message: "成功导入 \(successCount) 条记录")
        } else {
            showImportResult(success: false, message: "没有成功导入任何记录")
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

// 📌 `