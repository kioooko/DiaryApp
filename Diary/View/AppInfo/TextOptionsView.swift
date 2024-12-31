//
//  TextOptionsView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/10.
//

import SwiftUI
import Neumorphic

struct TextOptionsView: View {
    @EnvironmentObject private var bannerState: BannerState
    @EnvironmentObject private var textOptions: TextOptions

    @State private var fontSize: CGFloat = TextOptions.defaultFontSize
    @State private var lineSpacing: CGFloat = TextOptions.defaultLineSpacing

    private let userDefault = UserDefaults.standard

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                previousSettingsDemo
                downImage
                newSettingsDemo
                fontSizeSlider
                lineSpacingSlider
                jianju
                saveButton
            }
            .padding(20)
        }
        .onAppear {
            fontSize = textOptions.fontSize
            lineSpacing = textOptions.lineSpacing
        }
        .navigationTitle("文本设置")
        .background(Color.Neumorphic.main) // 颜色设置
    }
}


private extension TextOptionsView {
// MARK: View
var previousSettingsDemo: some View {
    // 创建一个 Text 视图，显示文本设置的说明
    Text("日记的文本设置可以修改调整哦！\n这里展示的是目前的设置哦！\n日记内容会以这样的方式呈现。\n快试着滑动下方的滑块看看吧🦈")
        .textOption(
            .init(
                fontSize: textOptions.fontSize, // 使用 textOptions 中的字体大小
                lineSpacing: textOptions.lineSpacing // 使用 textOptions 中的行间距
            )
        )
        .frame(height: 120) // 设置视图的高度为 120
        .padding(.vertical, 16) // 设置垂直方向的内边距为 16
        .padding(.horizontal, 16) // 设置水平方向的内边距为 16
      //  .modifier(NeumorphicCardModifier()) // 应用 NeumorphicCardModifier 修饰符，可能用于实现新拟态风格
}

    var newSettingsDemo: some View {
        Text("这是示例文本哦！\n调整后的日记内容会像这样显示。\n想保存设置的话记得按下下方的按钮🦄")
            .textOption(
                .init(
                    fontSize: fontSize,
                    lineSpacing: lineSpacing
                )
            )
            .frame(height: 200)
            .softOuterShadow() // 添加柔和的外部阴影
    }

    var downImage: some View {
        VStack {
            Image(systemName: "chevron.down")
                .font(.system(size: 20))
        }
    }

    var fontSizeSlider: some View {

        VStack {
            Slider(
                value: $fontSize,
                in: TextOptions.fontSizeRange,
                step: 1
            ) {
                Text("font size")
            } minimumValueLabel: {
                Text("小")
            } maximumValueLabel: {
                Text("大")
            }
        }
        .softOuterShadow() // 添加柔和的外部阴影
        .padding(.bottom, 20) // 添加底部内边距
        
    }

    var lineSpacingSlider: some View {
        Slider(
            value: $lineSpacing,
            in: TextOptions.lineSpacingRange,
            step: 1
        ) {
            Text("line spacing")
        } minimumValueLabel: {
            Text("窄")
        } maximumValueLabel: {
            Text("宽")
        }
          .softOuterShadow() // 添加柔和的外部阴影
    }
var jianju: some View {
    Text("\n")
}
    var saveButton: some View {
        Button("保存") {
            textOptions.save(fontSize: fontSize, lineSpacing: lineSpacing)
            bannerState.show(of: .success(message: "文本设置更新啦🎉"))
        }
        .softButtonStyle(RoundedRectangle(cornerRadius: 12))
        .frame(width: 120, height: 44) // 设置跳过按钮的宽度为80，高度为44

    }
    // MARK: Action
}

#if DEBUG

struct TextOptionsView_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            TextOptionsView()
                .environmentObject(
                    TextOptions(
                        fontSize: TextOptions.fontSizeRange.lowerBound,
                        lineSpacing: TextOptions.lineSpacingRange.lowerBound
                    )
                )
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

