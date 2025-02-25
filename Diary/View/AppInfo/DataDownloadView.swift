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
        // 1. 获取所有实体数据
        let diaryEntries = CoreDataProvider.shared.exportAllDiaryEntries()
        let savingsGoals = CoreDataProvider.shared.fetchAllSavingsGoals()
        let checkListItems = CoreDataProvider.shared.fetchAllCheckListItems()
        let contacts = CoreDataProvider.shared.fetchAllContacts()
        
        // 2. 转换为CSV格式
        let csvContent = convertToMultiSheetCSV(
            items: diaryEntries,
            goals: savingsGoals,
            checkListItems: checkListItems,
            contacts: contacts
        )
        
        // 3. 保存并分享
        saveFile(content: csvContent, format: .csv)
    }

    private func convertToMultiSheetCSV(
        items: [Item],
        goals: [SavingsGoal],
        checkListItems: [CheckListItem],
        contacts: [Contact]
    ) -> String {
        var csvString = ""
        
        // 添加工作表分隔符
        let sheetSeparator = "\n<<<SHEET>>>\n"
        
        // 1. 日记工作表
        csvString += "=== 日记数据 ===\n"
        csvString += convertItemsToCSV(items)
        csvString += sheetSeparator
        
        // 2. 储蓄目标工作表
        csvString += "=== 储蓄目标 ===\n"
        csvString += convertGoalsToCSV(goals)
        csvString += sheetSeparator
        
        // 3. 待办事项工作表
        csvString += "=== 待办事项 ===\n"
        csvString += convertCheckListItemsToCSV(checkListItems)
        csvString += sheetSeparator
        
        // 4. 联系人工作表
        csvString += "=== 联系人 ===\n"
        csvString += convertContactsToCSV(contacts)
        
        return csvString
    }

    // 转换日记数据
    private func convertItemsToCSV(_ items: [Item]) -> String {
        var csvString = "标题,内容,日期,金额,是否支出,备注,天气,是否收藏,图片,创建时间,更新时间\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for item in items {
            var fields = [String]()
            fields.append((item.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((item.body ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(item.date.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(String(item.amount))
            fields.append(item.isExpense ? "是" : "否")
            fields.append((item.note ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((item.weather ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(item.isBookmarked ? "是" : "否")
            fields.append(item.imageData?.base64EncodedString() ?? "")
            fields.append(item.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(item.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    // 转换储蓄目标数据
    private func convertGoalsToCSV(_ goals: [SavingsGoal]) -> String {
        var csvString = "标题,目标金额,当前金额,每月金额,每月日期,开始日期,目标日期,是否完成,创建时间,更新时间\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for goal in goals {
            var fields = [String]()
            fields.append((goal.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(goal.targetAmount))
            fields.append(String(goal.currentAmount))
            fields.append(String(goal.monthlyAmount))
            fields.append(goal.monthlyDate.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.startDate.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.targetDate.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.isCompleted ? "是" : "否")
            fields.append(goal.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    // 转换待办事项数据
    private func convertCheckListItemsToCSV(_ items: [CheckListItem]) -> String {
        var csvString = "标题,是否完成,创建时间,更新时间\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for item in items {
            var fields = [String]()
            fields.append((item.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(item.isCompleted ? "是" : "否")
            fields.append(item.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(item.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    // 转换联系人数据
    private func convertContactsToCSV(_ contacts: [Contact]) -> String {
        var csvString = "姓名,生日,创建时间,更新时间\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for contact in contacts {
            var fields = [String]()
            fields.append((contact.name ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(contact.birthday.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(contact.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(contact.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    private func saveFile(content: String, format: FileFormat) {
        let fileName = "DiaryData.\(format.rawValue.lowercased())"
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            bannerState.show(of: .error(message: "无法访问文档目录"))
            return
        }
        
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            // 添加 UTF-8 BOM，确保文件编码正确
            let bom = "\u{FEFF}"
            
            // 保存文件
            try (bom + content).write(to: fileURL, atomically: true, encoding: .utf8)
            
            print("✅ 文件已保存: \(fileURL)")
            
            // 分享文件
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
