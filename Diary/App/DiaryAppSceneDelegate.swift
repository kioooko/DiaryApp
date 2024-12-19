//
//  DiaryAppSceneDelegate.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/08.
//
import SplineRuntime
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
    var bannerWindow: UIWindow?
    weak var windowScene: UIWindowScene?

    var bannerState: BannerState? {
        didSet {
            setupBannerWindow()
        }
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        windowScene = scene as? UIWindowScene
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: WelcomeSplineAnimationView())
        window.makeKeyAndVisible()

        self.windowScene = windowScene
        self.bannerWindow = window

        // 设置5秒后切换到主界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.switchToWelcomeView()
        }
    }

    private func switchToWelcomeView() {
        guard let windowScene = windowScene else { return }

        // 确保传递的是实例
        let welcomeView = WelcomeView(apiKeyManager: APIKeyManager())
            .environmentObject(bannerState ?? BannerState())
            .environmentObject(NotificationSetting())
            .environmentObject(WeatherData())
           // .environmentObject(apiKeyManager)

        let welcomeWindow = UIWindow(windowScene: windowScene)
        welcomeWindow.rootViewController = UIHostingController(rootView: welcomeView)
        welcomeWindow.makeKeyAndVisible()

        self.bannerWindow = welcomeWindow
    }

    func setupBannerWindow() {
        guard let windowScene = windowScene, let bannerState else {
            return
        }

        let bannerViewController = UIHostingController(rootView: BannerView().environmentObject(bannerState))
        bannerViewController.view.backgroundColor = .clear

        let bannerWindow = PassThroughWindow(windowScene: windowScene)
        bannerWindow.rootViewController = bannerViewController
        bannerWindow.isHidden = false
        self.bannerWindow = bannerWindow
    }
}
