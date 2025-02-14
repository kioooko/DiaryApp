//
//  ReminderSettingView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/12.
//  Created by kioooko on 2024/12/19.
//

import SwiftUI
import Neumorphic

struct ReminderSettingView: View {
    @EnvironmentObject private var bannerState: BannerState
    @EnvironmentObject private var notificationSetting: NotificationSetting

    @State private var selectedDate: Date = Date()
    @State private var showRequestNotificationPermissionAlert = false
    @State private var isNotificationEnabled: Bool = false

    let cornerRadius : CGFloat = 15

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("让文字记录成为你的习惯吧👋")
                    .font(.system(size: 16))
                Toggle("开启每日提醒", isOn: $isNotificationEnabled)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.Neumorphic.main)
                            .softOuterShadow()
                    )
                    .onChange(of: isNotificationEnabled) { newValue in
                        if !newValue {
                            Task {
                                await notificationSetting.delete()
                            }
                            bannerState.show(of: .success(message: "通知已被设为未启用状态🗑️"))
                        }
                    }
                if isNotificationEnabled {
                    hourAndMinutePicker
                        .padding(.top, 20)
                    saveButton
                }
            }
            .padding(20)
        }
        .background(Color.Neumorphic.main.ignoresSafeArea())
        .onAppear {
            isNotificationEnabled = notificationSetting.isSetNotification
            if let date = notificationSetting.setNotificationDate {
                selectedDate = date
            }
        }
        .alert(isPresented: $showRequestNotificationPermissionAlert) {
            requestPermissionAlert
        }
        .navigationTitle("通知")
    }
}

private extension ReminderSettingView {

    // MARK: View

    var hourAndMinutePicker: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: .hourAndMinute)
            .datePickerStyle(WheelDatePickerStyle())
    }

    var requestPermissionAlert: Alert {
        Alert(
            title: Text("请打开手机的设置通知"),
            message: Text("请开启通知功能，这样就可以完成设置了哦！"),
            dismissButton: .default(
                Text("OK"),
                action: {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            )
        )
    }

    var saveButton: some View {

        Button(actionWithHapticFB: {
            save()
        }, label: {
            Text("保存").fontWeight(.bold)
        })
        .softButtonStyle(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: Action

    func save() {
        Task {
            do {
                try await notificationSetting.setNotification(date: selectedDate)
                bannerState.show(of: .success(message: "通知已打开🎉"))
            } catch NotificationSettingError.requiredPermissionInSettingsApp {
                showRequestNotificationPermissionAlert = true
            } catch {
                bannerState.show(with: error)
            }
        }
    }
}

#if DEBUG

struct ReminderSettingView_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            ReminderSettingView()
                .environmentObject(NotificationSetting())
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


