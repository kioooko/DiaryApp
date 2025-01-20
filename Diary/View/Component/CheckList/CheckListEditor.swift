//
//  CheckListEditor.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/06/28.
//

// 导入 SwiftUI 框架
import SwiftUI

// 定义一个 `CheckListEditor` 视图结构体
struct CheckListEditor: View {
    // 使用 @EnvironmentObject 修饰符从环境中获取 BannerState 对象
    @EnvironmentObject private var bannerState: BannerState

    // 使用 @FetchRequest 修饰符获取所有 CheckListItem 数据
    @FetchRequest(fetchRequest: CheckListItem.all)
    private var checkListItems: FetchedResults<CheckListItem>

    // 定义一个状态变量，用于跟踪编辑状态
    @State private var editState: CheckListEditState?
    // 定义一个状态变量，用于保存当前编辑中的项目标题
    @State private var editingItemTitle = ""
    // 定义一个状态变量，表示是否显示文本编辑器
    @State private var isPresentedTextEditor = false

    // 定义一个日期格式化工具，设置日期格式为 medium 并根据应用语言设置本地化
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = .appLanguageLocale
        return formatter
    }()

    // 定义视图的主体内容
    var body: some View {
        ZStack {
            // 背景颜色设置为 Neumorphic 风格
            Color.Neumorphic.main
                .edgesIgnoringSafeArea(.all) // 背景覆盖整个视图区域
            ScrollView {
                VStack(spacing: 20) { // 垂直布局，设置间距为 20
                    // 遍历 checkListItems 数据并生成视图
                    ForEach(checkListItems, id: \.objectID) { item in
                        checkListItem(item) // 调用自定义的 checkListItem 方法
                    }

                    addNewItem // 调用自定义的 addNewItem 视图
                        .padding(.top) // 设置顶部间距
                }
            } 
            .padding() // 外部边距
            .softOuterShadow() // 添加柔和的外阴影效果

            // 如果存在编辑状态且文本编辑器需要显示，则显示 CheckListTextEditor
            if let editState, isPresentedTextEditor  {
                CheckListTextEditor(
                    isPresented: $isPresentedTextEditor,
                    editState: editState
                )
            }
        }
        .navigationTitle("CheckList") // 设置导航标题
        .navigationBarTitleDisplayMode(.inline) // 标题居中显示
    }
}

// 定义一个枚举，用于表示编辑状态
enum CheckListEditState {
    case createNewItem // 创建新项目
    case editCurrentItem(item: CheckListItem) // 编辑当前项目
}

// 扩展 `CheckListEditor` 添加私有方法和视图
private extension CheckListEditor {

    // MARK: View

    // 添加新项目按钮视图
    var addNewItem: some View {
        Button(actionWithHapticFB: { // 按钮点击触发动作，并伴随触觉反馈
            editState = .createNewItem // 设置编辑状态为创建新项目
            isPresentedTextEditor = true // 显示文本编辑器
        }) {
            Text("追加新的CheckList") // 按钮文字
                .font(.system(size: 16)) // 字体大小
                .foregroundColor(.adaptiveBlack) // 自适应黑色
                .multilineTextAlignment(.leading) // 左对齐
                .padding(.vertical, 16) // 垂直内边距
                .padding(.horizontal, 16) // 水平内边距
                .background { // 按钮背景
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.Neumorphic.main)
                }
                .softOuterShadow() // 添加柔和外阴影
        }
    }

    // 列表中单个项目的视图
    func checkListItem(_ item: CheckListItem) -> some View {
        Button(actionWithHapticFB: { // 点击触发编辑动作
            editState = .editCurrentItem(item: item) // 设置编辑状态为编辑当前项目
            isPresentedTextEditor = true // 显示文本编辑器
        }) {
            HStack { // 水平布局
                Text(item.title ?? "无标题") // 显示项目标题
                    .font(.system(size: 20)) // 字体大小
                    .frame(maxWidth: .infinity, alignment: .leading) // 左对齐，宽度填充

                if let createdAt = item.createdAt { // 如果有创建日期
                    Text(createdAt, formatter: dateFormatter) // 显示格式化后的日期
                        .font(.system(size: 12)) // 字体大小
                        .frame(maxWidth: .infinity, alignment: .trailing) // 右对齐
                        .foregroundColor(.gray) // 灰色字体
                }
            }
            .contentShape(Rectangle()) // 设置点击区域为整个内容区域
        }
        .buttonStyle(.plain) // 使用普通按钮样式
    }
    // MARK: Action
}

// 预览代码，仅用于调试环境
#if DEBUG

struct CheckListEditor_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            CheckListEditor()
                .environment(
                    \.managedObjectContext,
                     CoreDataProvider.preview.container.viewContext // 使用预览上下文
                )
        }
    }

    static var previews: some View {
        Group { // 同时预览亮色和暗色模式
            content
                .environment(\.colorScheme, .light)
            content
                .environment(\.colorScheme, .dark)
        }
    }
}

#endif
