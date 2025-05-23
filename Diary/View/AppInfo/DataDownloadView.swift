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
            downloadData()
        }) {
            Text("下载")
                .fontWeight(.bold)
        }
        .softButtonStyle(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .disabled(isExporting)
    }

    private func downloadData() {
        isExporting = true
        exportProgress = 0
        
        let workItem = DispatchWorkItem {
            var diaryEntries: [Item] = []
            var savingsGoals: [SavingsGoal] = []
            var contacts: [Contact] = []
            var expenses: [Item] = []
            var checkListItems: [CheckListItem] = []
            
            self.viewContext.performAndWait {
                // 获取日记数据
                let diaryRequest: NSFetchRequest<Item> = Item.fetchRequest()
                diaryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.date, ascending: false)]
                if let entries = try? self.viewContext.fetch(diaryRequest) {
                    diaryEntries = entries
                }
                
                // 获取储蓄目标数据
                let goalRequest: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
                goalRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: false)]
                if let goals = try? self.viewContext.fetch(goalRequest) {
                    savingsGoals = goals
                }
                
                // 获取联系人数据
                let contactRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
                contactRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.name, ascending: true)]
                if let fetchedContacts = try? self.viewContext.fetch(contactRequest) {
                    contacts = fetchedContacts
                }
                
                // 获取记账数据
                let expenseRequest: NSFetchRequest<Item> = Item.fetchRequest()
                expenseRequest.predicate = NSPredicate(format: "amount != 0")
                expenseRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.date, ascending: false)]
                if let fetchedExpenses = try? self.viewContext.fetch(expenseRequest) {
                    expenses = fetchedExpenses
                }
                
                // 获取待办事项数据
                let checkListRequest: NSFetchRequest<CheckListItem> = CheckListItem.fetchRequest()
                checkListRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CheckListItem.createdAt, ascending: false)]
                if let items = try? self.viewContext.fetch(checkListRequest) {
                    checkListItems = items
                }
            }
            
            // 转换数据为指定格式
            let dataString: String
            switch self.selectedFormat {
            case .csv:
                dataString = self.convertToCSV(
                    entries: diaryEntries,
                    goals: savingsGoals,
                    contacts: contacts,
                    expenses: expenses,
                    checkListItems: checkListItems
                )
            case .txt:
                dataString = self.convertToTXT(
                    entries: diaryEntries,
                    goals: savingsGoals,
                    contacts: contacts,
                    expenses: expenses,
                    checkListItems: checkListItems
                )
            }
            
            // 保存文件
            if let data = dataString.data(using: .utf8) {
                let fileName = "diary_data_\(Date().timeIntervalSince1970).\(self.selectedFormat.rawValue.lowercased())"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                do {
                    try data.write(to: fileURL)
                    DispatchQueue.main.async {
                        self.isExporting = false
                        self.exportProgress = 1.0
                        self.shareFile(fileURL)
                    }
                } catch {
                    print("保存文件失败: \(error)")
                    DispatchQueue.main.async {
                        self.isExporting = false
                        self.exportProgress = 0
                    }
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }

    private func convertToCSV(
        entries: [Item],
        goals: [SavingsGoal],
        contacts: [Contact],
        expenses: [Item],
        checkListItems: [CheckListItem]
    ) -> String {
        var csvString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 添加 UTF-8 BOM，确保 Excel 正确识别中文
        csvString += "\u{FEFF}"
        
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
        
        // 添加表格页分隔符
        csvString += "\n\n=== 表格页分隔符 ===\n\n"
        
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
        
        // 添加表格页分隔符
        csvString += "\n\n=== 表格页分隔符 ===\n\n"
        
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
        
        // 添加表格页分隔符
        csvString += "\n\n=== 表格页分隔符 ===\n\n"
        
        // 4. 记账数据
        csvString += "=== 记账数据 ===\n"
        csvString += "标题,金额,是否支出,日期,备注,创建时间,更新时间\n"
        for expense in expenses {
            var fields = [String]()
            fields.append((expense.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(expense.amount))
            fields.append(expense.isExpense ? "是" : "否")
            fields.append(expense.date.map { dateFormatter.string(from: $0) } ?? "")
            fields.append((expense.note ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(expense.createdAt.map { dateFormatter.string(from: $0) } ?? "")
            fields.append(expense.updatedAt.map { dateFormatter.string(from: $0) } ?? "")
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        // 添加表格页分隔符
        csvString += "\n\n=== 表格页分隔符 ===\n\n"
        
        // 5. 待办事项数据
        csvString += "=== 待办事项数据 ===\n"
        csvString += "标题,是否完成,日记,创建时间,更新时间\n"
        for item in checkListItems {
            var fields = [String]()
            fields.append((item.title ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(item.isCompleted ? "是" : "否")
            if let diary = item.diary as? Item {
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
        expenses: [Item],
        checkListItems: [CheckListItem]
    ) -> String {
        var txtString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 1. 日记数据
        txtString += "=== 日记数据 ===\n\n"
        for entry in entries {
            txtString += "标题：\(entry.title ?? "")\n"
            txtString += "内容：\(entry.body ?? "")\n"
            if let date = entry.date {
                txtString += "日期：\(dateFormatter.string(from: date))\n"
            }
            txtString += "天气：\(entry.weather ?? "")\n"
            txtString += "是否收藏：\(entry.isBookmarked ? "是" : "否")\n"
            if let imageData = entry.imageData {
                txtString += "图片：\(imageData.base64EncodedString())\n"
            }
            if let createdAt = entry.createdAt {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = entry.updatedAt {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 2. 储蓄目标数据
        txtString += "=== 储蓄目标数据 ===\n\n"
        for goal in goals {
            txtString += "标题：\(goal.title ?? "")\n"
            txtString += "目标金额：\(goal.targetAmount)\n"
            txtString += "当前金额：\(goal.currentAmount)\n"
            if let targetDate = goal.targetDate {
                txtString += "截止日期：\(dateFormatter.string(from: targetDate))\n"
            }
            if let createdAt = goal.createdAt {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = goal.updatedAt {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 3. 联系人数据
        txtString += "=== 联系人数据 ===\n\n"
        for contact in contacts {
            txtString += "姓名：\(contact.name ?? "")\n"
            txtString += "关系层级：\(contact.tier)\n"
            if let birthday = contact.birthday {
                txtString += "生日：\(dateFormatter.string(from: birthday))\n"
            }
            txtString += "备注：\(contact.notes ?? "")\n"
            if let lastInteraction = contact.lastInteraction {
                txtString += "最近联系时间：\(dateFormatter.string(from: lastInteraction))\n"
            }
            if let avatar = contact.avatar {
                txtString += "头像：\(avatar.base64EncodedString())\n"
            }
            if let createdAt = contact.createdAt {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = contact.updatedAt {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 4. 记账数据
        txtString += "=== 记账数据 ===\n\n"
        for expense in expenses {
            txtString += "标题：\(expense.title ?? "")\n"
            txtString += "金额：\(expense.amount)\n"
            txtString += "是否支出：\(expense.isExpense ? "是" : "否")\n"
            if let date = expense.date {
                txtString += "日期：\(dateFormatter.string(from: date))\n"
            }
            txtString += "备注：\(expense.note ?? "")\n"
            if let createdAt = expense.createdAt {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = expense.updatedAt {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 5. 待办事项数据
        txtString += "=== 待办事项数据 ===\n\n"
        for item in checkListItems {
            txtString += "标题：\(item.title ?? "")\n"
            txtString += "是否完成：\(item.isCompleted ? "是" : "否")\n"
            if let diary = item.diary as? Item {
                txtString += "日记：\(diary.title ?? "")\n"
            } else {
                txtString += "日记：\n"
            }
            if let createdAt = item.createdAt {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = item.updatedAt {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        
        return txtString
    }

    private func shareFile(_ fileURL: URL) {
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
    }
}
