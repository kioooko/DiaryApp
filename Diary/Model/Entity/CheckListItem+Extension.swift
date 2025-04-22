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

    // 确保在创建时生成UUID
    @objc public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        if self.primitiveValue(forKey: "id") == nil {
            self.setPrimitiveValue(UUID(), forKey: "id")
        }
        
        if self.primitiveValue(forKey: "createdAt") == nil {
            self.setPrimitiveValue(Date(), forKey: "createdAt")
        }
        
        if self.primitiveValue(forKey: "updatedAt") == nil {
            self.setPrimitiveValue(Date(), forKey: "updatedAt")
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
