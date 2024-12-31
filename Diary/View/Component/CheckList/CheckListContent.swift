//
//  CheckListContent.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/06/28.
//

import SwiftUI // 导入 SwiftUI 框架，用于构建用户界面
import Neumorphic // 导入 Neumorphic 框架，用于构建 Neumorphic 风格的 UI
struct CheckListContent: View { // 定义一个结构体 CheckListContent，遵循 View 协议
    // Core Dataの変更通知を反映させるためにObservedObjectを設定
    @ObservedObject var item: CheckListItem // 观察一个 CheckListItem 对象，用于响应 Core Data 的更改
    let isChecked: Bool // 定义一个常量 isChecked，表示是否选中

    var body: some View { // 定义视图的主体
        HStack { // 使用水平堆栈布局
            Text(item.title ?? "无标题") // 显示 CheckListItem 的标题，如果为空则显示 "no title"
                .font(.system(size: 18)) // 设置字体大小为 18
                .frame(maxWidth: .infinity, alignment: .leading) // 设置最大宽度为无限，左对齐
            Image(systemName: isChecked ? "checkmark.square.fill" : "square") // 根据 isChecked 显示不同的图标
                .font(.system(size: 26)) // 设置图标的字体大小为 26
                .bold() // 设置图标为粗体
              .foregroundColor(Color.Neumorphic.main) // 设置图标的前景色为主色
        }
    }
}

#if DEBUG

struct CheckListContent_Previews: PreviewProvider { // 定义一个预览提供者，用于 SwiftUI 预览

    static var content: some View { // 定义一个静态属性 content，返回一个视图
        NavigationStack { // 使用 NavigationStack 包裹视图
            VStack { // 使用垂直堆栈布局
                CheckListContent(item: .makeRandom(), isChecked: true) // 创建一个选中的 CheckListContent 视图
                CheckListContent(item: .makeRandom(), isChecked: false) // 创建一个未选中的 CheckListContent 视图
            }
        }
    }

    static var previews: some View { // 定义一个静态属性 previews，返回一个视图组
        Group { // 使用 Group 包裹多个视图
            content
                .environment(\.colorScheme, .light) // 设置环境为浅色模式
            content
                .environment(\.colorScheme, .dark) // 设置环境为深色模式
        }
    }
}

#endif
