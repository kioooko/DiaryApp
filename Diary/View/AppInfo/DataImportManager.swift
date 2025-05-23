import Foundation
import CoreData
import SwiftUI

class DataImportManager {
    let viewContext: NSManagedObjectContext
    
    @Published var importProgress: Double = 0
    @Published var importedCount: Int = 0
    @Published var failedCount: Int = 0
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // 导入数据主函数
    func importData(from fileURL: URL, completion: @escaping (Bool, String) -> Void) {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        guard fileExtension == "csv" || fileExtension == "txt" else {
            completion(false, "不支持的文件格式，请选择CSV或TXT文件")
            return
        }
        
        do {
            let fileContent = try String(contentsOf: fileURL, encoding: .utf8)
            
            if fileExtension == "csv" {
                importCSVData(fileContent, completion: completion)
            } else {
                importTXTData(fileContent, completion: completion)
            }
        } catch {
            completion(false, "读取文件失败: \(error.localizedDescription)")
        }
    }
    
    // 导入CSV格式数据
    private func importCSVData(_ content: String, completion: @escaping (Bool, String) -> Void) {
        // 重置计数器
        importProgress = 0
        importedCount = 0
        failedCount = 0
        
        // 按段落分割内容
        let sections = content.components(separatedBy: "===")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // 如果没有有效段落，返回错误
        if sections.isEmpty {
            completion(false, "CSV文件格式无效，未找到任何数据段落")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 开始处理各部分
            for section in sections {
                let lines = section.components(separatedBy: .newlines)
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                
                guard lines.count >= 2 else { continue }
                
                let sectionTitle = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let headerLine = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let dataLines = Array(lines.dropFirst(2))
                
                // 根据段落标题处理不同类型的数据
                if sectionTitle.contains("日记数据") {
                    self.processItemData(headerLine: headerLine, dataLines: dataLines)
                } else if sectionTitle.contains("待办事项") {
                    self.processCheckListItemData(headerLine: headerLine, dataLines: dataLines)
                } else if sectionTitle.contains("联系人") {
                    self.processContactData(headerLine: headerLine, dataLines: dataLines)
                } else if sectionTitle.contains("支出记录") {
                    self.processExpenseData(headerLine: headerLine, dataLines: dataLines)
                } else if sectionTitle.contains("储蓄目标") {
                    self.processSavingsGoalData(headerLine: headerLine, dataLines: dataLines)
                }
            }
            
            // 最后保存所有更改
            do {
                try self.viewContext.save()
                DispatchQueue.main.async {
                    completion(true, "成功导入 \(self.importedCount) 条记录，失败 \(self.failedCount) 条")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "保存数据失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 处理日记数据
    private func processItemData(headerLine: String, dataLines: [String]) {
        let headers = parseCSVHeaders(headerLine)
        
        // 进度计算
        let totalCount = dataLines.count
        var currentCount = 0
        
        for line in dataLines {
            let values = parseCSVLine(line)
            guard values.count >= 4 else { 
                failedCount += 1
                continue 
            }
            
            // 检查是否已存在相同ID的记录
            var existingItem: Item?
            if let idString = values[safe: headers.firstIndex(of: "ID")], 
               let uuid = UUID(uuidString: idString) {
                let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                existingItem = try? viewContext.fetch(fetchRequest).first
            }
            
            // 创建或更新记录
            let item = existingItem ?? Item(context: viewContext)
            
            // 设置UUID
            if item.id == nil {
                item.id = UUID()
            }
            
            // 设置标题
            if let titleIndex = headers.firstIndex(of: "标题"), 
               let title = values[safe: titleIndex] {
                item.title = title.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置内容
            if let bodyIndex = headers.firstIndex(of: "内容"), 
               let body = values[safe: bodyIndex] {
                item.body = body.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置日期
            if let dateIndex = headers.firstIndex(of: "日期"), 
               let dateStr = values[safe: dateIndex],
               let date = dateFormatter.date(from: dateStr) {
                item.date = date
            } else {
                item.date = Date()
            }
            
            // 设置是否收藏
            if let bookmarkIndex = headers.firstIndex(of: "是否收藏"), 
               let bookmark = values[safe: bookmarkIndex] {
                item.isBookmarked = bookmark.contains("是")
            }
            
            // 设置天气
            if let weatherIndex = headers.firstIndex(of: "天气"), 
               let weather = values[safe: weatherIndex] {
                item.weather = weather.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置图片URL
            if let imageURLIndex = headers.firstIndex(of: "图片URL"), 
               let imageURL = values[safe: imageURLIndex] {
                item.imageURL = imageURL.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置备注
            if let noteIndex = headers.firstIndex(of: "备注"), 
               let note = values[safe: noteIndex] {
                item.note = note.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置创建时间
            if let createdAtIndex = headers.firstIndex(of: "创建时间"), 
               let createdAtStr = values[safe: createdAtIndex],
               let createdAt = dateFormatter.date(from: createdAtStr) {
                item.createdAt = createdAt
            } else {
                item.createdAt = Date()
            }
            
            // 设置更新时间
            if let updatedAtIndex = headers.firstIndex(of: "更新时间"), 
               let updatedAtStr = values[safe: updatedAtIndex],
               let updatedAt = dateFormatter.date(from: updatedAtStr) {
                item.updatedAt = updatedAt
            } else {
                item.updatedAt = Date()
            }
            
            // 更新计数和进度
            importedCount += 1
            currentCount += 1
            importProgress = Double(currentCount) / Double(totalCount)
        }
    }
    
    // 处理待办事项数据
    private func processCheckListItemData(headerLine: String, dataLines: [String]) {
        let headers = parseCSVHeaders(headerLine)
        
        for line in dataLines {
            let values = parseCSVLine(line)
            guard values.count >= 3 else { 
                failedCount += 1
                continue 
            }
            
            // 检查是否已存在相同ID的记录
            var existingItem: CheckListItem?
            if let idString = values[safe: headers.firstIndex(of: "ID")], 
               let uuid = UUID(uuidString: idString) {
                let fetchRequest: NSFetchRequest<CheckListItem> = CheckListItem.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                existingItem = try? viewContext.fetch(fetchRequest).first
            }
            
            // 创建或更新记录
            let item = existingItem ?? CheckListItem(context: viewContext)
            
            // 设置UUID
            if item.id == nil {
                item.id = UUID()
            }
            
            // 设置标题
            if let titleIndex = headers.firstIndex(of: "标题"), 
               let title = values[safe: titleIndex] {
                item.title = title.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置是否完成
            if let completedIndex = headers.firstIndex(of: "是否完成"), 
               let completed = values[safe: completedIndex] {
                item.isCompleted = completed.contains("是")
            }
            
            // 关联到日记
            if let diaryIDIndex = headers.firstIndex(of: "对应日记ID"), 
               let diaryIDString = values[safe: diaryIDIndex],
               let diaryUUID = UUID(uuidString: diaryIDString) {
                let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", diaryUUID as CVarArg)
                if let diary = try? viewContext.fetch(fetchRequest).first {
                    item.diary = diary
                }
            }
            
            // 设置创建时间
            if let createdAtIndex = headers.firstIndex(of: "创建时间"), 
               let createdAtStr = values[safe: createdAtIndex],
               let createdAt = dateFormatter.date(from: createdAtStr) {
                item.createdAt = createdAt
            } else {
                item.createdAt = Date()
            }
            
            // 设置更新时间
            if let updatedAtIndex = headers.firstIndex(of: "更新时间"), 
               let updatedAtStr = values[safe: updatedAtIndex],
               let updatedAt = dateFormatter.date(from: updatedAtStr) {
                item.updatedAt = updatedAt
            } else {
                item.updatedAt = Date()
            }
            
            importedCount += 1
        }
    }
    
    // 处理联系人数据
    private func processContactData(headerLine: String, dataLines: [String]) {
        let headers = parseCSVHeaders(headerLine)
        
        for line in dataLines {
            let values = parseCSVLine(line)
            guard values.count >= 3 else { 
                failedCount += 1
                continue 
            }
            
            // 检查是否已存在相同ID的记录
            var existingContact: Contact?
            if let idString = values[safe: headers.firstIndex(of: "ID")], 
               let uuid = UUID(uuidString: idString) {
                let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                existingContact = try? viewContext.fetch(fetchRequest).first
            }
            
            // 创建或更新记录
            let contact = existingContact ?? Contact(context: viewContext)
            
            // 设置UUID
            if contact.id == nil {
                contact.id = UUID()
            }
            
            // 设置姓名
            if let nameIndex = headers.firstIndex(of: "姓名"), 
               let name = values[safe: nameIndex] {
                contact.name = name.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置关系层级
            if let tierIndex = headers.firstIndex(of: "关系层级"), 
               let tierStr = values[safe: tierIndex],
               let tier = Int16(tierStr) {
                contact.tier = tier
            }
            
            // 设置生日
            if let birthdayIndex = headers.firstIndex(of: "生日"), 
               let birthdayStr = values[safe: birthdayIndex],
               let birthday = dateFormatter.date(from: birthdayStr) {
                contact.birthday = birthday
            }
            
            // 设置备注
            if let notesIndex = headers.firstIndex(of: "备注"), 
               let notes = values[safe: notesIndex] {
                contact.notes = notes.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置最近联系时间
            if let lastInteractionIndex = headers.firstIndex(of: "最近联系时间"), 
               let lastInteractionStr = values[safe: lastInteractionIndex],
               let lastInteraction = dateFormatter.date(from: lastInteractionStr) {
                contact.lastInteraction = lastInteraction
            }
            
            // 设置头像URL
            if let avatarURLIndex = headers.firstIndex(of: "头像URL"), 
               let avatarURL = values[safe: avatarURLIndex] {
                contact.avatarURL = avatarURL.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置创建时间
            if let createdAtIndex = headers.firstIndex(of: "创建时间"), 
               let createdAtStr = values[safe: createdAtIndex],
               let createdAt = dateFormatter.date(from: createdAtStr) {
                contact.createdAt = createdAt
            } else {
                contact.createdAt = Date()
            }
            
            // 设置更新时间
            if let updatedAtIndex = headers.firstIndex(of: "更新时间"), 
               let updatedAtStr = values[safe: updatedAtIndex],
               let updatedAt = dateFormatter.date(from: updatedAtStr) {
                contact.updatedAt = updatedAt
            } else {
                contact.updatedAt = Date()
            }
            
            importedCount += 1
        }
    }
    
    // 处理支出记录数据
    private func processExpenseData(headerLine: String, dataLines: [String]) {
        let headers = parseCSVHeaders(headerLine)
        
        for line in dataLines {
            let values = parseCSVLine(line)
            guard values.count >= 5 else { 
                failedCount += 1
                continue 
            }
            
            // 检查是否已存在相同ID的记录
            var existingExpense: Expense?
            if let idString = values[safe: headers.firstIndex(of: "ID")], 
               let uuid = UUID(uuidString: idString) {
                let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                existingExpense = try? viewContext.fetch(fetchRequest).first
            }
            
            // 创建或更新记录
            let expense = existingExpense ?? Expense(context: viewContext)
            
            // 设置UUID
            if expense.id == nil {
                expense.id = UUID()
            }
            
            // 设置标题
            if let titleIndex = headers.firstIndex(of: "标题"), 
               let title = values[safe: titleIndex] {
                expense.title = title.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置金额
            if let amountIndex = headers.firstIndex(of: "金额"), 
               let amountStr = values[safe: amountIndex],
               let amount = Double(amountStr) {
                expense.amount = amount
            }
            
            // 设置是否支出
            if let isExpenseIndex = headers.firstIndex(of: "是否支出"), 
               let isExpenseStr = values[safe: isExpenseIndex] {
                expense.isExpense = isExpenseStr.contains("是")
            }
            
            // 设置日期
            if let dateIndex = headers.firstIndex(of: "日期"), 
               let dateStr = values[safe: dateIndex],
               let date = dateFormatter.date(from: dateStr) {
                expense.date = date
            } else {
                expense.date = Date()
            }
            
            // 设置备注
            if let noteIndex = headers.firstIndex(of: "备注"), 
               let note = values[safe: noteIndex] {
                expense.note = note.replacingOccurrences(of: "\"", with: "")
            }
            
            // 关联联系人
            if let contactIDIndex = headers.firstIndex(of: "联系人ID"), 
               let contactIDString = values[safe: contactIDIndex],
               !contactIDString.isEmpty,
               let contactUUID = UUID(uuidString: contactIDString) {
                let fetchRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", contactUUID as CVarArg)
                if let contact = try? viewContext.fetch(fetchRequest).first {
                    expense.contact = contact
                }
            }
            
            // 关联储蓄目标
            if let goalIDIndex = headers.firstIndex(of: "储蓄目标ID"), 
               let goalIDString = values[safe: goalIDIndex],
               !goalIDString.isEmpty,
               let goalUUID = UUID(uuidString: goalIDString) {
                let fetchRequest: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", goalUUID as CVarArg)
                if let goal = try? viewContext.fetch(fetchRequest).first {
                    expense.goal = goal
                }
            }
            
            // 设置创建时间
            if let createdAtIndex = headers.firstIndex(of: "创建时间"), 
               let createdAtStr = values[safe: createdAtIndex],
               let createdAt = dateFormatter.date(from: createdAtStr) {
                expense.createdAt = createdAt
            } else {
                expense.createdAt = Date()
            }
            
            // 设置更新时间
            if let updatedAtIndex = headers.firstIndex(of: "更新时间"), 
               let updatedAtStr = values[safe: updatedAtIndex],
               let updatedAt = dateFormatter.date(from: updatedAtStr) {
                expense.updatedAt = updatedAt
            } else {
                expense.updatedAt = Date()
            }
            
            importedCount += 1
        }
    }
    
    // 处理储蓄目标数据
    private func processSavingsGoalData(headerLine: String, dataLines: [String]) {
        let headers = parseCSVHeaders(headerLine)
        
        for line in dataLines {
            let values = parseCSVLine(line)
            guard values.count >= 5 else { 
                failedCount += 1
                continue 
            }
            
            // 检查是否已存在相同ID的记录
            var existingGoal: SavingsGoal?
            if let idString = values[safe: headers.firstIndex(of: "ID")], 
               let uuid = UUID(uuidString: idString) {
                let fetchRequest: NSFetchRequest<SavingsGoal> = SavingsGoal.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
                existingGoal = try? viewContext.fetch(fetchRequest).first
            }
            
            // 创建或更新记录
            let goal = existingGoal ?? SavingsGoal(context: viewContext)
            
            // 设置UUID
            if goal.id == nil {
                goal.id = UUID()
            }
            
            // 设置标题
            if let titleIndex = headers.firstIndex(of: "标题"), 
               let title = values[safe: titleIndex] {
                goal.title = title.replacingOccurrences(of: "\"", with: "")
            }
            
            // 设置目标金额
            if let targetAmountIndex = headers.firstIndex(of: "目标金额"), 
               let targetAmountStr = values[safe: targetAmountIndex],
               let targetAmount = Double(targetAmountStr) {
                goal.targetAmount = targetAmount
            }
            
            // 设置当前金额
            if let currentAmountIndex = headers.firstIndex(of: "当前金额"), 
               let currentAmountStr = values[safe: currentAmountIndex],
               let currentAmount = Double(currentAmountStr) {
                goal.currentAmount = currentAmount
            }
            
            // 设置截止日期
            if let deadlineIndex = headers.firstIndex(of: "截止日期"), 
               let deadlineStr = values[safe: deadlineIndex],
               let deadline = dateFormatter.date(from: deadlineStr) {
                goal.deadline = deadline
            }
            
            // 设置创建时间
            if let createdAtIndex = headers.firstIndex(of: "创建时间"), 
               let createdAtStr = values[safe: createdAtIndex],
               let createdAt = dateFormatter.date(from: createdAtStr) {
                goal.createdAt = createdAt
            } else {
                goal.createdAt = Date()
            }
            
            // 设置更新时间
            if let updatedAtIndex = headers.firstIndex(of: "更新时间"), 
               let updatedAtStr = values[safe: updatedAtIndex],
               let updatedAt = dateFormatter.date(from: updatedAtStr) {
                goal.updatedAt = updatedAt
            } else {
                goal.updatedAt = Date()
            }
            
            importedCount += 1
        }
    }
    
    // 导入TXT格式数据
    private func importTXTData(_ content: String, completion: @escaping (Bool, String) -> Void) {
        // 按日期和内容分段解析
        let lines = content.components(separatedBy: .newlines)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var currentItem: Item?
        var importedCount = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 跳过空行和分隔线
                if trimmedLine.isEmpty || trimmedLine.contains("---") {
                    continue
                }
                
                // 检查是否是日期标题行
                if trimmedLine.hasPrefix("【") && trimmedLine.contains("】") {
                    // 保存之前的条目
                    if let item = currentItem {
                        try? self.viewContext.save()
                        importedCount += 1
                    }
                    
                    // 创建新条目
                    currentItem = Item(context: self.viewContext)
                    currentItem?.id = UUID()
                    currentItem?.createdAt = Date()
                    currentItem?.updatedAt = Date()
                    
                    // 解析日期和标题
                    let startIndex = trimmedLine.index(after: trimmedLine.startIndex)
                    let endIndex = trimmedLine.firstIndex(of: "】") ?? trimmedLine.endIndex
                    let dateString = String(trimmedLine[startIndex..<endIndex])
                    
                    if let date = dateFormatter.date(from: dateString) {
                        currentItem?.date = date
                    } else {
                        currentItem?.date = Date()
                    }
                    
                    // 解析标题
                    if endIndex < trimmedLine.endIndex {
                        let titleStartIndex = trimmedLine.index(after: endIndex)
                        let title = String(trimmedLine[titleStartIndex...])
                        currentItem?.title = title
                    }
                }
                // 检查是否是天气行
                else if trimmedLine.hasPrefix("天气：") {
                    let weather = trimmedLine.replacingOccurrences(of: "天气：", with: "")
                    currentItem?.weather = weather
                }
                // 检查是否是待办事项行
                else if trimmedLine.contains("待办事项：") {
                    // 跳过待办事项标题行
                    continue
                }
                else if trimmedLine.hasPrefix("[") && (trimmedLine.contains("✓") || trimmedLine.contains("□")) {
                    // 创建待办事项
                    let checkItem = CheckListItem(context: self.viewContext)
                    checkItem.id = UUID()
                    checkItem.isCompleted = trimmedLine.contains("✓")
                    
                    // 解析内容
                    if let contentStart = trimmedLine.firstIndex(of: "]") {
                        let startIndex = trimmedLine.index(after: contentStart)
                        let content = String(trimmedLine[startIndex...]).trimmingCharacters(in: .whitespaces)
                        checkItem.title = content
                    }
                    
                    checkItem.createdAt = Date()
                    checkItem.updatedAt = Date()
                    checkItem.diary = currentItem
                }
                // 否则作为日记内容
                else if let item = currentItem, !trimmedLine.isEmpty {
                    if item.body == nil {
                        item.body = trimmedLine
                    } else {
                        item.body = (item.body ?? "") + "\n" + trimmedLine
                    }
                }
            }
            
            // 保存最后一个条目
            if currentItem != nil {
                importedCount += 1
            }
            
            // 保存所有更改
            do {
                try self.viewContext.save()
                DispatchQueue.main.async {
                    completion(true, "成功导入 \(importedCount) 条日记")
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, "保存数据失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 辅助方法：解析CSV头部
    private func parseCSVHeaders(_ line: String) -> [String] {
        return line.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    // 辅助方法：解析CSV一行
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes = !inQuotes
            } else if char == "," && !inQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // 添加最后一个字段
        result.append(currentField)
        
        return result
    }
}

// 安全数组访问扩展
extension Array {
    subscript(safe index: Int?) -> Element? {
        guard let index = index, indices.contains(index) else { return nil }
        return self[index]
    }
} 