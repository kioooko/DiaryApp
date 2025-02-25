//
//  DiaryApp.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/23.
//

import SwiftUI

@main
struct DiaryApp: App {
    @UIApplicationDelegateAdaptor(DiaryAppDelegate.self) var appDelegate
    
    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue) 
    private var hasBeenLaunchedBefore: Bool = false
    
    @StateObject private var bannerState = BannerState()
    @StateObject private var coreDataProvider = CoreDataProvider.shared
    @StateObject private var textOptions: TextOptions = .makeUserOptions()
    @StateObject private var notificationSetting: NotificationSetting = NotificationSetting()
    @StateObject private var weatherData = WeatherData()
    @StateObject private var apiKeyManager = APIKeyManager()

    @AppStorage(UserDefaultsKey.reSyncPerformed.rawValue)
    private var reSyncPerformed: Bool = false

    @StateObject private var persistenceController = CoreDataProvider.shared

    init() {
//        let now = Date()
//        for i in -3 ... 0 {
//            let targetDate = Calendar.current.date(byAdding: .month, value: i, to: now)!
//            let item = Item.makeRandom(date: targetDate)
//            let item2 = Item.makeRandom(date: targetDate)
//            try! item.save()
//        }

        reSyncData()
        coreDataProvider.validateAllEntities()
    }

    var body: some Scene {
        WindowGroup {
            if !hasBeenLaunchedBefore {
                WelcomeView(apiKeyManager: apiKeyManager)
                    .environmentObject(bannerState)
                    .environment(\.managedObjectContext, coreDataProvider.container.viewContext)
                    .environmentObject(textOptions)
                    .environmentObject(notificationSetting)
                    .environmentObject(weatherData)
            } else {
                HomeView(apiKeyManager: apiKeyManager)
                    .environmentObject(bannerState)
                    .environment(\.managedObjectContext, coreDataProvider.container.viewContext)
                    .environmentObject(textOptions)
                    .environmentObject(notificationSetting)
                    .environmentObject(weatherData)
            }
            .onAppear {
                checkAndFixDatabase()
            }
        }
    }

    private func checkAndFixDatabase() {
        let context = persistenceController.container.viewContext
        
        do {
            // 检查是否有无效数据
            let invalidData = try checkForInvalidData(in: context)
            
            if invalidData {
                print("发现无效数据，正在重置数据库...")
                persistenceController.resetAllData()
            } else {
                print("数据库检查通过")
            }
        } catch {
            print("❌ 检查数据库时出错: \(error)")
        }
    }
    
    private func checkForInvalidData(in context: NSManagedObjectContext) throws -> Bool {
        // 检查每个实体类型
        let entities = ["Item", "CheckListItem", "Contact", "SavingsGoal"]
        
        for entityName in entities {
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            let objects = try context.fetch(request)
            
            for object in objects {
                if object.value(forKey: "id") == nil {
                    return true
                }
            }
        }
        
        return false
    }
}

private extension DiaryApp {

    /**
     2023/07/20 現在ですでにアプリ起動済みのユーザーのデータを再度CloudKitに同期するためにupdatedAtを数秒更新する。

     [Why]
     CloudKitのDBがProductionにデプロイされておらず、AppStore経由でインストールしたアプリの場合CloudKitに同期されないから。

     ver 1.1.0未満のユーザーがいなくなればこのコードは消して良い
     */
    func reSyncData() {
        if hasBeenLaunchedBefore && !reSyncPerformed {
            let itemFetchRequest = Item.all
            let checkListItemFetchRequest = CheckListItem.all

            do {
                let items = try CoreDataProvider.shared.container.viewContext.fetch(itemFetchRequest)
                for item in items {
                    if let updatedAt = item.updatedAt {
                        item.updatedAt = updatedAt.addingTimeInterval(1)
                    } else {
                        item.updatedAt = Date()
                    }
                }

                let checkListItems = try CoreDataProvider.shared.container.viewContext.fetch(checkListItemFetchRequest)
                for checkListItem in checkListItems {
                    if let updatedAt = checkListItem.updatedAt {
                        checkListItem.updatedAt = updatedAt.addingTimeInterval(1)
                    } else {
                        checkListItem.updatedAt = Date()
                    }
                }

                try CoreDataProvider.shared.container.viewContext.save()
                reSyncPerformed = true
            } catch {
                print("⚠️: Failed to re-sync data.")
            }
        } else {
            reSyncPerformed = true
        }
    }
}
