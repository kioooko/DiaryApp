import UIKit
import SwiftUI

/**
 Use to manage windows

 ---
 UIWindows are associated with and managed by UIScenes, which representing a UI instance of our app.
 We use a UISceneDelegate/UIWindowSceneDelegate to respond to various events related to our UIScene (and associated UISceneSession).
 reference:  https://github.com/FiveStarsBlog/CodeSamples/tree/main/Windows

 UIScene は UIWindowを管理している。
 UIWindowSceneDelegate（UISceneDelegateに準拠している）を利用することでUISceneでのイベントをトリガーにしてWindowを扱うことができる。
 sceneを取得しそこにBannerなどの最前面に出したいWindowを用意している。
 */
final class DiaryAppSceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
    // 用于显示横幅的窗口
    var bannerWindow: UIWindow?
    // 弱引用的窗口场景，避免循环引用
    weak var windowScene: UIWindowScene?

    // 横幅状态，当状态改变时设置横幅窗口
    var bannerState: BannerState? {
        didSet {
            setupBannerWindow()
        }
    }

    // 当场景将要连接到会话时调用
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // 将场景转换为 UIWindowScene
        windowScene = scene as? UIWindowScene
    }

    // 设置横幅窗口
    func setupBannerWindow() {
        // 确保 windowScene 和 bannerState 都存在
        guard let windowScene = windowScene, let bannerState else {
            return
        }

        // 创建一个 UIHostingController 以显示 BannerView，并将其背景设置为透明
        let bannerViewController = UIHostingController(rootView: BannerView().environmentObject(bannerState))
        bannerViewController.view.backgroundColor = .clear

        // 创建一个新的 PassThroughWindow 并设置其根视图控制器为 bannerViewController
        let bannerWindow = PassThroughWindow(windowScene: windowScene)
        bannerWindow.rootViewController = bannerViewController
        bannerWindow.isHidden = false
        self.bannerWindow = bannerWindow
    }
}