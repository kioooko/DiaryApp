import SwiftUI
import Neumorphic

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.Neumorphic.main)
                   // .softOuterShadow()
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct DiaryText: View {
    @EnvironmentObject private var textOptions: TextOptions

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
                    Text("日记内容") .foregroundColor(Color(uiColor: .placeholderText))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .textOption(textOptions)
                }
            }
        })
        .buttonStyle(SoftButtonStyle())
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
