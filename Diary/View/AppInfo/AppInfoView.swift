//
//  AppInfoView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/10.
//

import SwiftUI

struct AppInfoView: View {
    @EnvironmentObject private var notificationSetting: NotificationSetting

    @State private var consecutiveDays: Int? = 0
    @State private var diaryCount: Int? = 0
    @State private var isReminderOn = false

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("日記") {
                    streak
                    totalCount
                    bookMark
                    textOption
                    reminder
                }

                Section("サポート") {

                }
            }
            .navigationTitle("アプリについて")
        }
        .onAppear {
            fetchConsecutiveDays()
            fetchDiaryCount()
        }
    }
}

private extension AppInfoView {

    // MARK: View

    var streak: some View {
        HStack {
            rowTitle(emoji: "🔥", title: "現在の継続日数")
            Spacer()
            if let consecutiveDays {
                Text("\(consecutiveDays)日")
            } else {
                Text("データの取得に失敗しました")
                    .font(.system(size: 12))
            }
        }
    }

    var totalCount: some View {
        HStack {
            rowTitle(emoji: "📚", title: "合計")
            Spacer()
            if let diaryCount {
                Text("\(diaryCount)件")
            } else {
                Text("データの取得に失敗しました")
                    .font(.system(size: 12))
            }
        }
    }

    var bookMark: some View {
        NavigationLink {
            BookmarkListView()
        } label: {
            rowTitle(emoji: "🔖", title: "ブックマークした日記")
        }
    }

    var textOption: some View {
        NavigationLink {
            TextOptionsView()
        } label: {
            rowTitle(emoji: "📝", title: "テキストの設定")
        }
    }

    var reminder: some View {
        NavigationLink {
            ReminderSettingView()
        } label: {
            HStack {
                rowTitle(emoji: "⏰", title: "通知")
                Spacer()
                Group {
                    if notificationSetting.isSetNotification {
                        Text("オン")
                        Text(notificationSetting.setNotificationDate!, formatter: timeFormatter)
                    } else {
                        Text("オフ")
                    }
                }
                .foregroundColor(.gray)
                .font(.system(size: 14))
            }
        }
    }

    func rowTitle(emoji: String, title: String) -> some View {
        HStack {
            Text(emoji)
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
