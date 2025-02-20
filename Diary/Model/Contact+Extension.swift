import Foundation
import CoreData

extension Contact {
    var relationshipTier: RelationshipTier {
        get { RelationshipTier(rawValue: tier) ?? .acquaintance }
        set { tier = newValue.rawValue }
    }
    
    // 用于预览的示例数据
    static var example: Contact {
        let context = PersistenceController.preview.container.viewContext
        let contact = Contact(context: context)
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