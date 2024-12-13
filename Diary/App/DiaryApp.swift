//
//  DiaryApp.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/23.
//  Change by kioooko 2024/12/13
//

import SwiftUI // 导入 SwiftUI 框架

@main
struct DiaryApp: App { // 定义应用程序的主结构体，标记为应用程序入口
    @UIApplicationDelegateAdaptor var delegate: DiaryAppDelegate // 使用 UIApplicationDelegateAdaptor 适配 AppDelegate

    @StateObject private var bannerState = BannerState() // 创建 BannerState 的状态对象
    @StateObject private var coreDataProvider = CoreDataProvider.shared // 创建 CoreDataProvider 的共享实例
    @StateObject private var textOptions: TextOptions = .makeUserOptions() // 创建 TextOptions 的状态对象
    @StateObject private var weatherData = WeatherData() // 创建 WeatherData 的状态对象
    @StateObject private var notificationSetting = NotificationSetting() // 创建 NotificationSetting 的状态对象
    @State private var animationCompleted = false // 创建动画完成状态变量

    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue)
    private var hasBeenLaunchedBefore: Bool = false // 使用 AppStorage 存储应用是否启动过

    @AppStorage(UserDefaultsKey.reSyncPerformed.rawValue)
    private var reSyncPerformed: Bool = false // 使用 AppStorage 存储是否已执行重新同步

    init() { // 初始化方法
        print("DiaryApp initialized") // 确认应用程序初始化
        let now = Date() // 获取当前日期
        for i in -3 ... 0 { // 循环创建过去三个月的随机数据
            let targetDate = Calendar.current.date(byAdding: .month, value: i, to: now)!
            let item = Item.makeRandom(date: targetDate)
            let item2 = Item.makeRandom(date: targetDate)
            try! item.save() // 保存生成的随机数据
        }
        reSyncData() // 调用重新同步数据的方法
    }

    var body: some Scene { // 定义应用程序的场景
        WindowGroup { // 创建一个窗口组
            if animationCompleted {
                WelcomeView()
                    .environmentObject(bannerState)
                    .environment(\.managedObjectContext, coreDataProvider.container.viewContext)
                    .environmentObject(textOptions)
                    .environmentObject(notificationSetting)
                    .environmentObject(weatherData)
            } else {
                WelcomeSplineAnimationView()
                    .onAppear {
                        // 模拟动画完成后的延迟
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            animationCompleted = true
                        }
                    }
            }
        }
    }
}

// 下面是一些注释掉的代码，可能用于切换到 HomeView
// var body: some Scene {
//        WindowGroup {
//            if showHomeView {
//                HomeView()
//                    .environmentObject(bannerState)
//                    .environment(\.managedObjectContext, coreDataProvider.container.viewContext)
//                    .environmentObject(textOptions)
//                    .environmentObject(notificationSetting)
//                    .environmentObject(weatherData)
//            } else {
//                WelcomeSplineAnimationView()
//                .onAppear {
//                    // 模拟欢迎视图完成后的延迟
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        showHomeView = true
//                    }
//                }
//                WelcomeView()
//            }
//        }
//    }

private extension DiaryApp { // 定义 DiaryApp 的私有扩展

    /**
     2023/07/20 現在ですでにアプリ起動済みのユーザーのデータを再度CloudKitに同期するためにupdatedAtを数秒更新する。

     [Why]
     CloudKitのDBがProductionにデプロイされておらず、AppStore経由でインストールしたアプリの場合CloudKitに同期されないから。

     ver 1.1.0未満���ユーザーがいなくなればこのコードは消して良い
     */
    func reSyncData() { // 重新同步数据的方法
        if hasBeenLaunchedBefore && !reSyncPerformed { // 检查是否已启动过且未执行重新同步
            let itemFetchRequest = Item.all // 获取所有 Item 的请求
            let checkListItemFetchRequest = CheckListItem.all // 获取所有 CheckListItem 的请求

            do {
                let items = try CoreDataProvider.shared.container.viewContext.fetch(itemFetchRequest) // 获取所有 Item
                for item in items {
                    if let updatedAt = item.updatedAt {
                        item.updatedAt = updatedAt.addingTimeInterval(1) // 更新 updatedAt 时间
                    } else {
                        item.updatedAt = Date() // 设置为当前日期
                    }
                }

                let checkListItems = try CoreDataProvider.shared.container.viewContext.fetch(checkListItemFetchRequest) // 获取所有 CheckListItem
                for checkListItem in checkListItems {
                    if let updatedAt = checkListItem.updatedAt {
                        checkListItem.updatedAt = updatedAt.addingTimeInterval(1) // 更新 updatedAt 时间
                    } else {
                        checkListItem.updatedAt = Date() // 设置为当前日期
                    }
                }

                try CoreDataProvider.shared.container.viewContext.save() // 保存更改
                reSyncPerformed = true // 标记为已执行重新同步
            } catch {
                print("⚠️ : Failed to re-sync data.") // 打印错误信息
            }
        } else {
            reSyncPerformed = true // 如果不需要重新同步，直接标记为已执行
        }
    }
}