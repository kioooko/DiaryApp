//
//  ShareView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/07/23.
//

import SwiftUI // 导入 SwiftUI 框架，用于构建用户界面
import CoreData
struct ShareView: View { // 定义一个名为 ShareView 的视图结构体，遵循 View 协议
    @Environment(\.dismiss) private var dismiss // 从环境中获取 dismiss 方法，用于关闭视图
    @Environment(\.displayScale) private var displayScale // 从环境中获取设备的显示比例
    @EnvironmentObject private var bannerState: BannerState // 从环境中获取 BannerState 对象

    let item: Item // 定义一个常量 item，表示要分享的日记项

    @State private var renderedImage: UIImage = UIImage(named: "sample")! // 状态变量，存储渲染后的图像
    @State private var contentPattern: ShareContentPattern? // 状态变量，存储当前选择的内容模式
    @State private var isActivityViewPresented = false // 状态变量，控制活动视图的显示

    var body: some View { // 定义视图的主体
        ZStack { // 使用 ZStack 叠加视图
            Color.Neumorphic.main // 设置背景颜色为 Neumorphic 风格
                .edgesIgnoringSafeArea(.all) // 确保背景颜色覆盖整个视图

            ScrollView { // 使用 ScrollView 包裹内容
                VStack { // 使用 VStack 垂直排列子视图
                    xButton // 显示关闭按钮

                    VStack(spacing: 40) { // 垂直排列图像和按钮，间距为 40
                        VStack {
                            Image(uiImage: renderedImage) // 显示渲染后的图像
                            layoutPatternList // 显示布局模式列表
                        }

                        HStack(spacing: 30) { // 水平排列分享和保存按钮，间距为 30
                            shareButton // 显示分享按钮
                            saveButton // 显示保存按钮
                        }
                    }
                }
                .padding(.horizontal, 10) // 设置水平填充
                .padding(.vertical) // 设置垂直填充
            }
            .sheet(isPresented: $isActivityViewPresented) { // 显示活动视图
                ActivityView(
                    activityItems: [renderedImage], // 活动视图中包含的项目
                    applicationActivities: nil
                )
                .presentationDetents([.medium]) // 设置活动视图的显示大小
            }
            .onAppear { // 当视图出现时执行
                contentPattern = availableLayoutPatterns.first // 设置初始内容模式
                render() // 渲染图像
            }
            .onChange(of: contentPattern) { _ in // 当内容模式改变时执行
                render() // 重新渲染图像
            }
        }
    }
}

private extension ShareView { // 扩展 ShareView，添加私有方法和属性

    var xButton: some View { // 定义关闭按钮
        HStack {
            Spacer() // 占位符，用于将按钮推到右侧
            XButton {
                dismiss() // 点击时关闭视图
            }
            .padding(.trailing) // 设置右侧填充
        }
    }

    var availableLayoutPatterns: [ShareContentPattern] { // 定义可用的布局模式
        var patterns: [ShareContentPattern] = []
        let hasText = (item.body != nil) && !((item.body ?? "").isEmpty) // 检查是否有文本
        let hasChecklist = !item.checkListItemsArray.isEmpty // 检查是否有检查列表

        if item.imageData != nil, hasText {
            patterns.append(.imageAndText) // 如果有图像和文本，添加 imageAndText 模式
        }

        if hasText {
            patterns.append(.text) // 如果有文本，添加 text 模式
        }

        if hasChecklist {
            patterns.append(.checkList) // 如果有检查列表，添加 checkList 模式
        }

        return patterns // 返回可用的布局模式
    }

    @ViewBuilder
    var layoutPatternList: some View { // 定义布局模式列表
        if availableLayoutPatterns.count > 1 { // 如果有多个可用模式
            HStack(spacing: 8) { // 水平排列模式按钮，间距为 8
                ForEach(availableLayoutPatterns, id: \.self) { pattern in
                    Button(action: {
                        contentPattern = pattern // 点击时设置内容模式
                    }) {
                        Text(pattern.name) // 显示模式名称
                            .font(.system(size: 12)) // 设置字体大小
                            .fontWeight(contentPattern == pattern ? .heavy : .medium) // 根据选中状态设置字体粗细
                            .foregroundColor(.primary) // 设置文本颜色
                            .padding(.vertical, 10) // 设置垂直填充
                            .padding(.horizontal, 14) // 设置水平填充
                            .background {
                                RoundedRectangle(cornerRadius: 20) // 设置背景为圆角矩形
                                .fill(Color.Neumorphic.main)
                                .softOuterShadow() // 添加外部阴影
                    }
                            }
                           
                }
            }
        }
    }

    var shareButton: some View { // 定义分享按钮
        Button(actionWithHapticFB: {
            isActivityViewPresented = true // 点击时显示活动视图
        }) {
            VStack(spacing: 4) { // 垂直排列图标和文本，间距为 4
                Image(systemName: "square.and.arrow.up") // 显示分享图标
                    .font(.system(size: 16)) // 设置图标大小
                    .foregroundColor(.adaptiveBlack) // 设置图标颜色
                    .padding(12) // 设置内边距
                    .background {
                        Circle() // 设置背景为圆形
                            .fill(Color.Neumorphic.main) // 设置背景颜色
                    }
                    .softOuterShadow() // 添加外部阴影

                Text("\n分享") // 显示分享文本
                    .font(.system(size: 14)) // 设置字体大小
                    .foregroundColor(.adaptiveBlack) // 设置文本颜色
            }
        }
    }

    var saveButton: some View { // 定义保存按钮
        Button(actionWithHapticFB: {
            saveImage() // 点击时保存图像
        }) {
            VStack(spacing: 4) { // 垂直排列图标和文本，间距为 4
                Image(systemName: "arrow.down.circle") // 显示保存图标
                    .font(.system(size: 16)) // 设置图标大小
                    .foregroundColor(.adaptiveBlack) // 设置图标颜色
                    .padding(12) // 设置内边距
                    .background {
                        Circle() // 设置背景为圆形
                            .fill(Color.Neumorphic.main) // 设置背景颜色
                    }
                    .softOuterShadow() // 添加外部阴影
                Text("\n保存") // 显示保存文本
                    .font(.system(size: 14)) // 设置字体大小
                  //  .foregroundColor(.adaptiveBlack) // 设置文本颜色
            }
        }
    }

    // MARK: Action

    @MainActor
    func render() { // 渲染图像
        guard let contentPattern else {
            return // 如果没有内容模式，返回
        }

        let renderer = ImageRenderer( // 创建图像渲染器
            content: ShareImageRender(
                backgroundColor: Color.Neumorphic.main, // 设置背景颜色
                item: item, // 设置要渲染的项目
                contentPattern: contentPattern // 设置内容模式
            )
        )

        // 确保使用设备的正确显示比例
        renderer.scale = displayScale
        renderer.proposedSize = ProposedViewSize(width: UIScreen.main.bounds.size.width * 0.9, height: nil)

        if let uiImage = renderer.uiImage { // 如果渲染成功
            renderedImage = uiImage // 更新渲染后的图像
        }
    }

    func saveImage() { // 保存图像
        let imageSaver = ImageSaver() // 创建图像保存器
        imageSaver.writeToPhotoAlbum(image: renderedImage) { // 将图像写入相册
            bannerState.show(of: .success(message: "保存成功啦 🎉")) // 显示成功消息
        }
    }
}

#if DEBUG

struct ShareView_Previews: PreviewProvider { // 定义 ShareView 的预览提供者

    static var content: some View {
        NavigationStack {
            ShareView(item: .makeRandom(withImage: true)) // 创建一个带有随机图像的 ShareView
        }
    }

    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light) // 设置预览为浅色模式
            content
                .environment(\.colorScheme, .dark) // 设置预览为深色模式
        }
    }
}

#endif