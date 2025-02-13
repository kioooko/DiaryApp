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
        Text("导入")
            .fontWeight(.bold)
            .padding(.init(top: 30, leading: 120, bottom: 30, trailing: 120)) // 增加一些内边距，让按钮更好看
            .background(Color.white) // 设置背景色
            .cornerRadius(12) // 轻微圆角
            .overlay( // 添加虚线边框
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5])) // 2px宽度，虚线间隔 5
                    .foregroundColor(.gray) // 虚线颜色
            )
    }
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
        saveAndShare(content: fileContent)
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
        // 使用与导入格式匹配的简单格式
        var csvString = "日期,内容\n"
        
        for entry in entries {
            // 确保日期格式与导入时的格式一致
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = entry.date.map { dateFormatter.string(from: $0) } ?? ""
            
            // 合并标题和内容，确保没有逗号
            var content = entry.title ?? ""
            if let body = entry.body, !body.isEmpty {
                content += content.isEmpty ? body : "\n\(body)"
            }
            content = content.replacingOccurrences(of: ",", with: "，")
            
            csvString += "\(date),\(content)\n"
        }
        return csvString
    }

    private func convertToTXT(entries: [Item]) -> String {
        // 使用与 CSV 相同的格式，以确保一致性
        return convertToCSV(entries: entries)
    }

    private func saveAndShare(content: String) {
        let fileName = "DiaryData.\(selectedFormat.rawValue.lowercased())"
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            bannerState.show(of: .error(message: "无法访问文档目录"))
            return
        }
        
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // 添加 UTF-8 BOM，确保文件编码正确
            let bom = "\u{FEFF}"
            let contentWithBOM = bom + content
            
            try contentWithBOM.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ 文件已保存: \(fileURL)")
            
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                DispatchQueue.main.async {
                    rootViewController.present(activityVC, animated: true)
                }
            }
            
            bannerState.show(of: .success(message: "导出成功"))
        } catch {
            print("❌ 保存文件失败: \(error)")
            bannerState.show(of: .error(message: "导出失败"))
        }
    }
      }
