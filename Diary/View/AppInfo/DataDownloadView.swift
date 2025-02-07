import SwiftUI
import CoreData

struct DataDownloadView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedFormat: FileFormat = .csv

    enum FileFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case txt = "TXT"

        var id: String { self.rawValue }
    }

    var body: some View {
        VStack {
            Text("选择下载格式")
                .font(.title2)
                .padding()

            Picker("文件格式", selection: $selectedFormat) {
                ForEach(FileFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Button("下载") {
                downloadData(format: selectedFormat)
            }
            .padding()
        }
    }

    private func downloadData(format: FileFormat) {
        // 1. 从 CoreData 获取日记数据
        let fetchRequest: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        do {
            let diaryEntries = try viewContext.fetch(fetchRequest)

            // 2. 将数据转换为指定格式的字符串
            let fileContent = convertDataToFileContent(entries: diaryEntries, format: format)

            // 3. 保存文件到本地
            saveFile(content: fileContent, format: format)

        } catch {
            print("Error fetching diary entries: \(error)")
        }
    }

    private func convertDataToFileContent(entries: [DiaryEntry], format: FileFormat) -> String {
        switch format {
        case .csv:
            return convertToCSV(entries: entries)
        case .txt:
            return convertToTXT(entries: entries)
        }
    }

    private func convertToCSV(entries: [DiaryEntry]) -> String {
        var csvString = "Date,Title,Content\n" // CSV Header
        for entry in entries {
            let date = entry.date?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let title = entry.title ?? ""
            let content = entry.content ?? ""
            csvString += "\(date),\(title),\(content)\n"
        }
        return csvString
    }

    private func convertToTXT(entries: [DiaryEntry]) -> String {
        var txtString = ""
        for entry in entries {
            let date = entry.date?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let title = entry.title ?? ""
            let content = entry.content ?? ""
            txtString += "Date: \(date)\nTitle: \(title)\nContent: \(content)\n\n"
        }
        return txtString
    }

    private func saveFile(content: String, format: FileFormat) {
        let fileName = "DiaryData.\(format.rawValue.lowercased())"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved to: \(fileURL)")
            // TODO: 显示一个提示，告诉用户文件已保存，并提供分享选项
        } catch {
            print("Error saving file: \(error)")
        }
    }
}

// 示例 DiaryEntry 实体 (请替换为你实际的 CoreData 实体)
class DiaryEntry: NSManagedObject {
    @NSManaged var date: Date?
    @NSManaged var title: String?
    @NSManaged var content: String?
}