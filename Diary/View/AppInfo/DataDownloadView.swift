import SwiftUI
import CoreData
import Neumorphic

// 添加 DiaryEntry 的定义
class DiaryEntry: NSManagedObject {
    @NSManaged var date: Date?
    @NSManaged var title: String?
    @NSManaged var content: String?
}

struct DataDownloadView: View {
    @EnvironmentObject private var bannerState: BannerState
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedFormat: FileFormat = .csv

    enum FileFormat: String, CaseIterable, Identifiable {
        case csv = "导出数据为CSV格式"
        case txt = "导出数据为TXT格式"
        var id: String { self.rawValue }
    }

    var body: some View {
        ScrollView {
             VStack(spacing: 10) {
               Spacer()
               .padding(30)
                     }
            NoticeText
            SelectButton
            saveButton
        }
        .navigationTitle("导出日记数据")
        .padding(30)
        .background(Color.Neumorphic.main) // 设置 DataDownloadView 的背景颜色
        .edgesIgnoringSafeArea(.all)
    }
    
    var  NoticeText: some View {
        VStack(spacing: 10) {
            Text("您可以选择下载txt或者csv格式\n将您的历史数据导出。")
                .padding()
                .foregroundColor(.gray)
                .font(.system(size: 18))
        }
      //  .padding(10)
    }

      var SelectButton: some View {
        VStack (spacing: 10) {
            ForEach(FileFormat.allCases) { format in
                HStack {
                    Text(format.rawValue)
                    Spacer()
                    Toggle(isOn: Binding(
                        get: { selectedFormat == format },
                        set: { newValue in
                            if newValue {
                                selectedFormat = format
                            }
                        }
                    ))
                    {
                        EmptyView()
                    }
                    .labelsHidden()
                }
                .padding(.horizontal)
            }
        }
     .padding(.bottom, 30)
    }

  var saveButton: some View {
Button(action: {  downloadData(format: selectedFormat)
            bannerState.show(of: .success(message: "下载成功🎉"))}) {
    Text("下载").fontWeight(.bold)
}
.softButtonStyle(RoundedRectangle(cornerRadius: 12))
  .padding(.horizontal)
  
    }

    private func downloadData(format: FileFormat) {
        // 1. 从 CoreData 获取日记数据
        guard let fetchRequest = DiaryEntry.fetchRequest() as? NSFetchRequest<DiaryEntry> else {
            print("Could not create fetch request for DiaryEntry")
            return
        }
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
