//Change by kioooko on 2024/12/19


import SwiftUI
import Neumorphic


struct ReminderSettingView: View {
    @EnvironmentObject private var bannerState: BannerState
    @EnvironmentObject private var notificationSetting: NotificationSetting

    @State private var selectedDate: Date = Date()
    @State private var showRequestNotificationPermissionAlert = false

    var body: some View {
        setReminder
            .onAppear {
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

     // MARK: Reminder Page
    var setReminder: some View {
        VStack(spacing: 40) {
            Spacer()  // 添加顶部空间
            VStack(spacing: 40) {
                title("设置提醒事项", description: "让写日记成为一种习惯。我们不会发送任何烦人的垃圾通知。")
                    .multilineTextAlignment(.center)  // 文本居中
                
                HStack {
                    featureRow(icon: "alarm", color: .red, description: "设置你每日的编织时间吧")
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            hourAndMinutePicker 
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()  // 添加底部空间
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // 使用最大宽度和高度
        .padding(.horizontal)
    }
    
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

    // MARK: Helper Views

    func title(_ title: String, description: String) -> some View {
        VStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Neumorphic.main)
                .softInnerShadow(RoundedRectangle(cornerRadius: 12))
        )
    }

    func featureRow(icon: String, color: Color, description: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(description)
                .font(.body)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Neumorphic.main)
                .softInnerShadow(RoundedRectangle(cornerRadius: 12))
        )
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