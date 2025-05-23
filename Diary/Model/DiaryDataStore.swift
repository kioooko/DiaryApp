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

    var isBookmarked = false
    var selectedWeather: WeatherSymbol = .sun
    var selectedPickerItem: PhotosPickerItem?

    var originalItem: Item?
    private var originalItemImage: UIImage?

    /*
     新規作成の場合はまだItemを生成していないのでnil。
     編集などの場合は対象のItemを渡すことで更新可能。
     */
    init(item: Item? = nil) {
        originalItem = item
        updateValuesWithOriginalData()
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
        guard let originalItem else {
            throw DiaryDataStoreError.notFoundItem
        }

        var updated: Bool = false

        // 値の変更があるかどうかを元の値との比較より行い、変更されている場合のみプロパティの更新を行う

        if originalItem.date != selectedDate {
            originalItem.date = selectedDate
            updated = true
        }

        if originalItem.title != title,
           !title.isEmpty {
            originalItem.title = title
            updated = true
        }

        if originalItem.body != bodyText {
            originalItem.body = bodyText
            updated = true
        }

        if originalItem.weather != selectedWeather.symbol {
            originalItem.weather = selectedWeather.symbol
            updated = true
        }

        if originalItemImage != selectedImage {
            originalItem.imageData = selectedImage?.jpegData(compressionQuality: 0.5)
            updated = true
        }

        if originalItem.checkListItemsArray != checkListItems {
            originalItem.checkListItems = NSSet(array: checkListItems)
            updated = true
        }

        if updated {
            try saveItem()
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
