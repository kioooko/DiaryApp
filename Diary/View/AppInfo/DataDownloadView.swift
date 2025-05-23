import SwiftUI
import CoreData
import Neumorphic

// 添加必要的类型定义
@objc(Expense)
public class Expense: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var isExpense: Bool
    @NSManaged public var date: Date?
    @NSManaged public var note: String?
    @NSManaged public var contact: Contact?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension Expense {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }
}

struct DataDownloadView: View {
    @EnvironmentObject private var bannerState: BannerState
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedFormat: FileFormat = .csv
    @State private var isExporting = false
    @State private var exportProgress: Double = 0

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
        .background(Color.Neumorphic.main)
        .edgesIgnoringSafeArea(.all)
    }
    
    var NoticeText: some View {
        VStack(spacing: 30) {
            Text("导入日记仅支持过去导出的历史日记数据，格式为txt或者csv格式。")
                .padding()
                .foregroundColor(.gray)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    var ImportData: some View {
        NavigationLink {
            DataImportView()
        } label: {
            Text("导入")
                .fontWeight(.bold)
                .padding(.init(top: 30, leading: 120, bottom: 30, trailing: 120))
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.gray)
                )
        }
    }

    var DownloadText: some View {
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
        VStack(spacing: 10) {
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
                    )) {
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
        Button(action: {
            isExporting = true
            exportProgress = 0
            downloadData(format: selectedFormat)
        }) {
            Text("下载")
                .fontWeight(.bold)
        }
        .softButtonStyle(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .disabled(isExporting)
    }

    private func downloadData(format: FileFormat) {
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. 从 CoreData 获取所有数据
            var diaryEntries: [Item] = []
            var savingsGoals: [SavingsGoal] = []
            var contacts: [Contact] = []
            var expenses: [Expense] = []
            var checkListItems: [CheckListItem] = []
            
            viewContext.performAndWait {
                do {
                    // 获取日记数据
                    let diaryRequest = NSFetchRequest<Item>(entityName: "Item")
                    diaryRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                    diaryEntries = try viewContext.fetch(diaryRequest)
                    print("✅ 成功获取日记数据: \(diaryEntries.count) 条")
                    
                    // 获取储蓄目标数据
                    let savingsRequest = NSFetchRequest<SavingsGoal>(entityName: "SavingsGoal")
                    savingsRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    savingsGoals = try viewContext.fetch(savingsRequest)
                    print("✅ 成功获取储蓄目标数据: \(savingsGoals.count) 条")
                    
                    // 获取联系人数据
                    let contactRequest = NSFetchRequest<Contact>(entityName: "Contact")
                    contactRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                    contacts = try viewContext.fetch(contactRequest)
                    print("✅ 成功获取联系人数据: \(contacts.count) 条")
                    
                    // 获取支出数据
                    if let expenseEntity = NSEntityDescription.entity(forEntityName: "Expense", in: viewContext) {
                        let expenseRequest = NSFetchRequest<Expense>(entityName: "Expense")
                        expenseRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                        expenses = try viewContext.fetch(expenseRequest)
                        print("✅ 成功获取支出数据: \(expenses.count) 条")
                    } else {
                        print("❌ 无法找到 Expense 实体")
                    }
                    
                    // 获取待办事项数据
                    let checkListRequest = NSFetchRequest<CheckListItem>(entityName: "CheckListItem")
                    checkListRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    checkListItems = try viewContext.fetch(checkListRequest)
                    print("✅ 成功获取待办事项数据: \(checkListItems.count) 条")
                } catch {
                    print("❌ 获取数据失败: \(error)")
                    DispatchQueue.main.async {
                        bannerState.show(of: .error(message: "获取数据失败：\(error.localizedDescription)"))
                        isExporting = false
                        exportProgress = 0
                    }
                    return
                }
            }
            
            // 2. 将数据转换为指定格式的字符串
            let fileContent = convertToFileContent(
                entries: diaryEntries,
                goals: savingsGoals,
                contacts: contacts,
                expenses: expenses,
                checkListItems: checkListItems,
                format: format
            )

            // 3. 保存文件到本地
            DispatchQueue.main.async {
                saveFile(content: fileContent, format: format)
                isExporting = false
                exportProgress = 0
            }
        }
    }

    private func convertToFileContent(
        entries: [Item],
        goals: [SavingsGoal],
        contacts: [Contact],
        expenses: [Expense],
        checkListItems: [CheckListItem],
        format: FileFormat
    ) -> String {
        switch format {
        case .csv:
            return convertToCSV(
                entries: entries,
                goals: goals,
                contacts: contacts,
                expenses: expenses,
                checkListItems: checkListItems
            )
        case .txt:
            return convertToTXT(
                entries: entries,
                goals: goals,
                contacts: contacts,
                expenses: expenses,
                checkListItems: checkListItems
            )
        }
    }

    private func convertToCSV(
        entries: [Item],
        goals: [SavingsGoal],
        contacts: [Contact],
        expenses: [Expense],
        checkListItems: [CheckListItem]
    ) -> String {
        var csvString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 1. 日记数据
        csvString += "=== 日记数据 ===\n"
        csvString += "标题,内容,日期,天气,是否收藏,图片,创建时间,更新时间\n"
        for entry in entries {
            var fields = [String]()
            fields.append((entry.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((entry.body ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(entry.date.map { dateFormatter.string(from: $0) } ?? "")
            fields.append((entry.weather ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(entry.isBookmarked ? "是" : "否")
            fields.append(entry.imageData?.base64EncodedString() ?? "")
            fields.append(entry.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(entry.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            csvString += fields.joined(separator: ",") + "\n"
        }
        csvString += "\n\n"
        
        // 2. 储蓄目标数据
        csvString += "=== 储蓄目标数据 ===\n"
        csvString += "标题,目标金额,当前金额,截止日期,创建时间,更新时间\n"
        for goal in goals {
            var fields = [String]()
            fields.append((goal.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(goal.targetAmount))
            fields.append(String(goal.currentAmount))
            fields.append(goal.targetDate.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(goal.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            csvString += fields.joined(separator: ",") + "\n"
        }
        csvString += "\n\n"
        
        // 3. 联系人数据
        csvString += "=== 联系人数据 ===\n"
        csvString += "姓名,关系层级,生日,备注,最近联系时间,头像,创建时间,更新时间\n"
        for contact in contacts {
            var fields = [String]()
            fields.append((contact.name ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(contact.tier))
            fields.append(contact.birthday.map { dateFormatter.string(from: $0) } ?? "")
            fields.append((contact.notes ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(contact.lastInteraction.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(contact.avatar?.base64EncodedString() ?? "")
            fields.append(contact.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(contact.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            csvString += fields.joined(separator: ",") + "\n"
        }
        csvString += "\n\n"
        
        // 4. 支出数据
        if !expenses.isEmpty {
            csvString += "=== 支出数据 ===\n"
            csvString += "标题,金额,是否支出,日期,备注,联系人,创建时间,更新时间\n"
            for expense in expenses {
                var fields = [String]()
                fields.append((expense.title ?? "").replacingOccurrences(of: ",", with: "，"))
                fields.append(String(expense.amount))
                fields.append(expense.isExpense ? "是" : "否")
                fields.append(expense.date.map { dateFormatter.string(from: $0) } ?? "")
                fields.append((expense.note ?? "").replacingOccurrences(of: ",", with: "，"))
                fields.append((expense.contact?.name ?? "").replacingOccurrences(of: ",", with: "，"))
                fields.append(expense.createdAt.map { dateFormatter.string(from: $0) } ?? "")
                fields.append(expense.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
                csvString += fields.joined(separator: ",") + "\n"
            }
            csvString += "\n\n"
        }
        
        // 5. 待办事项数据
        csvString += "=== 待办事项数据 ===\n"
        csvString += "标题,是否完成,日记,创建时间,更新时间\n"
        for item in checkListItems {
            var fields = [String]()
            fields.append((item.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(item.isCompleted ? "是" : "否")
            if let diary = item.diary?.allObjects.first as? Item {
                fields.append((diary.title ?? "").replacingOccurrences(of: ",", with: "，"))
            } else {
                fields.append("")
            }
            fields.append(item.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(item.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    private func convertToTXT(
        entries: [Item],
        goals: [SavingsGoal],
        contacts: [Contact],
        expenses: [Expense],
        checkListItems: [CheckListItem]
    ) -> String {
        var txtString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 1. 日记数据
        txtString += "=== 日记数据 ===\n\n"
        for entry in entries {
            txtString += "标题: \(entry.title ?? "")\n"
            txtString += "内容: \(entry.body ?? "")\n"
            txtString += "日期: \(entry.date.map { dateFormatter.string(from: $0) } ?? "")\n"
            if let weather = entry.weather {
                txtString += "天气: \(weather)\n"
            }
            if entry.isBookmarked {
                txtString += "已收藏\n"
            }
            if let imageData = entry.imageData {
                txtString += "图片: \(imageData.base64EncodedString())\n"
            }
            txtString += "创建时间: \(entry.createdAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "更新时间: \(entry.updatedAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "\n"
        }
        
        // 2. 储蓄目标数据
        txtString += "=== 储蓄目标数据 ===\n\n"
        for goal in goals {
            txtString += "标题: \(goal.title ?? "")\n"
            txtString += "目标金额: \(goal.targetAmount)\n"
            txtString += "当前金额: \(goal.currentAmount)\n"
            if let targetDate = goal.targetDate {
                txtString += "截止日期: \(dateFormatter.string(from: targetDate))\n"
            }
            txtString += "创建时间: \(goal.createdAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "更新时间: \(goal.updatedAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "\n"
        }
        
        // 3. 联系人数据
        txtString += "=== 联系人数据 ===\n\n"
        for contact in contacts {
            txtString += "姓名: \(contact.name ?? "")\n"
            txtString += "关系层级: \(contact.tier)\n"
            if let birthday = contact.birthday {
                txtString += "生日: \(dateFormatter.string(from: birthday))\n"
            }
            if let notes = contact.notes {
                txtString += "备注: \(notes)\n"
            }
            if let lastInteraction = contact.lastInteraction {
                txtString += "最近联系时间: \(dateFormatter.string(from: lastInteraction))\n"
            }
            if let avatar = contact.avatar {
                txtString += "头像: \(avatar.base64EncodedString())\n"
            }
            txtString += "创建时间: \(contact.createdAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "更新时间: \(contact.updatedAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "\n"
        }
        
        // 4. 支出数据
        if !expenses.isEmpty {
            txtString += "=== 支出数据 ===\n\n"
            for expense in expenses {
                txtString += "标题: \(expense.title ?? "")\n"
                txtString += "金额: \(expense.amount)\n"
                txtString += "类型: \(expense.isExpense ? "支出" : "收入")\n"
                txtString += "日期: \(expense.date.map { dateFormatter.string(from: $0) } ?? "")\n"
                if let note = expense.note {
                    txtString += "备注: \(note)\n"
                }
                if let contact = expense.contact {
                    txtString += "联系人: \(contact.name ?? "")\n"
                }
                txtString += "创建时间: \(expense.createdAt.map { dateFormatter.string(from: $0) } ?? "")\n"
                txtString += "更新时间: \(expense.updatedAt.map { dateFormatter.string(from: $0) } ?? "")\n"
                txtString += "\n"
            }
        }
        
        // 5. 待办事项数据
        txtString += "=== 待办事项数据 ===\n\n"
        for item in checkListItems {
            txtString += "标题: \(item.title ?? "")\n"
            txtString += "状态: \(item.isCompleted ? "已完成" : "未完成")\n"
            if let diary = item.diary?.allObjects.first as? Item {
                txtString += "所属日记: \(diary.title ?? "")\n"
            }
            txtString += "创建时间: \(item.createdAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "更新时间: \(item.updatedAt.map { dateFormatter.string(from: $0) } ?? "")\n"
            txtString += "\n"
        }
        
        return txtString
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
