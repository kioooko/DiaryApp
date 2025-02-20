//
//  AppInfoView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/10.
//  Change by kioooko on 2024/12/1

import SwiftUI // 导入 SwiftUI 框架
import Neumorphic // 导入 Neumorphic 框架

struct AppInfoView: View { // 定义 AppInfoView 结构体，遵循 View 协议
    @EnvironmentObject private var bannerState: BannerState // 注入 BannerState 对象
    @EnvironmentObject private var notificationSetting: NotificationSetting // 注入 NotificationSetting 对象
    @EnvironmentObject private var apiKeyManager: APIKeyManager // 注入 APIKeyManager 对象
    @State private var consecutiveDays: Int? = 0 // 用于存储连续记录天数的状态
    @State private var diaryCount: Int? = 0 // 用于存储日记总数的状态
    @State private var isReminderOn = false // 用于存储提醒状态的布尔值
    @State private var isInquiryViewPresented = false // 控制是否显示询问视图的状态

    private let timeFormatter: DateFormatter = { // 定义时间格式化器
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .appLanguageLocale
        return formatter
    }()

    private let appVersion = AppVersion.current // 获取当前应用版本

    var body: some View { // 定义视图的主体
        NavigationStack { // 使用 NavigationStack 包裹内容
            VStack {
                attention // 显示 iCloud 状态信息
                    .padding(.horizontal) // 添加水平内边距
                    .padding(.vertical) // 添加垂直内边距
                    .background(Color.Neumorphic.main)

                Form { // 使用 Form 组织内容
                    Section("日记") { // 日记相关信息部分
                        streak // 显示连续记录天数
                        totalCount // 显示日记总数
                        bookMark // 显示书签
                        textOption // 显示文本选项
                        reminder // 显示提醒设置
                    }

                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.Neumorphic.main)
                    )
                    
     
                    Section("支持") { // 支持相关信息部分
                        Relationship // 显示关系
                        Expense // 显示记账指南
                        ChatAIGuide // 显示ChatAI功能
                        DataManage//导入，导出等数据管理
                        inquiry // 显示联系选项
                        version // 显示应用版本
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.Neumorphic.main)
                    )
                }
                .background(Color.Neumorphic.main) // 颜色设置
            .softOuterShadow(offset: 2, radius: 8)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("应用设置") // 设置导航标题
        }
        .onAppear { // 当视图出现时执行
            fetchConsecutiveDays() // 获取连续记录天数
            fetchDiaryCount() // 获取日记总数
        }
        .background(Color.Neumorphic.main) // 颜色设置
       
    }
}

private extension AppInfoView { // AppInfoView 的私有扩展

    var isiCloudEnabled: Bool { // 检查 iCloud 是否启用
        (FileManager.default.ubiquityIdentityToken != nil)
    }

    // MARK: View

    @ViewBuilder
    var attention: some View { // 显示 iCloud 状态信息
        if !isiCloudEnabled {
            HStack {
                iconImg(
                    icon: "exclamationmark",
                    color: .yellow)
                    .padding()
                iCloudLayout(
                    title: "iCloud已关闭",
                    message: "iCloud已关闭，因此如果删除应用程序或更改设备，数据将丢失。建议将其打开，以便数据可以继续👋"
                )
                Image(systemName: "chevron.right")
                    .font(.system(size: 20)) // 设置图标大小
                    .foregroundColor(.gray) // 设置图标颜色为灰色
                    .padding(.trailing, 10) // 为图标添加右侧内边距
            }
            .modifier(NeumorphicCardModifier())
        } else {
            connectedToiCloud // 显示 iCloud 已连接信息
        }
    }

    var connectedToiCloud: some View { // 显示 iCloud 已连接信息
        HStack{
        iconImg(icon: "checkmark", color: .green)
        .padding()
        iCloudLayout(
        title: "iCloud已连接",
        message: "iCloud已连接。iCloud中保存了数据。如果删除应用程序或更改设备,请使用相同的Apple ID。" 
        )
    }
      .modifier(NeumorphicCardModifier())
    }

    var streak: some View { // 显示连续记录天数
        HStack {
            rowTitle(icon: "flame", Color: .orange, description: "已经连续记录了")
            Spacer()
            if let consecutiveDays {
                Text("\(consecutiveDays)日")
            } else {
                Text("数据获取失败啦")
                    .font(.system(size: 12))
            }
        }
  }

    var totalCount: some View { // 显示日记总数
        HStack(spacing: 4) {
            rowTitle(icon: "square.stack", Color: .blue, description: "合計")
            Spacer()
            if let diaryCount {
                Text("\(diaryCount)件")
            } else {
                Text("数据获取失败啦")
                    .font(.system(size: 14))
            }
        }
    }

    var bookMark: some View { // 显示书签
        NavigationLink {
            BookmarkListView()
        } label: {
            rowTitle(icon: "bookmark", Color: .cyan, description: "收藏了的日记")
            
        }
    }

    var textOption: some View { // 显示文本选项
        NavigationLink {
            TextOptionsView()
        } label: {
            rowTitle(icon: "text.quote", Color: .gray, description: "文本设定")
        }
    }

    var reminder: some View { // 显示提醒设置
        NavigationLink {
            ReminderSettingView()
        } label: {
            HStack {
                rowTitle(icon: "bell", Color: .red, description: "通知")
                Spacer()
                Group {
                    if notificationSetting.isSetNotification {
                        Text("开")
                        Text(notificationSetting.setNotificationDate!, formatter: timeFormatter)
                    } else {
                        Text("关")
                    }
                }
                .font(.system(size: 14))
            }
        }
    }



var Relationship: some View {
    NavigationLink{
        RelationshipView()
    } label: {
        rowTitle(icon: "person.2", Color: .blue, description: "关系")
    }
}
var Expense: some View {
    NavigationLink{
        ExpenseStatsView()
    } label: {
        rowTitle(icon: "dollarsign.circle", Color: .green, description: "记账本")
    }
}

    var ChatAIGuide: some View { // 显示ChatAI功能
        NavigationLink {
          ChatAISetting(apiKeyManager: APIKeyManager())
        } label: {
            rowTitle(icon: "message", Color: .purple, description: "ChatAI设置")
        }
    }

var DataManage: some View {
  NavigationLink{
     DataDownloadView()
    } label: {
       rowTitle(icon: "square.and.arrow.down", Color: .yellow, description: "日记数据管理")
    }
}

    var inquiry: some View { // 显示联系选项
        Button(actionWithHapticFB: {
            isInquiryViewPresented = true
        }) {
            rowTitle(icon: "mail", Color: .green, description: "和我联系")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isInquiryViewPresented) {
            SafariView(url: .init(string: "https://forms.gle/QdZ439j5ZuTBADzLA")!)
        }
    }

    var version: some View { // 显示应用版本
        Button(actionWithHapticFB: {
            UIPasteboard.general.string = appVersion.versionText
            bannerState.show(of: .success(message: "版本已复制"))
        }) {
            HStack {
                rowTitle(icon: "iphone.homebutton", Color: .orange, description: "版本")
                Spacer()
                Text(appVersion.versionText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func rowTitle(icon: String, Color: Color, description: String) -> some View { // 显示行标题
        HStack (spacing: 4){
            // 图标，带有背景和阴影
            Image(systemName: icon)
                .resizable() // 使图像可调整大小
                .aspectRatio(contentMode: .fit) // 保持图像的宽高比
                .frame(width: 14, height: 14) // 设置图像的宽度和高度
                .foregroundColor(Color) // 设置图标颜色
                .padding() // 添加内边距
                .clipShape(Circle()) // 将背景裁剪为圆形
                .softInnerShadow(Circle(), spread: 0.6)
            // 描述文本
            Text(description)
                .foregroundColor(.primary.opacity(0.8)) // 设置文本颜色和不透明度
                .font(.system(size: 16)) // 设置字体大小
                .frame(maxWidth: .infinity, alignment: .leading) // 设置最大宽度和对齐方式
        }
    }

    // MARK: Action
    func fetchConsecutiveDays() { // 获取连续记录天数
        do {
            let consecutiveDays = try Item.calculateConsecutiveDays()
            self.consecutiveDays = consecutiveDays
        } catch {
            self.consecutiveDays = nil
        }
    }

    func fetchDiaryCount() { // 获取日记总数
        do {
            let count = try Item.count()
            self.diaryCount = count
        } catch {
            self.diaryCount = nil
        }
    }


    func iconImg(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .foregroundColor(color)
            .padding()
            .background(Color.Neumorphic.main) // 颜色设置
            .clipShape(Circle())
            .softOuterShadow() // 颜色设置
    }

    func iCloudLayout(title: String, message: String) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) { // 使用 VStack 垂直排列标题和消息
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading) // 设置最大宽度并左对齐
                    .bold() // 设置字体为粗体
                Text(message)
                    .frame(maxWidth: .infinity, alignment: .leading) // 设置最大宽度并左对齐
                    .font(.system(size: 14)) // 设置字体大小为 14
                    .foregroundColor(.gray) // 设置字体颜色为灰色
            }
        }
        .padding(.horizontal) // 为整个 HStack 添加水平外边距
    }
}

struct NeumorphicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, 8)
            .frame(height: 100)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.Neumorphic.main)
                    .softOuterShadow()
            }
    }
}

#if DEBUG

struct AppInfoView_Previews: PreviewProvider { // 预览提供者

    static var content: some View {
        AppInfoView()
            .environmentObject(NotificationSetting()) // 注入 NotificationSetting
            .environmentObject(BannerState()) // 注入 BannerState
    }

    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light) // 测试浅色模式
            content
                .environment(\.colorScheme, .dark) // 测试深色模式
        }
    }
}

#endif
