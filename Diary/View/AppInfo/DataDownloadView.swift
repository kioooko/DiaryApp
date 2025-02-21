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
        VStack(spacing: 30) {
            Text("导入日记仅支持过去导出的历史日记数据，格式为txt或者csv格式。")
            .padding()
            .foregroundColor(.gray)
            .font(.system(size: 14))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
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
            Text("您可以选择导出历史数据为txt或者csv格式。")
                .foregroundColor(.gray)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding()
       
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
        
        // 获取文件名
        let fileName = "DiaryData.\(format.rawValue.lowercased())"
        
        // 获取文件URL
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: fileURL.path)
            print("✅ 取消了文件保护")
        } catch {
            print("❌ 取消文件保护失败: \(error)")
        }

        // 3. 保存文件到本地
        saveFile(content: fileContent, fileURL: fileURL)
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
        // CSV 头部 - 包含所有字段
        var csvString = "标题,内容,日期,金额,是否支出,备注,天气,是否收藏,图片,待办事项,创建时间,更新时间\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for entry in entries {
            var fields = [String]()
            
            // 基本文本字段 - 替换逗号为中文逗号
            fields.append((entry.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((entry.body ?? "").replacingOccurrences(of: ",", with: "，"))
            
            // 日期字段
            fields.append(entry.date.map { dateFormatter.string(from: $0) } ?? "")
            
            // 数值和布尔字段
            fields.append(String(entry.amount))
            fields.append(entry.isExpense ? "是" : "否")
            fields.append((entry.note ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((entry.weather ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(entry.isBookmarked ? "是" : "否")
            
            // 图片数据 - Base64编码
            if let imageData = entry.imageData {
                fields.append(imageData.base64EncodedString())
            } else {
                fields.append("")
            }
            
            // 待办事项
            let checkListItems = (entry.checkListItems?.allObjects as? [CheckListItem])?.map { item in
                let title = (item.title ?? "").replacingOccurrences(of: ",", with: "，")
                                            .replacingOccurrences(of: "|", with: "｜")
                let status = item.isCompleted ? "[✓]" : "[ ]"
                return "\(status) \(title)"
            }.joined(separator: "|") ?? ""
            fields.append(checkListItems)
            
            // 时间戳
            fields.append(entry.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(entry.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            
            // 添加一行记录
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    private func convertToTXT(entries: [Item]) -> String {
        var txtString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for entry in entries {
            // 基本信息
            txtString += "日期: \(entry.date.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "标题: \(entry.title ?? "")\n"
            txtString += "内容: \(entry.body ?? "")\n"
            
            // 记账信息
            if entry.amount != 0 {
                txtString += "金额: \(entry.amount)\n"
                txtString += "类型: \(entry.isExpense ? "支出" : "收入")\n"
                if let note = entry.note, !note.isEmpty {
                    txtString += "备注: \(note)\n"
                }
            }
            
            // 天气和收藏状态
            if let weather = entry.weather, !weather.isEmpty {
                txtString += "天气: \(weather)\n"
            }
            if entry.isBookmarked {
                txtString += "已收藏\n"
            }
            
            // 图片数据
            if let imageData = entry.imageData {
                txtString += "图片: \(imageData.base64EncodedString())\n"
            }
            
            // 待办事项
            if let checkListItems = entry.checkListItems?.allObjects as? [CheckListItem], !checkListItems.isEmpty {
                txtString += "\n待办事项:\n"
                for item in checkListItems {
                    let status = item.isCompleted ? "[✓]" : "[ ]"
                    txtString += "\(status) \(item.title ?? "")\n"
                }
            }
            
            // 创建和更新时间
            txtString += "创建时间: \(entry.createdAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "更新时间: \(entry.updatedAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            
            txtString += "\n-------------------\n\n"
        }
        
        return txtString
    }

    private func saveFile(content: String, fileURL: URL) {
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
