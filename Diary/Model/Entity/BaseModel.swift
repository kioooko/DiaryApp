//
//  BaseModel.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/24.
//

import CloudKit
import CoreData

protocol BaseModel {
    func delete() throws
    func save() throws
}

extension BaseModel where Self: NSManagedObject {

    static var all: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: String(describing: self))
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return request
    }

    static func count() throws -> Int {
        let request = NSFetchRequest<Self>(entityName: String(describing: self))
        request.sortDescriptors = []
        do {
            let count = try CoreDataProvider.shared.container.viewContext.count(for: request)
            return count
        } catch {
            throw BaseModelError.databaseOperationError(error: error)
        }
    }

    func delete() throws {
        CoreDataProvider.shared.container.viewContext.delete(self)
        do {
            try save()
        } catch {
            try handleOperationError(error)
        }
    }

    func save() throws {
        do {
            try CoreDataProvider.shared.container.viewContext.save()
        } catch {
            try handleOperationError(error)
        }
    }

    private func handleOperationError(_ error: Error) throws {
        if let ckError = error as? CKError {
            if ckError.code == CKError.Code.serverRejectedRequest {
                throw BaseModelError.needToCheckSpace(error: error)
            }
            throw BaseModelError.databaseOperationError(error: error)
        } else {
            throw BaseModelError.databaseOperationError(error: error)
        }
    }
}

public enum BaseModelError: Error, LocalizedError {
    case databaseOperationError(error: Error?)
    case needToCheckSpace(error: Error?)

    public var errorDescription: String? {
        switch self {
        case .databaseOperationError:
            return "失败啦☹️"
        case .needToCheckSpace:
            return "失败啦☹️"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .databaseOperationError(let error):
            print(error?.localizedDescription ?? "")
            return "发生了一些问题、麻烦再试一次吧"
        case .needToCheckSpace:
            return "iCloud没有关联成功。请确认一下设置和iCloud的储存容量。"
        }
    }
}
