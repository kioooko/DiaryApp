//
//  ActionButtonStyle.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/02.
//

import SwiftUI

public struct ActionButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    let isActive: Bool
    let size: Size

    public enum Size {
        case extraSmall
        case small
        case medium

        var fontSize: CGFloat {
            switch self {
            case .extraSmall: return 12
            case .small: return 16
            case .medium: return 20
            }
        }

        var buttonWidth: CGFloat {
            switch self {
            case .extraSmall: return 80
            case .small: return 100
            case .medium: return 200
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .extraSmall: return 10
            case .small: return 12
            case .medium: return 15
            }
        }
    }

    public init(
        backgroundColor: Color = .adaptiveBlack,
        foregroundColor: Color = .adaptiveWhite,
        cornerRadius: CGFloat = 13,
        isActive: Bool = true,
        size: Size = .medium
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.isActive = isActive
        self.size = size
    }

    public func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .bold()
            .foregroundStyle(
                self.foregroundColor
                    .opacity(!configuration.isPressed ? 1 : 0.5)
            )
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        self.backgroundColor
                            .opacity(self.isActive && !configuration.isPressed ? 1 : 0.5)
                    )
                    .frame(minWidth: size.buttonWidth)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#if DEBUG

struct Buttons_Previews: PreviewProvider {
    static var previews: some View {
        let view = NavigationStack {
            VStack {
                Section(header: Text("Active")) {
                    Button("按钮") {}
                    NavigationLink("链接", destination: EmptyView())
                }
                .buttonStyle(ActionButtonStyle())

                Section(header: Text("Active with Color")) {
                    Button("按钮") {}
                    NavigationLink("链接", destination: EmptyView())
                }
                .buttonStyle(ActionButtonStyle(backgroundColor: .orange))

                Section(header: Text("Active, small")) {
                    Button("按钮") {}
                    NavigationLink("链接", destination: EmptyView())
                }
                .buttonStyle(ActionButtonStyle(size: .small))

                Section(header: Text("Active, extra small")) {
                    Button("按钮") {}
                    NavigationLink("链接", destination: EmptyView())
                }
                .buttonStyle(ActionButtonStyle(size: .extraSmall))

                Section(header: Text("In-active")) {
                    Button("按钮") {}
                    NavigationLink("链接", destination: EmptyView())
                }
                .buttonStyle(ActionButtonStyle(isActive: false))
                .disabled(true)
            }
        }

        return Group {
            view
                .environment(\.colorScheme, .light)
            view
                .environment(\.colorScheme, .dark)
        }
    }
}

#endif
