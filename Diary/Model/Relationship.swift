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

// 移除 Contact 类定义，使用 CoreData 生成的类 