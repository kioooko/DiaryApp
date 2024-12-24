import SwiftUI

struct DiaryText: View {//定义视图: 创建一个名为 DiaryText 的视图结构体，遵循 View 协议
    @EnvironmentObject private var textOptions: TextOptions
//环境对象: 使用 @EnvironmentObject 属性包装器来观察 TextOptions 对象，允许视图在 TextOptions 发生变化时自动更新。
    let text: String
    let action: () -> Void
// 属性声明:
// text: 一个常量字符串，表示要显示的文本。
// action: 一个常量闭包，表示按钮点击时要执行的操作。
    var body: some View {//- 视图主体: 定义视图的主体内容。
             VStack {
                 Text("Current option") // 正确访问属性
                .padding()//- 垂直堆栈: 使用 VStack 垂直排列子视图。
             Button(action: {//文本显示: 显示固定文本 "Current option" 并添加内边距。
            action()
        }, label: {//按钮点击: 创建一个按钮，当点击时执行 action 闭包。
            ZStack(alignment: .topLeading) {//- 堆栈: 使用 ZStack 堆叠子视图。
                Text(text)
                    .textOption(textOptions)
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                    .contentShape(.rect)
// 文本视图: 显示传入的 text。
//自定义修饰符: 假设 textOption 是一个自定义修饰符，用于应用 textOptions 中的样式。
//框架设置: 设置视图的最大宽度为无限，最小高度为 200，顶部对齐。
//内容形状: 设置内容形状为矩形，确保整个区域可点击。
                if text.isEmpty {
                    Text("日记内容") .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .textOption(textOptions)
                }
            }//- 占位符文本: 如果 text 为空，显示占位符 "日记内容"。
//占位符样式: 设置占位符文本颜色为系统的占位符颜色，并应用内边距和 textOptions 样式。
        })
        .buttonStyle(.plain)//- 按钮样式: 设置按钮样式为 .plain，去除默认按钮样式。
              }
    }
}

#Preview("没有文字") {
    DiaryText(text: "") {}
    .environmentObject(TextOptions.preview)
}//- 预览 1: 创建一个 DiaryText 视图的预览，传入空字符串以显示占位符文本，并注入 TextOptions.preview 作为环境对象。

#Preview("有文字") {
    DiaryText(text: "place holder") {}
    .environmentObject(TextOptions.preview)
}//- 预览 2: 创建一个 DiaryText 视图的预览，传入 "place holder" 作为文本，并注入 TextOptions.preview 作为环境对象。
