import SwiftUI
import CoreData
import Neumorphic

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

    private func downloadData(format: FileFormat) {
        let workItem = DispatchWorkItem {
            // 1. 从 CoreData 获取所有数据
            var diaryEntries: [NSManagedObject] = []
            var savingsGoals: [NSManagedObject] = []
            var contacts: [NSManagedObject] = []
            var expenses: [NSManagedObject] = []
            var checkListItems: [NSManagedObject] = []
            
            viewContext.performAndWait {
                do {
                    // 获取日记数据
                    let diaryRequest = NSFetchRequest<NSManagedObject>(entityName: "Item")
                    diaryRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                    diaryEntries = try viewContext.fetch(diaryRequest)
                    print("✅ 成功获取日记数据: \(diaryEntries.count) 条")
                    
                    // 获取储蓄目标数据
                    let savingsRequest = NSFetchRequest<NSManagedObject>(entityName: "SavingsGoal")
                    savingsRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    savingsGoals = try viewContext.fetch(savingsRequest)
                    print("✅ 成功获取储蓄目标数据: \(savingsGoals.count) 条")
                    
                    // 获取联系人数据
                    let contactRequest = NSFetchRequest<NSManagedObject>(entityName: "Contact")
                    contactRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                    contacts = try viewContext.fetch(contactRequest)
                    print("✅ 成功获取联系人数据: \(contacts.count) 条")
                    
                    // 获取支出数据
                    if let expenseEntity = NSEntityDescription.entity(forEntityName: "Expense", in: viewContext) {
                        let expenseRequest = NSFetchRequest<NSManagedObject>(entityName: "Expense")
                        expenseRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                        expenses = try viewContext.fetch(expenseRequest)
                        print("✅ 成功获取支出数据: \(expenses.count) 条")
                    } else {
                        print("❌ 无法找到 Expense 实体")
                    }
                    
                    // 获取待办事项数据
                    let checkListRequest = NSFetchRequest<NSManagedObject>(entityName: "CheckListItem")
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
        
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }

    private func convertToFileContent(
        entries: [NSManagedObject],
        goals: [NSManagedObject],
        contacts: [NSManagedObject],
        expenses: [NSManagedObject],
        checkListItems: [NSManagedObject],
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
        entries: [NSManagedObject],
        goals: [NSManagedObject],
        contacts: [NSManagedObject],
        expenses: [NSManagedObject],
        checkListItems: [NSManagedObject]
    ) -> String {
        var csvString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 日记数据
        csvString += "=== 日记数据 ===\n"
        csvString += "标题,内容,日期,天气,是否收藏,图片,创建时间,更新时间\n"
        for entry in entries {
            var fields = [String]()
            fields.append((entry.value(forKey: "title") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((entry.value(forKey: "body") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            if let date = entry.value(forKey: "date") as? Date {
                fields.append(dateFormatter.string(from: date))
            } else {
                fields.append("")
            }
            fields.append((entry.value(forKey: "weather") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((entry.value(forKey: "isBookmarked") as? Bool ?? false) ? "是" : "否")
            if let imageData = entry.value(forKey: "imageData") as? Data {
                fields.append(imageData.base64EncodedString())
            } else {
                fields.append("")
            }
            if let createdAt = entry.value(forKey: "createdAt") as? Date {
                fields.append(dateFormatter.string(from: createdAt))
            } else {
                fields.append("")
            }
            if let updatedAt = entry.value(forKey: "updatedAt") as? Date {
                fields.append(dateFormatter.string(from: updatedAt))
            } else {
                fields.append("")
            }
            csvString += fields.joined(separator: ",") + "\n"
        }
        csvString += "\n\n"
        
        // 储蓄目标数据
        csvString += "=== 储蓄目标数据 ===\n"
        csvString += "标题,目标金额,当前金额,目标日期,创建时间,更新时间\n"
        for goal in goals {
            var fields = [String]()
            fields.append((goal.value(forKey: "title") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(goal.value(forKey: "targetAmount") as? Double ?? 0))
            fields.append(String(goal.value(forKey: "currentAmount") as? Double ?? 0))
            if let targetDate = goal.value(forKey: "targetDate") as? Date {
                fields.append(dateFormatter.string(from: targetDate))
            } else {
                fields.append("")
            }
            if let createdAt = goal.value(forKey: "createdAt") as? Date {
                fields.append(dateFormatter.string(from: createdAt))
            } else {
                fields.append("")
            }
            if let updatedAt = goal.value(forKey: "updatedAt") as? Date {
                fields.append(dateFormatter.string(from: updatedAt))
            } else {
                fields.append("")
            }
            csvString += fields.joined(separator: ",") + "\n"
        }
        csvString += "\n\n"
        
        // 联系人数据
        csvString += "=== 联系人数据 ===\n"
        csvString += "姓名,等级,生日,备注,最后互动时间,头像,创建时间,更新时间\n"
        for contact in contacts {
            var fields = [String]()
            fields.append((contact.value(forKey: "name") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(contact.value(forKey: "tier") as? Int ?? 0))
            if let birthday = contact.value(forKey: "birthday") as? Date {
                fields.append(dateFormatter.string(from: birthday))
            } else {
                fields.append("")
            }
            fields.append((contact.value(forKey: "notes") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            if let lastInteraction = contact.value(forKey: "lastInteraction") as? Date {
                fields.append(dateFormatter.string(from: lastInteraction))
            } else {
                fields.append("")
            }
            if let avatar = contact.value(forKey: "avatar") as? Data {
                fields.append(avatar.base64EncodedString())
            } else {
                fields.append("")
            }
            if let createdAt = contact.value(forKey: "createdAt") as? Date {
                fields.append(dateFormatter.string(from: createdAt))
            } else {
                fields.append("")
            }
            if let updatedAt = contact.value(forKey: "updatedAt") as? Date {
                fields.append(dateFormatter.string(from: updatedAt))
            } else {
                fields.append("")
            }
            csvString += fields.joined(separator: ",") + "\n"
        }
        csvString += "\n\n"
        
        // 支出数据
        csvString += "=== 支出数据 ===\n"
        csvString += "标题,金额,类型,日期,备注,关联联系人,创建时间,更新时间\n"
        for expense in expenses {
            var fields = [String]()
            fields.append((expense.value(forKey: "title") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append(String(expense.value(forKey: "amount") as? Double ?? 0))
            fields.append((expense.value(forKey: "isExpense") as? Bool ?? false) ? "支出" : "收入")
            if let date = expense.value(forKey: "date") as? Date {
                fields.append(dateFormatter.string(from: date))
            } else {
                fields.append("")
            }
            fields.append((expense.value(forKey: "note") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            if let contact = expense.value(forKey: "contact") as? NSManagedObject {
                fields.append((contact.value(forKey: "name") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            } else {
                fields.append("")
            }
            if let createdAt = expense.value(forKey: "createdAt") as? Date {
                fields.append(dateFormatter.string(from: createdAt))
            } else {
                fields.append("")
            }
            if let updatedAt = expense.value(forKey: "updatedAt") as? Date {
                fields.append(dateFormatter.string(from: updatedAt))
            } else {
                fields.append("")
            }
            csvString += fields.joined(separator: ",") + "\n"
        }
        csvString += "\n\n"
        
        // 待办事项数据
        csvString += "=== 待办事项数据 ===\n"
        csvString += "标题,是否完成,创建时间,更新时间\n"
        for item in checkListItems {
            var fields = [String]()
            fields.append((item.value(forKey: "title") as? String ?? "").replacingOccurrences(of: ",", with: "，"))
            fields.append((item.value(forKey: "isCompleted") as? Bool ?? false) ? "是" : "否")
            if let createdAt = item.value(forKey: "createdAt") as? Date {
                fields.append(dateFormatter.string(from: createdAt))
            } else {
                fields.append("")
            }
            if let updatedAt = item.value(forKey: "updatedAt") as? Date {
                fields.append(dateFormatter.string(from: updatedAt))
            } else {
                fields.append("")
            }
            csvString += fields.joined(separator: ",") + "\n"
        }
        
        return csvString
    }

    private func convertToTXT(
        entries: [NSManagedObject],
        goals: [NSManagedObject],
        contacts: [NSManagedObject],
        expenses: [NSManagedObject],
        checkListItems: [NSManagedObject]
    ) -> String {
        var txtString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // 日记数据
        txtString += "=== 日记数据 ===\n\n"
        for entry in entries {
            txtString += "标题：\(entry.value(forKey: "title") as? String ?? "")\n"
            txtString += "内容：\(entry.value(forKey: "body") as? String ?? "")\n"
            if let date = entry.value(forKey: "date") as? Date {
                txtString += "日期：\(dateFormatter.string(from: date))\n"
            }
            txtString += "天气：\(entry.value(forKey: "weather") as? String ?? "")\n"
            txtString += "是否收藏：\((entry.value(forKey: "isBookmarked") as? Bool ?? false) ? "是" : "否")\n"
            if let createdAt = entry.value(forKey: "createdAt") as? Date {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = entry.value(forKey: "updatedAt") as? Date {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 储蓄目标数据
        txtString += "=== 储蓄目标数据 ===\n\n"
        for goal in goals {
            txtString += "标题：\(goal.value(forKey: "title") as? String ?? "")\n"
            txtString += "目标金额：\(goal.value(forKey: "targetAmount") as? Double ?? 0)\n"
            txtString += "当前金额：\(goal.value(forKey: "currentAmount") as? Double ?? 0)\n"
            if let targetDate = goal.value(forKey: "targetDate") as? Date {
                txtString += "目标日期：\(dateFormatter.string(from: targetDate))\n"
            }
            if let createdAt = goal.value(forKey: "createdAt") as? Date {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = goal.value(forKey: "updatedAt") as? Date {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 联系人数据
        txtString += "=== 联系人数据 ===\n\n"
        for contact in contacts {
            txtString += "姓名：\(contact.value(forKey: "name") as? String ?? "")\n"
            txtString += "等级：\(contact.value(forKey: "tier") as? Int ?? 0)\n"
            if let birthday = contact.value(forKey: "birthday") as? Date {
                txtString += "生日：\(dateFormatter.string(from: birthday))\n"
            }
            txtString += "备注：\(contact.value(forKey: "notes") as? String ?? "")\n"
            if let lastInteraction = contact.value(forKey: "lastInteraction") as? Date {
                txtString += "最后互动时间：\(dateFormatter.string(from: lastInteraction))\n"
            }
            if let createdAt = contact.value(forKey: "createdAt") as? Date {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = contact.value(forKey: "updatedAt") as? Date {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 支出数据
        txtString += "=== 支出数据 ===\n\n"
        for expense in expenses {
            txtString += "标题：\(expense.value(forKey: "title") as? String ?? "")\n"
            txtString += "金额：\(expense.value(forKey: "amount") as? Double ?? 0)\n"
            txtString += "类型：\((expense.value(forKey: "isExpense") as? Bool ?? false) ? "支出" : "收入")\n"
            if let date = expense.value(forKey: "date") as? Date {
                txtString += "日期：\(dateFormatter.string(from: date))\n"
            }
            txtString += "备注：\(expense.value(forKey: "note") as? String ?? "")\n"
            if let contact = expense.value(forKey: "contact") as? NSManagedObject {
                txtString += "关联联系人：\(contact.value(forKey: "name") as? String ?? "")\n"
            }
            if let createdAt = expense.value(forKey: "createdAt") as? Date {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = expense.value(forKey: "updatedAt") as? Date {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        txtString += "\n"
        
        // 待办事项数据
        txtString += "=== 待办事项数据 ===\n\n"
        for item in checkListItems {
            txtString += "标题：\(item.value(forKey: "title") as? String ?? "")\n"
            txtString += "是否完成：\((item.value(forKey: "isCompleted") as? Bool ?? false) ? "是" : "否")\n"
            if let createdAt = item.value(forKey: "createdAt") as? Date {
                txtString += "创建时间：\(dateFormatter.string(from: createdAt))\n"
            }
            if let updatedAt = item.value(forKey: "updatedAt") as? Date {
                txtString += "更新时间：\(dateFormatter.string(from: updatedAt))\n"
            }
            txtString += "\n"
        }
        
        return txtString
    }

    private func saveFile(content: String, format: FileFormat) {
        let fileName = "日记数据_\(Date().timeIntervalSince1970).\(format.rawValue.lowercased())"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true)
                bannerState.show(of: .success(message: "数据导出成功"))
            }
        } catch {
            print("❌ 保存文件失败: \(error)")
            bannerState.show(of: .error(message: "保存文件失败：\(error.localizedDescription)"))
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("数据导出")
                .font(.title)
                .fontWeight(.bold)
            
            Picker("导出格式", selection: $selectedFormat) {
                ForEach(FileFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if isExporting {
                ProgressView(value: exportProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
            }
            
            Button(action: {
                isExporting = true
                exportProgress = 0.3
                downloadData(format: selectedFormat)
            }) {
                Text("导出数据")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(isExporting)
            
            Spacer()
        }
        .padding()
    }
}
