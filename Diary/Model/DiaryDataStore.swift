//
//  DiaryDataStore.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/01.
//

import Combine// 导入 Combine 框架
import CoreData// 导入 CoreData 框架
import Foundation// 导入 Foundation 框架
import _PhotosUI_SwiftUI// 导入 PhotosUI 框架
import UIKit// 导入 UIKit 框架

// MARK: - PersistenceController
struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Diary")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ CoreData 加载失败: \(error.localizedDescription)")
                fatalError("无法加载 CoreData 存储: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ CoreData 保存失败: \(error)")
                context.rollback()
            }
        }
    }
}

/**
 Diary item関連の状態、ロジックを保持するclass
 Itemの作成や編集などの画面で利用できる

 Itemエンティティにロジックを集約させても良かったが、すでに作成済みであるコンテンツの編集画面を考える際、
 元のデータと、それによって初期化された変数をViewで保持する必要があった。その際にinitでStateを初期化すると、initに渡している値が
 変わってもViewが再描画されることはない（initは初期化時のみ動作する）ので、Bindingとして持つ必要がある。
 ・そうなった場合、Itemのプロパティ分だけViewの変数が増える
 ・また、入力情報を保持するものはItem作成機能でも利用でき、Viewの状態を分割でき見通しが良くなる
 以上の理由から本Modelを作成した。
 */
@MainActor
public class DiaryDataStore: ObservableObject {

    /*
     Publishedの利用について
     title, bodyTextはValidation結果を伝達するために利用
     selectedDate, selectedImageはpickerの選択結果を伝達するために利用
     */
    @Published var title = ""
    @Published var bodyText = ""
    @Published var selectedDate: Date = Date()
    @Published var selectedImage: UIImage?
    @Published var checkListItems: [CheckListItem] = []
    @Published var id: UUID

    var isBookmarked = false
    var selectedWeather: WeatherSymbol = .sun
    var selectedPickerItem: PhotosPickerItem?

    internal var originalItem: Item?
    private var originalItemImage: UIImage?
    private let context: NSManagedObjectContext

    /*
     新規作成の場合はまだItemを生成していないのでnil。
     編集などの場合は対象のItemを渡すことで更新可能。
     */
    init(item: Item? = nil) {
        self.context = PersistenceController.shared.container.viewContext
        self.originalItem = item
        
        if let item = item {
            self.id = item.id ?? UUID()
            self.title = item.title ?? ""
            self.bodyText = item.body ?? ""
            self.selectedDate = item.date ?? Date()
            self.selectedWeather = WeatherSymbol.make(from: item.weather ?? "sun.max")
            self.isBookmarked = item.isBookmarked
            
            if let imageData = item.imageData {
                self.selectedImage = UIImage(data: imageData)
            }
            
            if let checkListItems = item.checkListItems?.allObjects as? [CheckListItem] {
                self.checkListItems = checkListItems
            }
        } else {
            self.id = UUID()
            // 设置其他默认值
            self.selectedDate = Date()
            self.selectedWeather = .sun
            self.isBookmarked = false
        }
    }

    // MARK: Validation

    /*
     @Published 属性プロパティを扱っている場合は、その変更により再計算される
     */

    var canCreate: Bool {
        validTitle && validContent
    }

    var validTitle: Bool {
        title.count >= Item.titleRange.lowerBound &&
        title.count <= Item.titleRange.upperBound
    }

    /**
     何れかのチェックリストがチェック済み or テキストが設定済みであればtrue
     */
    var validContent: Bool {
        if checkListItems.isEmpty {
            return bodyText.count > Item.textRange.lowerBound
            && bodyText.count <= Item.textRange.upperBound
        } else {
            return bodyText.count <= Item.textRange.upperBound
        }
    }

    // MARK: func

    @discardableResult
    func updateValuesWithOriginalData() -> Bool {
        guard let item = originalItem else {
            originalItemImage = nil
            return false
        }

        // Update values

        if let date = item.date {
            self.selectedDate = date
        } else {
            self.selectedDate = Date()
        }

        if let title = item.title {
            self.title = title
        }

        if let body = item.body {
            self.bodyText = body
        }

        self.isBookmarked = item.isBookmarked

        if let weather = item.weather {
            self.selectedWeather = WeatherSymbol.make(from: weather)
        }

        if let imageData = item.imageData,
           let uiImage = UIImage(data: imageData) {
            self.originalItemImage = uiImage
            self.selectedImage = uiImage
        } else {
            originalItemImage = nil
        }

        if !item.checkListItemsArray.isEmpty {
            self.checkListItems = item.checkListItemsArray
        }

        return  true
    }

    func create() throws {
        guard canCreate else {
            throw DiaryDataStoreError.notValidData
        }

        var imageData: Data?
        if let selectedImage {
            imageData = selectedImage.jpegData(compressionQuality: 0.5)
        }

        try Item.create(
            date: Calendar.current.startOfDay(for: selectedDate),
            title: title,
            body: bodyText,
            weather: selectedWeather.symbol,
            imageData: imageData,
            checkListItems: checkListItems
        )
    }

    func delete() throws {
        guard let originalItem else {
            throw DiaryDataStoreError.notFoundItem
        }

        try originalItem.delete()
    }

    func update() throws {
        do {
            let item: Item
            if let existingItem = originalItem {
                item = existingItem
            } else {
                item = Item(context: context)
            }
            
            // 更新项目
            item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            item.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
            item.date = selectedDate
            item.weather = selectedWeather.symbol
            item.isBookmarked = isBookmarked
            item.updatedAt = Date()
            
            // 处理图片
            if let image = selectedImage {
                if let resizedImage = image.resizeImage(to: CGSize(width: 1024, height: 1024)) {
                    item.imageData = resizedImage.jpegData(compressionQuality: 0.8)
                } else {
                    item.imageData = image.jpegData(compressionQuality: 0.8)
                }
            } else {
                item.imageData = nil
            }
            
            // 验证并保存
            try validateItem()
            try context.save()
            
        } catch {
            print("❌ 保存失败: \(error.localizedDescription)")
            context.rollback()
            throw DiaryDataStoreError.notValidData
        }
    }
    
    private func validateItem() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DiaryDataStoreError.notValidData
        }
    }

    /**
     Update bookmark state(on/off)

     This is used for already created item.
     */
    func updateBookmarkState() throws {
        guard let originalItem else {
            throw DiaryDataStoreError.notFoundItem
        }

        if originalItem.isBookmarked != isBookmarked {
            let updatedItem = originalItem
            updatedItem.isBookmarked = isBookmarked
            try saveItem()
        }
    }

    func updateCheckListItemState(of item: CheckListItem) {
        if let foundItem = checkListItems.first(where: { $0.objectID == item.objectID
        }) {
            checkListItems.removeAll(where: {
                $0.objectID == foundItem.objectID
            })
        } else {
            checkListItems.append(item)
        }
    }

    private func saveItem() throws {
        guard let originalItem else {
            throw DiaryDataStoreError.notFoundItem
        }
        originalItem.updatedAt = Date()
        try self.originalItem?.save()
    }

    // 添加公开访问方法
    var item: Item? {
        return originalItem
    }
    
    var createdAt: Date? {
        return originalItem?.createdAt
    }
    
    var updatedAt: Date? {
        return originalItem?.updatedAt
    }
}

public enum DiaryDataStoreError: Error, LocalizedError {
    case notFoundItem // 操作対象のItemが存在しない
    case notValidData // 入力データが不適


    public var errorDescription: String? {
        switch self {
        case .notFoundItem:
            return "找不到这篇日记呢"
        case .notValidData:
            return "输入的内容格式好像有问题诶"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notFoundItem:
            return "发生了一些问题，再试一次吧"
        case .notValidData:
            return "请确认好内容格式后、再试一次吧"
        }
    }
}
