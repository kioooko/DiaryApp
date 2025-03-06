//
//  FloatingActionButton.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/02.
//

import SwiftUI

struct FloatingButton: View {
    let action: () -> Void

    var body: some View { // 定义视图主体
        Button(actionWithHapticFB: action) { // 创建一个带有触觉反馈的按钮，执行传入的 action 闭包
            HStack(alignment: .center, spacing: 8) { // 水平排列的元素，居中对齐，间距为 8
                Image("BZicon20") // 添加一个系统 "plus" 图标
                    .bold() // 使图标变粗
                    .font(.system(size: 20)) // 设置图标字体大小为 20
                    .foregroundColor(.greenLight) // 设置图标颜色为浅绿色
                    .padding(1) // 图标周围添加 1 点的内边距
                   
                Text("作成") // 添加文本"作成"（日语，意为"创建"）
                    .font(.system(size: 16)) // 设置文本字体大小为 16
                    .bold() // 使文本变粗
                    .foregroundColor(.gray) // 设置文本颜色为灰色
            }
            .padding(.vertical, 16) // 垂直方向内边距为 16
            .padding(.horizontal, 20) // 水平方向内边距为 20
            .background( // 设置背景
                Capsule() // 创建一个胶囊形状（两端为半圆的圆角矩形）
                    .fill(Color.Neumorphic.main) // 填充拟物化主色
                   .softOuterShadow() // 添加柔和的外阴影效果，实现拟物化设计
            )
        }
    }
}

#if DEBUG

struct FloatingButton_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            FloatingButton {
                print("tap button")
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
