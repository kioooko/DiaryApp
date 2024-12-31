import SwiftUI

struct DiaryText: View {//定义视图: 创建一个名为 DiaryText 的视图结构体，遵循 View 协议
    @EnvironmentObject private var textOptions: TextOptions
//环境对象: 使用 @EnvironmentObject 属性包装器来观察 TextOptions 对象，允许视图在 TextOptions 发生变化时自动更新。
    let text: String
    let action: () -> Void

 var body: some View {
        Button(action: {
            action()
        }, label: {
            ZStack(alignment: .topLeading) {
                Text(text)
                    .textOption(textOptions)
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                    .contentShape(.rect)

                if text.isEmpty {
                    Text("可以在这里编织属于你的日记") .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .textOption(textOptions)
                }
            }
        })
        .buttonStyle(.plain)
       // .background(Color.Neumorphic.main)
    
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
