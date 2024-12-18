//
//  TextOptionsView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/10.
//

import SwiftUI

struct TextOptionsView: View {
    @EnvironmentObject private var bannerState: BannerState
    @EnvironmentObject private var textOptions: TextOptions

    @State private var fontSize: CGFloat = TextOptions.defaultFontSize
    @State private var lineSpacing: CGFloat = TextOptions.defaultLineSpacing

    private let userDefault = UserDefaults.standard

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("日记的文本设置可以修改调整哦😄")
                    .font(.system(size: 16))
                previousSettingsDemo
                downImage
                newSettingsDemo
                fontSizeSlider
                lineSpacingSlider
                saveButton
            }
            .padding(20)
        }
        .onAppear {
            fontSize = textOptions.fontSize
            lineSpacing = textOptions.lineSpacing
        }
        .navigationTitle("文本设置")
    }
}


private extension TextOptionsView {

    // MARK: View

    var previousSettingsDemo: some View {
        Text("这里是目前的设置哦！\n日记内容会以这样的方式呈现。\n快试着滑动下方的滑块看看吧🦈")
          //  .textOption(
          //      .init(
                  //  fontSize: textOptions.fontSize,
                   // lineSpacing: textOptions.lineSpacing
             //   )
        //    )
         //   .frame(height: 100)
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
    }

    var downImage: some View {
        VStack {
            Image(systemName: "chevron.down")
                .font(.system(size: 30))
            Image(systemName: "chevron.down")
                .font(.system(size: 30))
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
    }

    var saveButton: some View {
        Button("保存") {
            textOptions.save(fontSize: fontSize, lineSpacing: lineSpacing)
            bannerState.show(of: .success(message: "文本设置更新啦🎉"))
        }
        .buttonStyle(ActionButtonStyle())
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

