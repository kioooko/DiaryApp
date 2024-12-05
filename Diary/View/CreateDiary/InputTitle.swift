//
//  InputTitle.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/06.
//

import SwiftUI

struct InputTitle: View {
    @Binding var title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("起个题目吧（1~100文字）", text: $title)
                .font(.system(size: 20))
                .multilineTextAlignment(.leading)

            if title.count > Item.titleRange.upperBound {
                Text("标题请控制在100个字符以内，简洁更好！")
                    .invalidInput()
                    .font(.system(size: 12))
            }
        }
        .animation(.easeInOut, value: title)
    }
}

#if DEBUG

struct InputTitle_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            VStack(spacing: 50) {
                InputTitle(title: .constant(""))
                InputTitle(title: .constant("窗前明月光123abcdefg"))
                InputTitle(title: .constant("窗前明月光"))
            }
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


