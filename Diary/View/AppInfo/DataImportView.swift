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

    var body: some View {
        ScrollView {
            Color.Neumorphic.main // 设置背景颜色为 Neumorphic 风格
                .edgesIgnoringSafeArea(.all) // 确保背景颜色覆盖整个视图
            VStack(spacing: 10) {
            Spacer()
            .padding(.init(top: 60, leading: 120, bottom: 60, trailing: 120)) // 增加一些内边距，让按钮更好看
            Button("选择文件") {
                isImporting = true
            }
            .disabled(isImporting)

            if isImporting {
                FilePicker(isPresented: $isImporting, selectedFile: $selectedFile, onFileSelected: importData)
            }

            if let selectedFile = selectedFile {
                Text("已选择文件：\(selectedFile.lastPathComponent)")
                    .padding()
            }
              Spacer()
        }
          }
        .navigationTitle("导入日记数据")
        .padding(30)
    }

    private func importData(fileURL: URL?) {
        guard let selectedFile = fileURL else {
            bannerState.show(of: .warning(message: "请先选择文件"))
            return
        }

        isImporting = true
        importProgress = 0

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOf: selectedFile, encoding: .utf8)
                let entries = parseFileContent(fileContent: fileContent, fileURL: selectedFile)

                importToCoreData(entries: entries)

                DispatchQueue.main.async {
                    isImporting = false
                    bannerState.show(of: .success(message: "成功导入 \(entries.count) 条日记"))
                    self.selectedFile = nil
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    bannerState.show(of: .warning(message: "导入失败：\(error.localizedDescription)"))
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
    var onFileSelected: (URL?) -> Void

    func makeCoordinator() -> FilePickerCoordinator {
        return FilePickerCoordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.plainText, UTType.commaSeparatedText])
            documentPicker.delegate = context.coordinator
            documentPicker.allowsMultipleSelection = false
            uiViewController.present(documentPicker, animated: true, completion: nil)
            isPresented = false
        }
    }

    class FilePickerCoordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilePicker

        init(parent: FilePicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedFile = urls.first
            parent.onFileSelected(urls.first)
        }
    }
}

// 📌 `DiaryEntry` 结构体
struct DiaryEntry {
    let date: Date
    let title: String
    let body: String
}
