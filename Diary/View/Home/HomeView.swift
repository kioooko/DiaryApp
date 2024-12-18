//
//  HomeView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/01.
// Change by kioooko 2024/12/13

import CoreData // 导入 Core Data 框架，用于数据持久化
import SwiftUI // 导入 SwiftUI 框架，用于构建用户界面
import Neumorphic // 导入 Neumorphic 库

struct HomeView: View { // 定义 HomeView 结构体，遵循 View 协议
    @Environment(\.colorScheme) var colorScheme // 获取当前的颜色模式（浅色或深色）
    @Environment(\.managedObjectContext) var viewContext // 获取 Core Data 的上下文
    @EnvironmentObject private var sceneDelegate: DiaryAppSceneDelegate // 注入 DiaryAppSceneDelegate 对象
    @EnvironmentObject private var bannerState: BannerState // 注入 BannerState 对象
    @EnvironmentObject private var textOptions: TextOptions // 注入 TextOptions 对象

    @AppStorage(UserDefaultsKey.hasBeenLaunchedBefore.rawValue)
    private var hasBeenLaunchedBefore: Bool = false // 使用 AppStorage 存储应用是否启动过

    @State private var isCreateDiaryViewPresented = false // 控制是否显示创建日记视图的状态
    @State private var isCalendarPresented = false // 控制是否显示日历的状态
    @State private var selectedDate: Date? = Date() // 选中的日期
    @State private var scrollToItem: Item? = nil // 滚动到的日记条目
    @State private var diaryListInterval: DateInterval = Date.currentMonthInterval! // 当前显示的日记时间间隔
    @State private var dateItemCount: [Date: Int] = [:] // 每个日期的日记条目计数

    private let calendar = Calendar.current // 当前日历
    private var dateFormatter: DateFormatter = { // 日期格式化器
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // 设置日期格式
        formatter.locale = .appLanguageLocale // 设置语言区域
        return formatter
    }()

    var body: some View { // 定义视图的主体
        NavigationStack { // 使用 NavigationStack 包裹内容
            ZStack(alignment: .bottomTrailing) { // 使用 ZStack 布局，右下角对齐
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all) // 设置背景颜色为 Neumorphic 风格
                // メインコンテンツ
                ZStack(alignment: .topTrailing) { // 使用 ZStack 布局，右上角对齐
                    appInfo // 显示应用信息按钮
                        .padding(.top, 8) // 顶部内边距
                        .padding(.trailing, 16) // 右侧内边距
                        .zIndex(200) // 设置 Z 索引
                    ChatAIGuide
                        .padding(.top, 8) // 顶部内边距
                        .padding(.trailing, 66) // 右侧内边距
                        .zIndex(200) // 设置 Z 索引
                    GeometryReader { proxy in // 使用 GeometryReader 获取安全区域信息
                        let safeArea = proxy.safeAreaInsets
                        CalendarContainer( // 显示日历容器
                            selectedMonth: $diaryListInterval.start, // 绑定选中的月份
                            safeAreaInsets: safeArea, // 传递安全区域内边距
                            dateItemCount: dateItemCount // 传递日期条目计数
                        ) {
                            DiaryList( // 显示日记列表
                                dateInterval: diaryListInterval, // 传递日期间隔
                                scrollToItem: $scrollToItem // 绑定滚动到的条目
                            )
                            .padding(.vertical, 16) // 垂直内边距
                            .padding(.horizontal, 10) // 水平内边距
                        }
                        .ignoresSafeArea(.container, edges: .top) // 忽略顶部安全区域
                        .onSwipe(minimumDistance: 28) { direction in // 处理滑动手势
                            switch direction {
                            case .left:
                                moveMonth(.forward) // 向前移动一个月
                                break
                            case .right:
                                moveMonth(.backward) // 向后移动一个月
                                break
                            case .up, .down:
                                break
                            }
                        }
                    }
                }
                FloatingButton {
                    isCreateDiaryViewPresented = true
                }
                .padding(.trailing, 16) // 确保使用有效的方向
                .padding(.bottom, 20) // 确保使用有效的方向
            }
        }
        .navigationBarBackButtonHidden(true) // 隐藏返回按钮
        .tint(.adaptiveBlack) // 设置全局的 tint 颜色
        .sheet(isPresented: $isCreateDiaryViewPresented) { // 显示创建日记视图
            CreateDiaryView()
                .interactiveDismissDisabled() // 禁用交互式关闭
        }
        .sheet(isPresented: $hasBeenLaunchedBefore.not) { // 显示欢迎视图
            WelcomeView()
                .interactiveDismissDisabled() // 禁用交互式关闭
        }
        .onAppear {
          //  sceneDelegate.bannerState = bannerState // 设置 bannerState
        }
        .onChange(of: diaryListInterval) { _, newValue in // 监听 diaryListInterval 的变化
            loadItems(of: newValue) // 加载新日期间隔的条目
        }
    }
}

private extension HomeView { // HomeView 的私有扩展
    func loadItems(of dateInterval: DateInterval) { // 加载指定日期间隔的条目
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest() // 创建获取请求
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ && date <= %@",
            dateInterval.start as CVarArg,
            dateInterval.end as CVarArg
        )
        do {
            let fetchedItems = try viewContext.fetch(fetchRequest) // 执行获取请求
            var countDict: [Date: Int] = [:] // 创建日期计数字典
            let calendar = Calendar.current

            for item in fetchedItems { // 遍历获取的条目
                guard let date = item.date else { continue }
                let components = calendar.dateComponents([.year, .month, .day], from: date)
                guard let startOfDay = calendar.date(from: components) else { continue }

                if let count = countDict[startOfDay] {
                    countDict[startOfDay] = count + 1 // 增加计数
                } else {
                    countDict[startOfDay] = 1 // 初始化计数
                }
            }
            self.dateItemCount = countDict // 更新日期计数
        } catch {
            print("⚠️ Failed to fetch items: \(error)") // 打印错误信息
        }
    }

    func moveMonth(_ direction: Direction) { // 移动月份
        var diff: Int
        switch direction {
        case .forward:
            diff = 1 // 向前一个月
        case .backward:
            diff = -1 // 向后一个月
        }

        guard let date = calendar.date(byAdding: .month, value: diff, to: diaryListInterval.start),
              let start = date.startOfMonth,
              let end = date.endOfMonth else { return }

        diaryListInterval = .init(start: start, end: end) // 更新日期间隔
    }

    var appInfo: some View { // 应用信息视图
        NavigationLink {
            AppInfoView() // 导航到应用信息视图
        } label: {
            Image(systemName: "gearshape") // 齿轮图标
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.black)
                .frame(width: 24)
                .bold()
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(Color.Neumorphic.main)
                        .softOuterShadow()
                )
                .offset(y: -10) // 向上移动图标
        }
    }
     var ChatAIGuide: some View {
        NavigationLink {
            ChatAIView() // 导航到ChatAI视图
        } label: {
            Image(systemName: "message")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.black)
                .frame(width: 24)
                .bold()
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(Color.Neumorphic.main)
                        .softOuterShadow()
                )
                .offset(y: -10) // 向上移动图标
        }
    }

    var navigationToolBar: some View { // 导航工具栏
        NavigationLink {
            AppInfoView() // 导航到应用信息视图
        } label: {
            Image(systemName: "gearshape") // 齿轮图标
                .font(.system(size: 18))
                .bold()
        }
    }
}


#if DEBUG

struct Home_Previews: PreviewProvider {

    static var content: some View {
        HomeView()
            .environmentObject(DiaryAppSceneDelegate()) // 注入 DiaryAppSceneDelegate
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
