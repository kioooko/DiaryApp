import SwiftUI

struct DiaryText: View {
    @EnvironmentObject var textOptions: TextOptions

    let text: String
    let action: () -> Void

    var body: some View {
             VStack {
                 Text("Current option") // 正确访问属性
                .padding()
             Button(action: {
            action()
        }, label: {
            ZStack(alignment: .topLeading) {
                Text(text)
                    .textOption(textOptions)
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                    .contentShape(.rect)

                if text.isEmpty {
                    Text("日记内容") .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .textOption(textOptions)
                }
            }
        })
        .buttonStyle(.plain)
              }
    }
}

#Preview("没有文字") {
    DiaryText(text: "") {}
    .environmentObject(TextOptions.preview)
}

#Preview("有文字") {
    DiaryText(text: "place holder") {}
    .environmentObject(TextOptions.preview)
}
