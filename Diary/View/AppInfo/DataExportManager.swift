import Foundation
import CoreData
import SwiftUI

class DataExportManager {
    let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }
    
    // 导出所有数据为CSV格式
    func exportAllDataAsCSV() -> String {
        // 日期格式化器
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter
        }()
        
        var csvContent = ""
        
        // 1. 日记数据表
        csvContent += "=== 日记数据 ===\n"
        csvContent += "ID,标题,内容,日期,是否收藏,天气,图片URL,备注,创建时间,更新时间\n"
        
        let items = CoreDataProvider.shared.exportAllDiaryEntries()
        for item in items {
            let dateStr = item.date.map { dateFormatter.string(from: $0) } ?? ""
            let createdAtStr = item.createdAt.map { dateFormatter.string(from: $0) } ?? ""
            let updatedAtStr = item.updatedAt.map { dateFormatter.string(from: $0) } ?? ""
            
            // 确保字段中的逗号不会破坏CSV格式
            let title = (item.title ?? "").replacingOccurrences(of: ",", with: "，")
            let body = (item.body ?? "").replacingOccurrences(of: ",", with: "，")
            let weather = (item.weather ?? "").replacingOccurrences(of: ",", with: "，")
            let note = (item.note ?? "").replacingOccurrences(of: ",", with: "，")
            let imageURL = (item.imageURL ?? "").replacingOccurrences(of: ",", with: "，")
            
            let row = [
                item.id?.uuidString ?? UUID().uuidString,
                "\"\(title)\"",
                "\"\(body)\"",
                dateStr,
                item.isBookmarked ? "是" : "否",
                "\"\(weather)\"",
                "\"\(imageURL)\"",
                "\"\(note)\"",
                createdAtStr,
                updatedAtStr
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        csvContent += "\n\n"
        
        // 2. 待办事项数据表
        csvContent += "=== 待办事项数据 ===\n"
        csvContent += "ID,标题,是否完成,对应日记ID,创建时间,更新时间\n"
        
        let checkListItems = CoreDataProvider.shared.fetchAllCheckListItems()
        for item in checkListItems {
            let createdAtStr = item.createdAt.map { dateFormatter.string(from: $0) } ?? ""
            let updatedAtStr = item.updatedAt.map { dateFormatter.string(from: $0) } ?? ""
            
            // 确保字段中的逗号不会破坏CSV格式
            let title = (item.title ?? "").replacingOccurrences(of: ",", with: "，")
            
            let row = [
                item.id?.uuidString ?? UUID().uuidString,
                "\"\(title)\"",
                item.isCompleted ? "是" : "否",
                item.diary?.id?.uuidString ?? "",
                createdAtStr,
                updatedAtStr
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        csvContent += "\n\n"
        
        // 3. 联系人数据表
        csvContent += "=== 联系人数据 ===\n"
        csvContent += "ID,姓名,关系层级,生日,备注,最近联系时间,头像URL,创建时间,更新时间\n"
        
        let contacts = CoreDataProvider.shared.fetchAllContacts()
        for contact in contacts {
            let birthdayStr = contact.birthday.map { dateFormatter.string(from: $0) } ?? ""
            let lastInteractionStr = contact.lastInteraction.map { dateFormatter.string(from: $0) } ?? ""
            let createdAtStr = contact.createdAt.map { dateFormatter.string(from: $0) } ?? ""
            let updatedAtStr = contact.updatedAt.map { dateFormatter.string(from: $0) } ?? ""
            
            // 确保字段中的逗号不会破坏CSV格式
            let name = (contact.name ?? "").replacingOccurrences(of: ",", with: "，")
            let notes = (contact.notes ?? "").replacingOccurrences(of: ",", with: "，")
            let avatarURL = (contact.avatarURL ?? "").replacingOccurrences(of: ",", with: "，")
            
            let row = [
                contact.id?.uuidString ?? UUID().uuidString,
                "\"\(name)\"",
                String(contact.tier),
                birthdayStr,
                "\"\(notes)\"",
                lastInteractionStr,
                "\"\(avatarURL)\"",
                createdAtStr,
                updatedAtStr
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        csvContent += "\n\n"
        
        // 4. 支出记录数据表
        csvContent += "=== 支出记录数据 ===\n"
        csvContent += "ID,标题,金额,是否支出,日期,备注,联系人ID,储蓄目标ID,创建时间,更新时间\n"
        
        let expenses = CoreDataProvider.shared.fetchAllExpenses()
        for expense in expenses {
            let dateStr = expense.date.map { dateFormatter.string(from: $0) } ?? ""
            let createdAtStr = expense.createdAt.map { dateFormatter.string(from: $0) } ?? ""
            let updatedAtStr = expense.updatedAt.map { dateFormatter.string(from: $0) } ?? ""
            
            // 确保字段中的逗号不会破坏CSV格式
            let title = (expense.title ?? "").replacingOccurrences(of: ",", with: "，")
            let note = (expense.note ?? "").replacingOccurrences(of: ",", with: "，")
            
            let row = [
                expense.id?.uuidString ?? UUID().uuidString,
                "\"\(title)\"",
                String(expense.amount),
                expense.isExpense ? "是" : "否",
                dateStr,
                "\"\(note)\"",
                expense.contact?.id?.uuidString ?? "",
                expense.goal?.id?.uuidString ?? "",
                createdAtStr,
                updatedAtStr
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        csvContent += "\n\n"
        
        // 5. 储蓄目标数据表
        csvContent += "=== 储蓄目标数据 ===\n"
        csvContent += "ID,标题,目标金额,当前金额,截止日期,创建时间,更新时间\n"
        
        let savingsGoals = CoreDataProvider.shared.fetchAllSavingsGoals()
        for goal in savingsGoals {
            let deadlineStr = goal.deadline.map { dateFormatter.string(from: $0) } ?? ""
            let createdAtStr = goal.createdAt.map { dateFormatter.string(from: $0) } ?? ""
            let updatedAtStr = goal.updatedAt.map { dateFormatter.string(from: $0) } ?? ""
            
            // 确保字段中的逗号不会破坏CSV格式
            let title = (goal.title ?? "").replacingOccurrences(of: ",", with: "，")
            
            let row = [
                goal.id?.uuidString ?? UUID().uuidString,
                "\"\(title)\"",
                String(goal.targetAmount),
                String(goal.currentAmount),
                deadlineStr,
                createdAtStr,
                updatedAtStr
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        return csvContent
    }
    
    // 导出为简化的TXT格式（仅包含日记）
    func exportDiaryAsTXT() -> String {
        // 日期格式化器
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.timeZone = TimeZone.current
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter
        }()
        
        var txtContent = "=== 我的日记 ===\n\n"
        
        // 按日期分组的日记
        let items = CoreDataProvider.shared.exportAllDiaryEntries().sorted {
            ($0.date ?? Date()) > ($1.date ?? Date())
        }
        
        for item in items {
            let dateStr = item.date.map { dateFormatter.string(from: $0) } ?? "未知日期"
            
            txtContent += "【\(dateStr)】\(item.title ?? "")\n"
            if let body = item.body, !body.isEmpty {
                txtContent += "\(body)\n"
            }
            
            // 添加天气
            if let weather = item.weather, !weather.isEmpty {
                txtContent += "天气：\(weather)\n"
            }
            
            // 添加代办事项
            if let checkListItems = item.checkListItems as? Set<CheckListItem>, !checkListItems.isEmpty {
                txtContent += "\n待办事项：\n"
                
                let sortedItems = checkListItems.sorted {
                    ($0.createdAt ?? Date()) < ($1.createdAt ?? Date())
                }
                
                for checkItem in sortedItems {
                    let statusMark = checkItem.isCompleted ? "✓" : "□"
                    txtContent += "[\(statusMark)] \(checkItem.title ?? "")\n"
                }
            }
            
            txtContent += "\n----------------------------\n\n"
        }
        
        return txtContent
    }
} 