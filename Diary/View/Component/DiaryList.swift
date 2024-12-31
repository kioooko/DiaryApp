//
//  DiaryList.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/09.
//

import SwiftUI // 导入 SwiftUI 框架，用于构建用户界面

struct DiaryList: View { // 定义一个名为 DiaryList 的视图结构体，遵循 View 协议
    /*
     > The fetch request and its results use the managed object context stored in the environment, which you can access using the managedObjectContext environment value.
     https://developer.apple.com/documentation/swiftui/fetchrequest

     FetchRequestにより、コンテキストの変化に応じて自動取得を行う
     */
    @FetchRequest private var items: FetchedResults<Item> // 使用 FetchRequest 自动获取数据，items 是获取的结果
    @Binding var scrollToItem: Item? // 绑定变量，用于滚动到特定的日记项
    @State var selectedItem: Item? = nil // 状态变量，存储当前选中的日记项

    init(
        dateInterval: DateInterval, // 初始化方法，接受一个日期区间
        scrollToItem: Binding<Item?> // 绑定的 scrollToItem 参数
    ) {
        /*
         HomeViewでitemsを管理した場合、EnvironmentObjectの更新毎にFetchRequestが発火し、再描画が起こった際に特定のDateでFetchRequestを作成することが難しい。
         別Viewを作成しinitでFetchRequestを作成することで再描画時の表示情報が特定のDateIntervalに紐づくものであることを保証している。
         */
        _items = FetchRequest(fetchRequest: Item.items(of: dateInterval)) // 使用日期区间创建 FetchRequest

        self._scrollToItem = scrollToItem // 初始化 scrollToItem 绑定
    }

    var body: some View { // 定义视图的主体
        if items.isEmpty { // 如果 items 为空
            empty // 显示空视图
                .padding(.top, 60) // 设置顶部填充
        } else {
            LazyVStack(spacing: 24) { // 使用 LazyVStack 显示日记项，设置项之间的间距
                ForEach(items) { item in // 遍历每个日记项
                    DiaryItem(item: item) // 显示单个日记项
                        .id(item.objectID) // 设置唯一标识符
                        .padding(.horizontal, 20) // 设置水平填充
                        .onTapGesture { // 添加点击手势
                            // NavigationLinkだと、DiaryItem上でのアクションではNavigationLinkが優先されます。
                            // 本Viewの使用箇所であるHomeではDiaryItem上で左右スワイプを効かせたかったので、tap gestureにしています。
                            selectedItem = item // 设置选中的日记项
                        }
                }
            }
            .padding(.top, 4) // 设置顶部填充
            .padding(.bottom, 200) // 设置底部填充
            .background(Color.Neumorphic.main)
            .navigationDestination(isPresented: .init(
                get: {
                    selectedItem != nil // 检查是否有选中的日记项
                }, set: { _ in
                    selectedItem = nil // 重置选中的日记项
                }
            )) {
                DiaryDetailView(diaryDataStore: .init(item: selectedItem)) // 显示日记详情视图
            }
        }
    }
}

private extension DiaryList { // 扩展 DiaryList，添加私有方法和属性
    var empty: some View { // 定义空视图
        VStack {
            Text("只需点击「+」按钮，就可以开始你的日记啦！") // 显示提示文本
                .foregroundColor(.gray) // 设置文本颜色
                .font(.system(size: 20)) // 设置字体大小
                .frame(height: 100) // 设置视图高度
                .multilineTextAlignment(.center) // 设置文本居中对齐
        }
    }

    func fetchFirstItem(on date: Date) -> Item? { // 定义一个方法，获取特定日期的第一个日记项
        // 日付の範囲を設定
        let calendar = Calendar.current // 获取当前日历
        let startOfDay = calendar.startOfDay(for: date) // 获取当天的开始时间
        let components = DateComponents(day: 1, second: -1) // 定义日期组件，表示一天的结束时间
        guard let endOfDay = calendar.date(byAdding: components, to: startOfDay) else {
            return nil // 如果无法计算结束时间，返回 nil
        }

        let itemsOnDate = items.filter { item in // 过滤出特定日期的日记项
            guard let itemDate = item.date else { return false } // 检查日记项的日期
            return itemDate >= startOfDay && itemDate <= endOfDay // 判断日期是否在范围内
        }
        return itemsOnDate.first // 返回第一个符合条件的日记项
    }
}

#if DEBUG

struct DiaryList_Previews: PreviewProvider { // 定义预览提供者，用于 SwiftUI 预览

    static var content: some View {
        NavigationStack {
            DiaryList(
                dateInterval: .init(start: Date(), end: Date()), // 使用当前日期初始化 DiaryList
                scrollToItem: .constant(nil) // 初始化 scrollToItem 为 nil
            )
        }
    }

    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light) // 设置预览为浅色模式
            content
                .environment(\.colorScheme, .dark) // 设置预览为深色模式
        }
    }
}

#endif