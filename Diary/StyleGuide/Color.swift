//
//  Color.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/02.
//

import SwiftUI
import Neumorphic

extension Color {

    

    /// Neumorphic 风格的白色
    public static let adaptiveWhite = Self {
        $0.userInterfaceStyle == .dark ? appDarkGray : appLightGray
    }

    /// Neumorphic 风格的黑色
    public static let adaptiveBlack = Self {
        $0.userInterfaceStyle == .dark ? appLightGray : appDarkGray
    }

   

    /// Neumorphic 风格的背景
    public static let adaptiveBackground = Self {
        $0.userInterfaceStyle == .dark ? appDarkGray : appLightGray
    }

    public static let appBlack = hex(0x2C2C2E)
    public static let appLightGray = hex(0xE0E0E0)
    public static let appDarkGray = hex(0x3A3A3C)
    public static let safetyYellow = hex(0xEDFA00)
    public static let greenLight = hex(0x69E147)

    public static let appPrimary = Self {
        $0.userInterfaceStyle == .dark ? hex(0xf5f5f5) : appBlack
    }
    public static let appSecondary = Self {
        $0.userInterfaceStyle == .dark ? hex(0x525252) : hex(0xefefef)
    }

    // Neumorphic 风格的颜色扩展
    public static let neumorphicLight = Self {
        $0.userInterfaceStyle == .dark ? hex(0x2C2C2E) : hex(0xE0E0E0)
    }
    
    public static let neumorphicDark = Self {
        $0.userInterfaceStyle == .dark ? hex(0x1C1C1E) : hex(0xD0D0D0)
    }
    
    public static let neumorphicAccent = Self {
        $0.userInterfaceStyle == .dark ? hex(0x3A3A3C) : hex(0xFFFFFF)
    }

    public static func hex(_ hex: UInt) -> Self {
        Self(
            red: Double((hex & 0xff0000) >> 16) / 255,
            green: Double((hex & 0x00ff00) >> 8) / 255,
            blue: Double(hex & 0x0000ff) / 255,
            opacity: 1
        )
    }
}

#if canImport(UIKit)

import UIKit

extension Color {

    public init(dynamicProvider: @escaping (UITraitCollection) -> Color) {
        self = Self(UIColor { UIColor(dynamicProvider($0)) })
    }

    public static let placeholderGray = Color(UIColor.placeholderText)
}

#endif

#if DEBUG

struct DemoColorView_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            VStack {
                HStack {
                    VStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.adaptiveBlack)
                        Text("adaptiveBlack")
                    }

                    VStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.adaptiveWhite)
                        Text("adaptiveWhite")
                    }
                }

                VStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.adaptiveBackground)
                    Text("adaptiveBackground")
                }

                VStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.placeholderGray)
                    Text("placeholderGray")
                }

                HStack {
                    VStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.appPrimary)
                        Text("appPrimary")
                    }

                    VStack {
                        RoundedRectangle(cornerRadius: 20)
                            .foregroundColor(.appSecondary)
                        Text("appSecondary")
                    }
                }
            }
            .shadow(radius: 10)
            .padding(.horizontal)
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
