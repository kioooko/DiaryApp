import SwiftUI
import UniformTypeIdentifiers
import CoreData
import UIKit

struct DataImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var bannerState: BannerState
    @State private var isImporting: Bool = false
    @State private var importProgress: Double = 0
    @State private var selectedFile: URL?
    @State private var isDropTargeted: Bool = false

    var body: some View {
        ZStack {
            Color.Neumorphic.main
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 10) {
                // 拖拽区域
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
                    }
                }
                .padding(.horizontal, 40)
                .onTapGesture {
                    isImporting = true
                }
                .onDrop(
                    of: [.fileURL],
                    isTargeted: $isDropTargeted
                ) { providers in
                    guard let provider = providers.first else { return false }
                    
                    _ = provider.loadObject(ofClass: URL.self) { url, error in
                        if let url = url {
                            DispatchQueue.main.async {
                                copyAndImportFile(from: url)
                            }
                        }
                    }
                    return true
                }

                if isImporting {
                    FilePicker(isPresented: $isImporting, selectedFile: $selectedFile) { url in
                        if let url = url {
                            copyAndImportFile(from: url)
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
    }
    
    private func copyAndImportFile(from sourceURL: URL) {
        do {
            // 获取应用文档目录
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            
            // 如果文件已存在，先删除
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // 复制文件到文档目录
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            // 更新UI并开始导入
            selectedFile = destinationURL
            importData(fileURL: destinationURL)
            
        } catch {
            print("❌ 文件处理失败: \(error)")
            bannerState.show(of: .error(message: "文件处理失败：\(error.localizedDescription)"))
        }
    }
    
    private func importData(fileURL: URL) {
        isImporting = true
        importProgress = 0

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
                let entries = parseFileContent(fileContent: fileContent, fileURL: fileURL)

                importToCoreData(entries: entries)

                DispatchQueue.main.async {
                    isImporting = false
                    bannerState.show(of: .success(message: "成功导入 \(entries.count) 条日记"))
                    selectedFile = nil
                    importProgress = 0
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    bannerState.show(of: .error(message: "导入失败：\(error.localizedDescription)"))
                    importProgress = 0
                }
            }
        }
    }

    private func parseFileContent(fileContent: String, fileURL: URL) -> [DiaryEntry] {
        let fileExtension = fileURL.pathExtension.lowercased()
        switch fileExtension {
        case "csv":
            return parseCSV(fileContent: fileContent)
        case "txt":
            return parseTXT(fileContent: fileContent)
        default:
            return []
        }
    }

    private func parseCSV(fileContent: String) -> [DiaryEntry] {
        var entries: [DiaryEntry] = []
        let rows = fileContent.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ",")
            if columns.count >= 3 {
                let dateString = columns[0]
                let title = columns[1]
                let body = columns[2]

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = dateFormatter.date(from: dateString) {
                    let entry = DiaryEntry(date: date, title: title, body: body)
                    entries.append(entry)
                }
            }
        }
        return entries
    }

    private func parseTXT(fileContent: String) -> [DiaryEntry] {
        var entries: [DiaryEntry] = []
        let rows = fileContent.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: "|")
            if columns.count >= 3 {
                let dateString = columns[0]
                let title = columns[1]
                let body = columns[2]

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                if let date = dateFormatter.date(from: dateString) {
                    let entry = DiaryEntry(date: date, title: title, body: body)
                    entries.append(entry)
                }
            }
        }
        return entries
    }

    private func importToCoreData(entries: [DiaryEntry]) {
        let totalEntries = entries.count
        for (index, entry) in entries.enumerated() {
            let item = Item(context: viewContext)
            item.date = entry.date
            item.title = entry.title
            item.body = entry.body
            item.createdAt = Date()
            item.updatedAt = Date()

            do {
                try viewContext.save()
            } catch {
                print("保存 Core Data 失败：\(error)")
            }

            let progress = Double(index + 1) / Double(totalEntries)
            DispatchQueue.main.async {
                importProgress = progress
            }
        }
    }
}

// 📌 `FilePicker` 用于在 SwiftUI 里调用 `UIDocumentPickerViewController`
struct FilePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedFile: URL?
    let onFileSelected: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.plainText, .commaSeparatedText])
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
            guard let url = urls.first else { return }
            parent.selectedFile = url
            parent.onFileSelected(url)
            parent.isPresented = false
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
            parent.onFileSelected(nil)
        }
    }
}

// 📌 `DiaryEntry` 结构体
struct DiaryEntry {
    let date: Date
    let title: String
    let body: String
}
