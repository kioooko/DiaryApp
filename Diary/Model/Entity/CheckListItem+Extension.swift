//
//  CheckListItem+Extension.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/06/07.
//

import CoreData
import Foundation

extension CheckListItem: BaseModel {

    static func makeRandom(
        context: NSManagedObjectContext = CoreDataProvider.shared.container.viewContext,
        date: Date = Date()
    ) -> CheckListItem {
        let titleSourceString = "窗前明月光"
        var title = ""
        let repeatCountForTitle = Int.random(in: 1...3)
        for _ in 1...repeatCountForTitle {
            title += titleSourceString
        }

        let newItem = CheckListItem(context: context)
        newItem.title = title
        newItem.createdAt = date
        newItem.updatedAt = date

        return newItem
    }

    static func create(title: String, isCompleted: Bool = false, in context: NSManagedObjectContext) -> CheckListItem {
        let item = CheckListItem(context: context)
        item.id = UUID()
        item.title = title
        item.isCompleted = isCompleted
        item.createdAt = Date()
        item.updatedAt = Date()
        return item
    }

    func update(title: String) throws {
        guard CheckListItem.titleRange.contains(title.count) else {
            throw CheckListItemError.validationError
        }

        self.title = title
        self.updatedAt = Date()

        try save()
    }

    // Validation
    static let titleRange = 0...100

    var id: UUID? {
        get { primitiveValue(forKey: "id") as? UUID }
        set { setPrimitiveValue(newValue, forKey: "id") }
    }
    
    var title: String? {
        get { primitiveValue(forKey: "title") as? String }
        set { setPrimitiveValue(newValue, forKey: "title") }
    }
    
    var isCompleted: Bool {
        get { (primitiveValue(forKey: "isCompleted") as? Bool) ?? false }
        set { setPrimitiveValue(newValue, forKey: "isCompleted") }
    }
    
    var createdAt: Date? {
        get { primitiveValue(forKey: "createdAt") as? Date }
        set { setPrimitiveValue(newValue, forKey: "createdAt") }
    }
    
    var updatedAt: Date? {
        get { primitiveValue(forKey: "updatedAt") as? Date }
        set { setPrimitiveValue(newValue, forKey: "updatedAt") }
    }
    
    var diary: Item? {
        get { primitiveValue(forKey: "diary") as? Item }
        set { setPrimitiveValue(newValue, forKey: "diary") }
    }
    
    // 确保在创建时生成UUID
    @objc func awakeFromInsert() {
        super.awakeFromInsert()
        
        if id == nil {
            id = UUID()
        }
        
        if createdAt == nil {
            createdAt = Date()
        }
        
        if updatedAt == nil {
            updatedAt = Date()
        }
    }
}

public enum CheckListItemError: Error, LocalizedError {
    case validationError

    public var errorDescription: String? {
        switch self {
        case .validationError:
            return "输入的内容格式好像有问题诶"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .validationError:
            return "请确认好内容格式后、再试一次吧"
        }
    }
}
