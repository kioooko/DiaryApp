//
//  WelcomeView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/07/05.
//

import SwiftUI

/*
 1. アプリ全体の機能紹介
 2. 位置情報取得依頼
 3. リマインダー設定
 */
struct WelcomeView: View {
    @EnvironmentObject private var notificationSetting: NotificationSetting
    @EnvironmentObject private var weatherData: WeatherData

    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue)
    private var hasBeenLaunchedBefore: Bool = false
    @State private var selectedPage = 1
    @State private var selectedDate: Date = Date()

    private let maxPageCount = 3

    var body: some View {
        VStack {
            TabView(selection: $selectedPage) {
                Group {
                    appIntroduction
                        .tag(1)
                    requestLocation
                        .tag(2)
                    setReminder
                        .tag(3)
                }
                .contentShape(Rectangle()).gesture(DragGesture()) // スワイプでのページ遷移をしない
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            nextButton
                .padding(.bottom)
        }
    }
}

private extension WelcomeView {

    var nextButton: some View {

        // TODO: refactoring
        Button(actionWithHapticFB: {
            if selectedPage == 2 {
                weatherData.requestLocationAuth()
            }

            if selectedPage == 3 {
                Task {
                    do {
                        try await notificationSetting.setNotification(date: selectedDate)
                    }
                }
            }

            if selectedPage >= maxPageCount {
                hasBeenLaunchedBefore = true
                return
            } else {
                withAnimation {
                    selectedPage += 1
                }
            }
        }) {
            Text("OK")
        }
        .buttonStyle(ActionButtonStyle(size: .medium))
    }

    var appIntroduction: some View {
        VStack(spacing: 40) {
            title("你好哇👋！", description: "编织日记是一款用文字记录生活的简单应用")

            featureRow(
                icon: "book",
                color: .orange,
                description: "「编织日记」是一款直观且简洁的日记应用，帮助你用文字和图片编织自己的生活。"
            )
            featureRow(
                icon: "checkmark",
                color: .green,
                description: "帮助追踪日常习惯的检查清单。通过可视化目标，查看每天的微小进步。"
            )
            featureRow(
                icon: "icloud",
                color: .blue,
                description: "与 iCloud 完全同步。您可以轻松访问所有设备上的内容。重要的记录将始终安全存储。")

        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

    func featureRow(icon: String, color: Color, description: String) -> some View {
        HStack(spacing: 24) {
            IconWithRoundedBackground(systemName: icon, backgroundColor: color)

            Text(description)
                .foregroundColor(.adaptiveBlack.opacity(0.8))
                .font(.system(size: 18))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func title(_ text: String, description: String) -> some View {
        VStack(spacing: 16) {
            Text(text)
                .bold()
                .font(.system(size: 24))
            Text(description)
                .font(.system(size: 18))
        }
    }

    var requestLocation: some View {
        VStack(spacing: 40) {
            title(
                "请允许访问您的位置信息",
                description: "允许位置访问，开始更加丰富的日记体验吧！"
            )

            HStack(spacing: 24) {
                IconWithRoundedBackground(systemName: "mappin", backgroundColor: .green)

                Text("在「编织日记」中，我们会自动添加天气信息。\n位置信息仅用于获取天气信息。您随时可以更改设置。")
                    .foregroundColor(.adaptiveBlack.opacity(0.8))
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

    var setReminder: some View {
        VStack(spacing: 40) {
            title(
                "设置提醒事项",
                description: "让写日记成为一种习惯。我们不会发送任何烦人的通知。"
            )

            HStack {
                IconWithRoundedBackground(systemName: "alarm", backgroundColor: .red)
                Text("我们不会发送任何垃圾信息")
            }

            hourAndMinutePicker
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal)
    }

    var hourAndMinutePicker: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
            .datePickerStyle(WheelDatePickerStyle())
    }
}

#if DEBUG

struct WelcomeView_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            WelcomeView()
        }
    }

    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light)
            content
                .environment(\.colorScheme, .dark)
        }
    }
}

#endif
