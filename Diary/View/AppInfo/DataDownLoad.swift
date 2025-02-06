import Foundation
import CoreData
import UIKit
import SwiftUI

class DataDownLoad: ObservableObject {
    static let shared = DataDownLoad()

    private init() {}

    enum ExportFormat {
        case csv
        case txt
    }

    enum DataDownLoadError: Error {
        case fileCreationFailed
        case writeFailed
        case coreDataError(Error)
    }

    @Published var isExporting = false
    @Published var exportError: Error?
    @Published var fileURL: URL?

    func exportData(
        entityName: String,
        attributes: [String],
        exportFormat: ExportFormat,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        switch exportFormat {
        case .csv:
            exportCoreDataToCSV(entityName: entityName, attributes: attributes, completion: completion)
        case .txt:
            exportCoreDataToTXT(entityName: entityName, attributes: attributes, completion: completion)
        }
    }

    private func exportCoreDataToCSV(
        entityName: String,
        attributes: [String],
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        // ... existing code ...
    }

    private func exportCoreDataToTXT(
        entityName: String,
        attributes: [String],
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            completion(.failure(DataDownLoadError.fileCreationFailed))
            return
        }

        let managedContext = appDelegate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)

        do {
            let objects = try managedContext.fetch(fetchRequest)

            guard !objects.isEmpty else {
                print("没有数据可以导出")
                completion(.failure(DataDownLoadError.fileCreationFailed))
                return
            }

            var txtContent = ""

            // 添加标题行
            txtContent += attributes.joined(separator: "\t") + "\n"

            // 遍历数据
            for object in objects {
                var row = ""
                for attribute in attributes {
                    let value = object.value(forKey: attribute)

                    switch value {
                    case let dateValue as Date:
                        // 格式化日期
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 自定义日期格式
                        row += "\(dateFormatter.string(from: dateValue))\t"
                    case let stringValue as String:
                        // 处理字符串，进行转义或其他格式化
                        row += "\(stringValue.replacingOccurrences(of: "\t", with: " "))\t" // 替换制表符
                    case let intValue as Int:
                        row += "\(intValue)\t"
                    case let doubleValue as Double:
                        row += "\(doubleValue)\t"
                    case nil:
                        row += "\t" // 处理空值
                    default:
                        print("不支持的类型：\(type(of: value))")
                        row += "\t"
                    }
                }
                txtContent += row.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
            }

            // 获取文档目录
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("无法获取文档目录")
                completion(.failure(DataDownLoadError.fileCreationFailed))
                return
            }

            // 创建文件路径
            let fileName = "\(entityName).txt"
            let filePath = documentsDirectory.appendingPathComponent(fileName)

            do {
                try txtContent.write(to: filePath, atomically: true, encoding: .utf8)
                print("TXT 文件已保存到：\(filePath)")
                completion(.success(filePath))
            } catch {
                print("保存 TXT 文件时出错：\(error)")
                completion(.failure(DataDownLoadError.writeFailed))
            }

        } catch let error as NSError {
            print("无法获取数据。\(error), \(error.userInfo)")
            completion(.failure(DataDownLoadError.coreDataError(error)))
        }
    }

    func handleExport(
        entityName: String,
        attributes: [String],
        exportFormat: ExportFormat
    ) {
        isExporting = true
        exportError = nil
        fileURL = nil

        exportData(entityName: entityName, attributes: attributes, exportFormat: exportFormat) { result in
            DispatchQueue.main.async {
                self.isExporting = false
                switch result {
                case .success(let url):
                    self.fileURL = url
                case .failure(let error):
                    self.exportError = error
                }
            }
        }
    }
}

struct DataDownLoadView: View {
    @ObservedObject var dataDownLoad = DataDownLoad.shared
    @State private var selectedExportFormat: DataDownLoad.ExportFormat = .csv
    let entityName = "Item"
    let attributes = ["date", "title", "bodyText"]

    var body: some View {
        VStack {
            Picker("选择导出格式", selection: $selectedExportFormat) {
                Text("CSV").tag(DataDownLoad.ExportFormat.csv)
                Text("TXT").tag(DataDownLoad.ExportFormat.txt)
            }
            .pickerStyle(.segmented)
            Button("导出数据") {
                dataDownLoad.handleExport(
                    entityName: entityName,
                    attributes: attributes,
                    exportFormat: selectedExportFormat
                )
            }
            .disabled(dataDownLoad.isExporting)

            if dataDownLoad.isExporting {
                ProgressView("正在导出...")
            }

            if let error = dataDownLoad.exportError {
                Text("导出失败: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }

            if let fileURL = dataDownLoad.fileURL {
                ShareSheet(items: [fileURL])
            }
        }
        .padding()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to do
    }
}