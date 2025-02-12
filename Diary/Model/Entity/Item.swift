import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject, Identifiable {

    @NSManaged public var body: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var isBookmarked: Bool
    @NSManaged public var title: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var weather: String?
    @NSManaged public var checkListItems: NSSet?

}