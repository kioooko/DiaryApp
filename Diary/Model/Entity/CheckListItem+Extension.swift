//
//  CheckListItem+Extension.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/06/07.
//

import CoreData

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

    static func create(title: String) throws {
        guard titleRange.contains(title.count) else {
            throw CheckListItemError.validationError
        }

        let now = Date()
        let checkListItem = CheckListItem(context: CoreDataProvider.shared.container.viewContext)

        checkListItem.title = title
        checkListItem.createdAt = now
        checkListItem.updatedAt = now

        try checkListItem.save()
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
