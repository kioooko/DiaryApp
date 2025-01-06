import SwiftUI

/**
 日記本文の編集画面

 ScrollViewの中にTextEditorを入れると「改行した際にキーボードの下にもぐり込まない」という挙動の実現が難しいのでSheetなどで本Viewをメインで表示するようにする
 */
struct DiaryTextEditor: View {
    @EnvironmentObject private var textOptions: TextOptions

    @Binding var bodyText: String

    @FocusState private var isFocused: Bool

    let okButtonAction: () -> Void

    var isOverMaxBodyText: Bool {
        bodyText.count > Item.textRange.upperBound
    }

    var body: some View {
        ZStack {
                 Color.Neumorphic.main // 设置背景颜色为 Neumorphic 风格
                .edgesIgnoringSafeArea(.all) // 确保背景颜色覆盖整个视图
        VStack(alignment: .center, spacing: 16) {
            ZStack(alignment: .center) {

                TextEditor(text: $bodyText)
                    .frame(maxHeight: .infinity)
                    .focused($isFocused)
                    .textOption(textOptions)
                    .background(Color.Neumorphic.main)
               
                if bodyText.isEmpty {
                    Text("在这里写下今天的感受吧") 
                        .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .allowsHitTesting(false)
                        .textOption(textOptions)
                }
            }

            HStack(alignment: .center, spacing: 0){
                Text("\(bodyText.count) / \(Item.textRange.upperBound)")
                    .font(.monospacedDigit(.system(size: 16))())
                    .foregroundStyle(isOverMaxBodyText ? Color.red : Color.adaptiveBlack)
                Spacer(minLength: 8)
                Button(action: {
                    okButtonAction()
                }) {
                    Text("OK")
                        .bold()
                        .foregroundStyle(Color.greenLight)
                }
                .softButtonStyle(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
        }
     
        .onAppear {
            isFocused = true
        }
     
    }
  }
}

#if DEBUG

struct DiaryTextEditor_Previews: PreviewProvider {

    struct Demo: View {
        @State var bodyTextEmpty = ""

        @State var bodyText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed eget tortor porta erat feugiat dictum \ndemo\ndemo\ndemo\ndemo\n"

        @State var bodyLongText = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed eget tortor porta erat feugiat dictum\n", count:11)
        var body: some View {
            VStack {
                DiaryTextEditor(
                    bodyText: $bodyTextEmpty, okButtonAction: {}
                )

                DiaryTextEditor(
                    bodyText: $bodyText, okButtonAction: {}
                )

                DiaryTextEditor(
                    bodyText: $bodyLongText, okButtonAction: {}
                )
            }
        }
    }


    static var content: some View {
        Demo()
    }

    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light)
            content
                .environment(\.colorScheme, .dark)
        }
        .environmentObject(TextOptions.preview)
    }
}

#endif

