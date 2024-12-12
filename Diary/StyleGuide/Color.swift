//
//  Color.swift
//  Diary
//  Change for Neumorphicstyle by kioooko on 2024/12/12.
//  Created by Higashihara Yoki on 2023/05/02.
//  

import SwiftUI

extension Color {

    /// 自适应白色：在深色模式下显示为应用黑色，在浅色模式下显示为白色
    public static let adaptiveWhite = Self {
        $0.userInterfaceStyle == .dark ? appBlack : .white
    }

    /// 自适应黑色：在深色模式下显示为白色，在浅色模式下显示为应用黑色
    public static let adaptiveBlack = Self {
        $0.userInterfaceStyle == .dark ? .white : appBlack
    }

    /// 自适应背景色：在深色模式下显示为黑色，在浅色模式下显示为白色
    public static let adaptiveBackground = Self {
        $0.userInterfaceStyle == .dark ? .black : .white
    }

    // 定义应用的标准黑色（使用十六进制值 0x2C2C2E）
    public static let appBlack = hex(0x292d32)

    /*
     primary: 作为应用的主要基调色，经常使用
     secondary: 用于强调或区分元素，需要注意不要过度使用以免喧宾夺主
     primary/secondary variant: 当需要在深色/浅色模式下使用同系列但略有差异的颜色时使用
     */
    
    // 应用主色：深色模式下为浅灰色(0xf5f5f5)，浅色模式下为应用黑色
    public static let appPrimary = Self {
        $0.userInterfaceStyle == .dark ? hex(0xefeef3) : appBlack
    }
    
    // 应用次要色：深色模式下为深灰色(0x525252)，浅色模式下为浅灰色(0xefefef)
    public static let appSecondary = Self {
        $0.userInterfaceStyle == .dark ? hex(0x525252) : hex(0xefefef)
    }

    // 将十六进制颜色值转换为 Color 对象的工具方法
    public static func hex(_ hex: UInt) -> Self {
        Self(
            red: Double((hex & 0xff0000) >> 16) / 255,    // 提取红色分量
            green: Double((hex & 0x00ff00) >> 8) / 255,   // 提取绿色分量
            blue: Double(hex & 0x0000ff) / 255,           // 提取蓝色分量
            opacity: 1                                     // 设置不透明度为1
        )
    }
}

#if canImport(UIKit)

import UIKit

extension Color {

    // 根据 UITraitCollection 动态提供颜色的初始化方法
    public init(dynamicProvider: @escaping (UITraitCollection) -> Color) {
        self = Self(UIColor { UIColor(dynamicProvider($0)) })
    }

    // 定义占位符灰色，使用系统的占位符文本颜色
    public static let placeholderGray = Color(UIColor.placeholderText)
}

#endif

#if DEBUG

struct DemoColorView_Previews: PreviewProvider {

    // 定义预览内容
    static var content: some View {
        NavigationStack {
            VStack {
                // 展示各种颜色的示例
                // ... 预览代码内容 ...
            }
            .shadow(radius: 10)
            .padding(.horizontal)
        }
    }

    // 提供浅色和深色模式的预览
    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light)  // 浅色模式预览

            content
                .environment(\.colorScheme, .dark)   // 深色模式预览
        }
    }
}

#endif
