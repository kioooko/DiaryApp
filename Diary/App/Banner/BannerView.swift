//
//  BannerView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/08.
//

import Combine
import SwiftUI

struct BannerView: View {
    @EnvironmentObject var bannerState: BannerState

    @State private var dismissTask: Task<Void, Never>?

    private let baseHeight: CGFloat = 76
    private let shadowY: CGFloat = 5

    var body: some View {
        VStack {
            banner

            // Banner部分を上部に配置するためにSpacerを付与
            Spacer()
        }
    }
}

private extension BannerView {

    var banner: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 12) {
                IconWithRoundedBackground(
                    systemName: bannerState.mode.imageName,
                    backgroundColor: bannerState.mode.mainColor
                )

                Text(bannerState.mode.message)
                    .bold()
                    .font(.system(size: 14))
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.adaptiveBlack)
            }
            .padding(16)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .foregroundColor(.adaptiveWhite)
            )
            .drawingGroup() // テキストの変更とオフセットの変更アニメーションを同期させるために使用。（memo: これにより、もしViewが.clear（タッチイベントが生じなくなる）などを利用していても、タッチイベントは発生する（透過しない）ようになる。）
            .offset(y: bannerState.isPresented ? 0 : -(geometry.safeAreaInsets.top + baseHeight))
            .animation(Animation.spring(), value: bannerState.isPresented)
            .frame(maxWidth: .infinity)
            .frame(height: baseHeight)
            .adaptiveShadow()
            .onTapGesture {
                bannerState.isPresented = false
            }
        }
        .frame(height: baseHeight)
        .background(.clear)
        .onReceive(bannerState.$isPresented) { isPresented in
            if isPresented {
                dismissTask?.cancel()
                dismissTask = Task.init { @MainActor in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if !Task.isCancelled {
                        bannerState.isPresented = false
                    }
                }
            } else {
                dismissTask?.cancel()
            }
        }
    }
}

#if DEBUG

struct BannerView_Previews: PreviewProvider {
    static var bannerState01: BannerState = {
        let state = BannerState()
        state.mode = .success(message: "成功啦耶🏅")
        return state
    }()
    static var bannerState02: BannerState = {
        let state = BannerState()
        state.mode = .warning(message: "再检查一次吧")
        return state
    }()
    static var bannerState03: BannerState = {
        let state = BannerState()
        state.mode = .error(message: "出了问题，再试一次吧")
        return state
    }()

    static var content: some View {
        NavigationStack{
            VStack {
                BannerView()
                    .environmentObject(bannerState01)
                BannerView()
                    .environmentObject(bannerState02)
                BannerView()
                    .environmentObject(bannerState03)

                Button("change") {
                    bannerState01.show(of: .error(message: "上传失败☹️"))
                }
            }
            .padding(.top, 80)
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
