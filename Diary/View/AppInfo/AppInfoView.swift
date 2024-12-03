//
//  AppInfoView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/10.
//

import SwiftUI

struct AppInfoView: View {
    @EnvironmentObject private var bannerState: BannerState
    @EnvironmentObject private var notificationSetting: NotificationSetting

    @State private var consecutiveDays: Int? = 0
    @State private var diaryCount: Int? = 0
    @State private var isReminderOn = false
    @State private var isInquiryViewPresented = false

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .appLanguageLocale
        return formatter
    }()

    private let appVersion = AppVersion.current

    var body: some View {
        NavigationStack {

            attention
                .padding(.horizontal)
                .padding(.vertical)

            Form {
                Section("日记") {
                    streak
                    totalCount
                    bookMark
                    textOption
                    reminder
                }

                Section("支持") {
                    inquiry
                    version
                }
            }
            .navigationTitle("关于应用")
        }
        .onAppear {
            fetchConsecutiveDays()
            fetchDiaryCount()
        }
    }
}

private extension AppInfoView {

    var isiCloudEnabled: Bool {
        (FileManager.default.ubiquityIdentityToken != nil)
    }

    // MARK: View

    @ViewBuilder
    var attention: some View {
        if !isiCloudEnabled {
            warning(
                title: "iCloud已关闭",
                message: "iCloud已关闭，因此如果删除应用程序或更改设备，数据将丢失。建议将其打开，以便数据可以继续👋"
            )
        } else {
            connectedToiCloud
        }
    }

    var connectedToiCloud: some View {
        HStack(spacing: 20) {
            IconWithRoundedBackground(
                systemName: "checkmark",
                backgroundColor: .green
            )
            .foregroundColor(.adaptiveWhite)
            .padding(.leading)

            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("iCloud已连接")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .bold()
                    Text("iCloud中保存了数据。如果删除应用程序或更改设备，请使用相同的Apple ID。")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.trailing, 8)
            .padding(.vertical, 4)

        }
        .padding(.vertical, 4)
        .frame(height: 110)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveWhite)
                .adaptiveShadow()
        }
    }

    func warning(title: String, message: String) -> some View {
        HStack(spacing: 20) {
            IconWithRoundedBackground(
                systemName: "exclamationmark",
                backgroundColor: .yellow
            )
            .foregroundColor(.adaptiveWhite)
            .padding(.leading)

            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .bold()
                    Text(message)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
            .padding(.vertical, 4)

        }
        .padding(.vertical, 4)
        .frame(height: 110)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.adaptiveWhite)
                .adaptiveShadow()
        }
    }

    var streak: some View {
        HStack {
            rowTitle(symbolName: "flame", iconColor: .orange, title: "已经连续记录了")
            Spacer()
            if let consecutiveDays {
                Text("\(consecutiveDays)日")
            } else {
                Text("数据获取失败啦")
                    .font(.system(size: 12))
            }
        }
    }

    var totalCount: some View {
        HStack {
            rowTitle(symbolName: "square.stack", iconColor: .blue, title: "合計")
            Spacer()
            if let diaryCount {
                Text("\(diaryCount)件")
            } else {
                Text("数据获取失败啦")
                    .font(.system(size: 12))
            }
        }
    }

    var bookMark: some View {
        NavigationLink {
            BookmarkListView()
        } label: {
            rowTitle(symbolName: "bookmark", iconColor: .cyan, title: "收藏了的日记")
        }
    }

    var textOption: some View {
        NavigationLink {
            TextOptionsView()
        } label: {
            rowTitle(symbolName: "text.quote", iconColor: .gray, title: "文本设定")
        }
    }

    var reminder: some View {
        NavigationLink {
            ReminderSettingView()
        } label: {
            HStack {
                rowTitle(symbolName: "bell", iconColor: .red, title: "通知")
                Spacer()
                Group {
                    if notificationSetting.isSetNotification {
                        Text("开")
                        Text(notificationSetting.setNotificationDate!, formatter: timeFormatter)
                    } else {
                        Text("关")
                    }
                }
                .foregroundColor(.gray)
                .font(.system(size: 14))
            }
        }
    }

    var inquiry: some View {
        Button(actionWithHapticFB: {
            isInquiryViewPresented = true
        }) {
            rowTitle(symbolName: "mail", iconColor: .green, title: "和我联系")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isInquiryViewPresented) {
            SafariView(url: .init(string: "https://forms.gle/QdZ439j5ZuTBADzLA")!)
        }
    }

    var version: some View {
        Button(actionWithHapticFB: {
            UIPasteboard.general.string = appVersion.versionText
            bannerState.show(of: .success(message: "版本已复制"))
        }) {
            HStack {
                rowTitle(symbolName: "iphone.homebutton", iconColor: .orange, title: "版本")
                Spacer()
                Text(appVersion.versionText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func rowTitle(symbolName: String, iconColor: Color, title: String) -> some View {
        HStack {
            IconWithRoundedBackground(
                systemName: symbolName,
                backgroundColor: iconColor
            )
            .foregroundColor(.adaptiveWhite)
            Text(title)
                .font(.system(size: 14))
        }
    }

    // MARK: Action

    func fetchConsecutiveDays() {
        do {
            let consecutiveDays = try Item.calculateConsecutiveDays()
            self.consecutiveDays = consecutiveDays
        } catch {
            self.consecutiveDays = nil
        }
    }

    func fetchDiaryCount() {
        do {
            let count = try Item.count()
            self.diaryCount = count
        } catch {
            self.diaryCount = nil
        }
    }
}

#if DEBUG

struct AppInfoView_Previews: PreviewProvider {

    static var content: some View {
        AppInfoView()
            .environmentObject(NotificationSetting())
            .environmentObject(BannerState())
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
