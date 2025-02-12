import SwiftUI
import CoreData
import Neumorphic

struct DataDownloadView: View {
    @EnvironmentObject private var bannerState: BannerState
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedFormat: FileFormat = .csv

    enum FileFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case txt = "TXT"
        var id: String { self.rawValue }
    }

    var body: some View {
        ScrollView {
             VStack(spacing: 10) {
               Spacer()
               .padding(30)
                     }
            NoticeText
            ImportData

            DownloadText
            SelectButton
            saveButton
   
        }
        .navigationTitle("管理日记数据")
        .padding(30)
        .background(Color.Neumorphic.main) // 设置 DataDownloadView 的背景颜色
        .edgesIgnoringSafeArea(.all)
    }
    
    var  NoticeText: some View {
        VStack(spacing: 10) {
            Text("导入日记仅支持过去导出的历史日记数据，格式为txt或者csv格式。")
                .padding()
                .foregroundColor(.gray)
                .font(.system(size: 18))
        }
    }

     var ImportData: some View { // 导入数据
        NavigationLink {
            DataImportView()
        } label: {
            Text("导入").fontWeight(.bold)
        }
        .softButtonStyle(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

     var  DownloadText: some View {
        VStack(spacing: 10) {
            Text("您可以选择导出历史日记数据为txt或者csv格式。")
                .padding()
                .foregroundColor(.gray)
                .font(.system(size: 18))
        }
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
            bannerState.show(of: .success(message: "导出成功🎉"))}) {
    Text("下载").fontWeight(.bold)
}
.softButtonStyle(RoundedRectangle(cornerRadius: 12))
  .padding(.horizontal)
  
    }

 
    private func downloadData(format: FileFormat) {
        // 1. 从 CoreData 获取日记数据
        let diaryEntries = CoreDataProvider.shared.exportAllDiaryEntries()

        // 2. 将数据转换为指定格式的字符串
        let fileContent = convertDataToFileContent(entries: diaryEntries, format: format)

        // 3. 保存文件到本地
        saveFile(content: fileContent, format: format)
    }

    private func convertDataToFileContent(entries: [Item], format: FileFormat) -> String {
        switch format {
        case .csv:
            return convertToCSV(entries: entries)
        case .txt:
            return convertToTXT(entries: entries)
        }
    }

    private func convertToCSV(entries: [Item]) -> String {
        var csvString = "Title,Body,CreatedAt,UpdatedAt,Weather,ImageData,IsBookmarked\n"
        for entry in entries {
            let title = entry.title ?? ""
            let body = entry.body ?? ""
            let createdAt = entry.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let updatedAt = entry.updatedAt?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let weather = entry.weather ?? ""
            let imageData = entry.imageData?.base64EncodedString() ?? ""
            let isBookmarked = entry.isBookmarked
            csvString += "\(title),\(body),\(createdAt),\(updatedAt),\(weather),\(imageData),\(isBookmarked)\n"
        }
        return csvString
    }

    private func convertToTXT(entries: [Item]) -> String {
         var txtString = ""
        for entry in entries {
            let title = entry.title ?? ""
            let body = entry.body ?? ""
            let createdAt = entry.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let updatedAt = entry.updatedAt?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let weather = entry.weather ?? ""
            let imageData = entry.imageData?.base64EncodedString() ?? ""
            let isBookmarked = entry.isBookmarked
            txtString += "Title: \(title)\nBody: \(body)\nCreatedAt: \(createdAt)\nUpdatedAt: \(updatedAt)\nWeather: \(weather)\nImageData: \(imageData)\nIsBookmarked: \(isBookmarked)\n\n"
        }
        return txtString
    }

   private func saveFile(content: String, format: FileFormat) {
        let fileName = "DiaryData.\(format.rawValue.lowercased())"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved to \(fileURL)")

            // 使用 UIActivityViewController 显示分享选项
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

            // 找到当前视图控制器并呈现 activityViewController
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                viewController.present(activityViewController, animated: true, completion: nil)
            }

        } catch {
            print("Error saving file: \(error)")
            // TODO: Show error alert
        }
    }
      }
