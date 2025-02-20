import Foundation
import CoreData

enum RelationshipTier: Int16, CaseIterable {
    case core = 0           // 核心圈 (5人)
    case intimate = 1       // 亲密朋友圈 (15人)
    case social = 2         // 社交朋友圈 (50人)
    case acquaintance = 3   // 熟人圈 (150人)
    case weak = 4          // 弱连接圈 (500人)
    
    var title: String {
        switch self {
        case .core: return "核心圈"
        case .intimate: return "亲密朋友圈"
        case .social: return "社交朋友圈"
        case .acquaintance: return "熟人圈"
        case .weak: return "弱连接圈"
        }
    }
    
    var limit: Int {
        switch self {
        case .core: return 5
        case .intimate: return 15
        case .social: return 50
        case .acquaintance: return 150
        case .weak: return 500
        }
    }
}

@objc(Contact)
class Contact: NSManagedObject {
   // @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var avatar: Data?
    @NSManaged var tier: Int16
    @NSManaged var birthday: Date?
    @NSManaged var notes: String?
    @NSManaged var lastInteraction: Date?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    var relationshipTier: RelationshipTier {
        get { RelationshipTier(rawValue: tier) ?? .acquaintance }
        set { tier = newValue.rawValue }
    }
}