//
//  Item+Extension.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/24.
//

import CoreData// 导入 CoreData 框架
import SwiftUI// 导入 SwiftUI 框架

extension Item {
    /*
     NSManagedObject 是 ObservableObject 的子类，但未使用 Published 等属性来通知属性更改，因此需要重写 objectWillChange.send() 方法
     https://developer.apple.com/forums/thread/121897
     */
    override public func willChangeValue(forKey key: String) {// 重写 willChangeValue(forKey:) 方法，用于在属性更改时发送通知   
        super.willChangeValue(forKey: key)// 调用父类的 willChangeValue(forKey:) 方法
        self.objectWillChange.send()// 发送通知
    }
}

extension Item: BaseModel {// 定义一个 Item 的扩展，用于实现 BaseModel 协议
// 定义一个静态方法 makeRandom，用于创建一个随机的 Item 对象
// 创建一个 NSManagedObjectContext 对象
    static func makeRandom(
        context: NSManagedObjectContext = CoreDataProvider.shared.container.viewContext,
        date: Date = Date(),
        withImage: Bool = false// 设置日期为当前日期// 设置是否包含图片
    ) -> Item {// 返回一个 Item 对象
        let titleSourceString = "あ漢1"// 设置标题源字符串
        var title = ""// 设置标题为空字符串
        let repeatCountForTitle = Int.random(in: 1...3)// 设置标题重复次数
        for _ in 1...repeatCountForTitle {// 遍历标题重复次数
            title += titleSourceString// 将标题源字符串添加到标题中
        }

        let bodySourceString = "AaGgYyQq123あいうえお漢字カタカナ@+"// 设置正文源字符串
        var body = ""// 设置正文为空字符串
        let repeatCountForBody = Int.random(in: 1...10)// 设置正文重复次数
        for _ in 1...repeatCountForBody {// 遍历正文重复次数
            body += bodySourceString// 将正文源字符串添加到正文中
        }

        let newItem = Item(context: context)// 创建一个 Item 对象
        newItem.title = title// 设置标题
        newItem.body = body// 设置正文
        newItem.date = date// 设置日期
        newItem.createdAt = Date()// 设置创建时间为当前时间
        newItem.isBookmarked = Bool.random()// 设置是否为书签
        newItem.updatedAt = Date()// 设置更新时间为当前时间
        newItem.weather = "sun.max"// 设置天气为晴天

        if withImage {// 如果包含图片
            let image: Data = UIImage(named: "sample")!.jpegData(compressionQuality: 0.5)!// 创建一个 UIImage 对象，并将其转换为 Data 对象
            newItem.imageData = image// 设置图片数据
        } else {
            newItem.imageData = nil// 设置图片数据为 nil
        }
        return newItem // 返回新的 Item 对象
    }
// 定义一个静态方法 makeWithOnlyCheckList，用于创建一个包含 CheckListItem 的 Item 对象
// 创建一个 NSManagedObjectContext 对象 
    static func makeWithOnlyCheckList(
        context: NSManagedObjectContext = CoreDataProvider.shared.container.viewContext,
        date: Date = Date(),
        withImage: Bool = false// 设置日期为当前日期 // 设置是否包含图片
    ) -> Item {// 返回一个 Item 对象
        let newItem = Item(context: context)// 创建一个 Item 对象
        newItem.title = "Hi🦄"// 设置标题
        newItem.body = ""// 设置正文
        newItem.date = date// 设置日期
        newItem.createdAt = Date()// 设置创建时间为当前时间
        newItem.isBookmarked = Bool.random()// 设置是否为书签
        newItem.updatedAt = Date()// 设置更新时间为当前时间
        newItem.weather = "sun.max"// 设置天气为晴天

        if withImage {
            let image: Data = UIImage(named: "sample")!.jpegData(compressionQuality: 0.5)!// 创建一个 UIImage 对象，并将其转换为 Data 对象
            newItem.imageData = image// 设置图片数据
        } else {
            newItem.imageData = nil// 设置图片数据为 nil
        }

        let checkListCount = Int.random(in: 1...10)
        var checkListItems: [CheckListItem] = []
        for _ in 0...checkListCount {
            checkListItems.append(.makeRandom())// 创建一个随机的 CheckListItem 对象，并将其添加到 checkListItems 数组中
        }
        newItem.checkListItems = NSSet(array: checkListItems)// 设置 checkListItems 为 NSSet 对象

        return newItem// 返回新的 Item 对象
    }

    static var allSortedByDate: NSFetchRequest<Item> {// 定义一个静态方法，返回一个 NSFetchRequest 对象，用于获取所有 Item 对象，并按日期排序
        let request = NSFetchRequest<Item>(entityName: String(describing: self))// 创建一个 NSFetchRequest 对象，用于获取 Item 实体
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]// 设置排序描述符，按日期降序排序    
        return request// 返回 NSFetchRequest 对象
    }

    static var thisMonth: NSFetchRequest<Item> {// 定义一个静态方法，返回一个 NSFetchRequest 对象，用于获取当前月份的 Item 对象 
        let request: NSFetchRequest<Item> = Item.fetchRequest()// 创建一个 NSFetchRequest 对象，用于获取 Item 实体
        let now = Date()// 设置当前日期
        // TODO: ここの後半、date <= %@ でいいのでは
        request.predicate = NSPredicate(// 设置谓词，用于过滤 Item 对象
            format: "date >= %@ && date < %@",// 设置谓词格式，用于过滤 Item 对象
            now.startOfMonth! as CVarArg,// 设置谓词参数，用于过滤 Item 对象
            now.endOfMonth! as CVarArg// 设置谓词参数，用于过滤 Item 对象
        )// 设置谓词
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]// 设置排序描述符，按日期降序排序
        return request// 返回 NSFetchRequest 对象
    }

    static var bookmarks: NSFetchRequest<Item> {// 定义一个静态方法，返回一个 NSFetchRequest 对象，用于获取所有书签的 Item 对象
        let request: NSFetchRequest<Item> = Item.fetchRequest()// 创建一个 NSFetchRequest 对象，用于获取 Item 实体
        request.predicate = NSPredicate(// 设置谓词，用于过滤 Item 对象
            format: "isBookmarked == true"// 设置谓词格式，用于过滤 Item 对象
        )// 设置谓词
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]// 设置排序描述符，按日期降序排序
        return request// 返回 NSFetchRequest 对象
    }

    static var thisMonthItemsCount: Int {// 定义一个静态方法，返回一个 Int 对象，用于获取当前月份的 Item 对象的数量
        let fetchRequest = Item.thisMonth// 获取当前月份的 Item 对象
        do {// 执行以下代码 
            let context: NSManagedObjectContext = CoreDataProvider.shared.container.viewContext// 创建一个 NSManagedObjectContext 对象
            let thisMonthItemCount = try context.count(for: fetchRequest)// 获取当前月份的 Item 对象的数量
            return thisMonthItemCount// 返回当前月份的 Item 对象的数量  
        } catch {// 捕获错误
            print("⚠️ Failed to fetch item count: \(error)")// 打印错误信息
            return 0// 返回 0
        }
    }

    static func items(of dateInterval: DateInterval) -> NSFetchRequest<Item> {// 定义一个静态方法，返回一个 NSFetchRequest 对象，用于获取指定日期区间的 Item 对象
        let request: NSFetchRequest<Item> = Item.fetchRequest()// 创建一个 NSFetchRequest 对象，用于获取 Item 实体
        request.predicate = NSPredicate(// 设置谓词，用于过滤 Item 对象
            format: "date >= %@ && date <= %@",// 设置谓词格式，用于过滤 Item 对象
            dateInterval.start as CVarArg,// 设置谓词参数，用于过滤 Item 对象
            dateInterval.end as CVarArg// 设置谓词参数，用于过滤 Item 对象
        )// 设置谓词
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]// 设置排序描述符，按日期降序排序
        return request// 返回 NSFetchRequest 对象
    }

    static var hasTodayItem: Bool {// 定义一个静态方法，返回一个 Bool 对象，用于判断今天是否有 Item 对象
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()// 创建一个 NSFetchRequest 对象，用于获取 Item 实体
        fetchRequest.fetchLimit = 1// 设置 fetchLimit 为 1

        let context: NSManagedObjectContext = CoreDataProvider.shared.container.viewContext

        // Get today's date at start of day
        let calendar = Calendar.current// 创建一个 Calendar 对象
        let startOfDay = calendar.startOfDay(for: Date())// 获取今天的开始时间

        // Set predicate to fetch items created today
        fetchRequest.predicate = NSPredicate(// 设置谓词，用于过滤 Item 对象
            format: "(createdAt >= %@ ) AND (createdAt < %@)",// 设置谓词格式，用于过滤 Item 对象
            argumentArray: [startOfDay, calendar.date(byAdding: .day, value: 1, to: startOfDay)!]// 设置谓词参数，用于过滤 Item 对象
        )// 设置谓词

        do {// 执行以下代码
            let items = try context.fetch(fetchRequest)// 获取今天的 Item 对象
            return !items.isEmpty// 返回今天的 Item 对象是否为空
        } catch {// 捕获错误
            print("Failed to fetch items: \(error)")// 打印错误信息
            return false// 返回 false
        }
    }

    /**
     今日までの継続日数を算出する。
     作成日をもとに算出している。従って毎日"いつかの"日記を書いていれば継続日数は増加する。
     今日未作成の場合は昨日までの継続日数を出力
     */
    static func calculateConsecutiveDays(_ context: NSManagedObjectContext = CoreDataProvider.shared.container.viewContext) throws -> Int {
        let request = allSortedByDate
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        var items = try context.fetch(request)
        
        // 过滤掉 createdAt 为 nil 的记录
        items = items.filter { $0.createdAt != nil }
        
        guard !items.isEmpty,
              let latestItemDate = items.first?.createdAt
        else { return 0 }
        
        var count = 0
        let now = Date()

        // 最新的Item与今日的日期差
        let dayDiffBetweenLatestItemAndNow = Calendar.current.dateComponents([.day], from: latestItemDate, to: now).day

        let hasTodayItem = dayDiffBetweenLatestItemAndNow == 0
        if hasTodayItem {
            items.removeFirst()
        }

        for item in items {
            guard let itemCreatedAt = item.createdAt else { continue }  // 安全处理
            let currentItemDateStartOfDay = Calendar.current.startOfDay(for: itemCreatedAt)
            let expectedDate = Calendar.current.date(byAdding: .day, value: -(count + 1), to: now)!
            let expectedStartOfDay = Calendar.current.startOfDay(for: expectedDate)

            let dayDiffBetweenCurrentItemAndExpected = Calendar.current.dateComponents(
                [.day],
                from: currentItemDateStartOfDay,
                to: expectedStartOfDay
            ).day

            if dayDiffBetweenCurrentItemAndExpected == 0 {
                count += 1
            } else if dayDiffBetweenCurrentItemAndExpected == -1 {
                continue
            } else {
                break
            }
        }

        return hasTodayItem ? count + 1 : count
    }

    static func create(
        date: Date,
        title: String,
        body: String,
        isBookmarked: Bool = false,
        weather: String,
        imageData: Data?,
        checkListItems: [CheckListItem]
    ) throws {

        guard titleRange.contains(title.count) else {
            throw ItemError.validationError
        }

        guard !checkListItems.isEmpty || !body.isEmpty else {
            throw ItemError.validationError
        }

        if !body.isEmpty {
            guard textRange.contains(body.count) else {
                throw ItemError.validationError
            }
        }

        let now = Date()
        let diaryItem = Item(context: CoreDataProvider.shared.container.viewContext)

        diaryItem.date = date
        diaryItem.title = title
        diaryItem.body = body
        diaryItem.createdAt = now
        diaryItem.updatedAt = now
        diaryItem.isBookmarked = isBookmarked
        diaryItem.weather = weather
        diaryItem.checkListItems = NSSet(array: checkListItems)

        if let imageData {
            diaryItem.imageData = imageData
        }

        try diaryItem.save()
    }

    var checkListItemsArray: [CheckListItem] {
        let set = checkListItems as? Set<CheckListItem> ?? []
        return set.sorted {
            $0.createdAt! < $1.createdAt!
        }
    }

    // Validation
    static let titleRange = 1...1000
    static let textRange = 0...10000
}

public enum ItemError: Error, LocalizedError {
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
