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
        // 1. 从 CoreData 获取所有数据
        let diaryEntries = CoreDataProvider.shared.exportAllDiaryEntries()
        let savingsGoals = CoreDataProvider.shared.exportAllSavingsGoals()

        // 2. 将数据转换为指定格式的字符串
        let diaryContent = convertDataToFileContent(entries: diaryEntries, format: format)
        let savingsContent = convertSavingsGoalsToFileContent(goals: savingsGoals, format: format)

        // 3. 保存文件到本地
        saveAndShare(diaryContent: diaryContent, savingsContent: savingsContent, format: format)
    }

    private func convertDataToFileContent(entries: [Item], format: FileFormat) -> String {
        switch format {
        case .csv:
            return convertToCSV(entries: entries)
        case .txt:
            return convertToTXT(entries: entries)
        }
    }

    private func convertSavingsGoalsToFileContent(goals: [SavingsGoal], format: FileFormat) -> String {
        switch format {
        case .csv:
            return convertSavingsGoalsToCSV(goals: goals)
        case .txt:
            return convertSavingsGoalsToTXT(goals: goals)
        }
    }

    private func convertToCSV(entries: [Item]) -> String {
        // CSV 头部 - 根据实际数据库结构定义列
        var csvString = "日期,标题,内容,金额,是否支出,备注,天气,是否收藏,图片,待办事项,创建时间,更新时间\n"
        
        for entry in entries {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            // 处理基本字段
            var fields = [String]()
            
            // 日期和时间字段
            fields.append(entry.date.map { dateFormatter.string(from: $0) } ?? "")
            fields.append((entry.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((entry.body ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(entry.amount))
            fields.append(entry.isExpense ? "是" : "否")
            fields.append((entry.note ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((entry.weather ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(entry.isBookmarked ? "是" : "否")
            
            // 图片数据
            let imageStr = entry.imageData?.base64EncodedString() ?? ""
            fields.append(imageStr)
            
            // 待办事项
            let checkListItems = (entry.checkListItems?.allObjects as? [CheckListItem])?.map { item in
                let title = (item.title ?? "").replacingOccurrences(of: ",", with: "，")
                let status = item.isCompleted ? "[✓]" : "[ ]"
                return "\(status) \(title)"
            }.joined(separator: "|") ?? ""
            fields.append(checkListItems)
            
            // 创建和更新时间
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

    private func convertSavingsGoalsToCSV(goals: [SavingsGoal]) -> String {
        // CSV 头部 - 储蓄目标的字段
        var csvString = "标题,目标金额,当前金额,每月存储金额,每月存储日期,开始日期,目标日期,是否完成,创建时间,更新时间\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for goal in goals {
            var fields = [String]()
            
            // 基本信息
            fields.append((goal.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(goal.targetAmount))
            fields.append(String(goal.currentAmount))
            fields.append(String(goal.monthlyAmount))
            
            // 日期相关
            fields.append(goal.monthlyDate.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.startDate.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.targetDate.map { dateFormatter.string(from: $0) } ?? "")
            
            // 状态
            fields.append(goal.isCompleted ? "是" : "否")
            
            // 创建和更新时间
            fields.append(goal.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            
            // 添加一行记录
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    private func convertSavingsGoalsToTXT(goals: [SavingsGoal]) -> String {
        var txtString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for goal in goals {
            txtString += "储蓄目标信息:\n"
            txtString += "标题: \(goal.title ?? "")\n"
            txtString += "目标金额: \(goal.targetAmount)\n"
            txtString += "当前金额: \(goal.currentAmount)\n"
            txtString += "每月存储金额: \(goal.monthlyAmount)\n"
            
            if let monthlyDate = goal.monthlyDate {
                txtString += "每月存储日期: \(dateFormatter.string(from: monthlyDate))\n"
            }
            
            if let startDate = goal.startDate {
                txtString += "开始日期: \(dateFormatter.string(from: startDate))\n"
            }
            
            if let targetDate = goal.targetDate {
                txtString += "目标日期: \(dateFormatter.string(from: targetDate))\n"
            }
            
            txtString += "是否完成: \(goal.isCompleted ? "是" : "否")\n"
            
            if let createdAt = goal.createdAt {
                txtString += "创建时间: \(dateFormatter.string(from: createdAt))\n"
            }
            
            if let updatedAt = goal.updatedAt {
                txtString += "更新时间: \(dateFormatter.string(from: updatedAt))\n"
            }
            
            txtString += "\n-------------------\n\n"
        }
        
        return txtString
    }

    private func saveAndShare(diaryContent: String, savingsContent: String, format: FileFormat) {
        let diaryFileName = "DiaryData.\(format.rawValue.lowercased())"
        let savingsFileName = "SavingsGoals.\(format.rawValue.lowercased())"
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            bannerState.show(of: .error(message: "无法访问文档目录"))
            return
        }
        
        let diaryFileURL = documentsPath.appendingPathComponent(diaryFileName)
        let savingsFileURL = documentsPath.appendingPathComponent(savingsFileName)
        
        do {
            // 添加 UTF-8 BOM，确保文件编码正确
            let bom = "\u{FEFF}"
            
            // 保存日记数据
            try (bom + diaryContent).write(to: diaryFileURL, atomically: true, encoding: .utf8)
            // 保存储蓄目标数据
            try (bom + savingsContent).write(to: savingsFileURL, atomically: true, encoding: .utf8)
            
            print("✅ 文件已保存: \(diaryFileURL)")
            print("✅ 文件已保存: \(savingsFileURL)")
            
            // 分享两个文件
            let activityVC = UIActivityViewController(
                activityItems: [diaryFileURL, savingsFileURL],
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
