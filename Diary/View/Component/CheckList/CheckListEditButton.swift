//
//  CheckListEditButton.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/07/10.
//

import SwiftUI

struct CheckListEditButton: View {

    var body: some View {
        HStack {
            Text("管理你的CheckList")
                .font(.system(size: 14))
                .foregroundColor(.adaptiveBlack)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.Neumorphic.main)
        }
        .softOuterShadow()
    }
}
