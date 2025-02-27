import Foundation
import CoreData
import SwiftUI

@available(iOS 13.0, *)
extension Contact {
    var relationshipTier: RelationshipTier {
        get { RelationshipTier(rawValue: tier) ?? .acquaintance }
        set { tier = newValue.rawValue }
    }
    
    // 用于预览的示例数据
    static var example: Contact {
        let viewContext = NSPersistentContainer(name: "Diary 2").viewContext
        let contact = Contact(context: viewContext)
        contact.id = UUID()
        contact.name = "示例联系人"
        contact.tier = RelationshipTier.core.rawValue
        contact.birthday = Date()
        contact.notes = "这是一个示例联系人"
        contact.lastInteraction = Date()
        contact.createdAt = Date()
        contact.updatedAt = Date()
        return contact
    }
} 
