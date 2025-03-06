import SwiftUI // 导入 SwiftUI 框架，提供 UI 组件和布局功能
import Neumorphic // 导入 Neumorphic 框架，提供拟物化设计风格的 UI 元素

struct AddContactView: View { // 定义添加/编辑联系人的视图
    @Environment(\.managedObjectContext) private var viewContext // 获取环境中的 Core Data 管理对象上下文
    @Environment(\.dismiss) private var dismiss // 获取环境中的关闭视图功能
    @EnvironmentObject private var bannerState: BannerState // 获取环境中的横幅状态对象，用于显示通知
    
    // 表单状态变量
    @State private var name = "" // 联系人姓名
    @State private var selectedTier: RelationshipTier = .acquaintance // 选中的关系层级，默认为"认识的人"
    @State private var birthday: Date = Date() // 生日日期，默认为当前日期
    @State private var notes = "" // 备注信息
    @State private var showingImagePicker = false // 控制是否显示图片选择器
    @State private var avatarImage: UIImage? // 存储联系人头像图片
    @State private var showingDeleteAlert = false // 控制是否显示删除确认对话框
    
    // 用于编辑现有联系人的属性
    var contactToEdit: Contact? // 如果是编辑模式，存储要编辑的联系人对象
    
    // 初始化方法：检查是否有要编辑的联系人，并加载其数据
    init(contactToEdit: Contact? = nil) {
        self.contactToEdit = contactToEdit
        if let contact = contactToEdit { // 如果是编辑模式，初始化表单数据
            _name = State(initialValue: contact.name ?? "")
            _selectedTier = State(initialValue: RelationshipTier(rawValue: contact.tier ?? "") ?? .acquaintance)
            _birthday = State(initialValue: contact.birthday ?? Date())
            _notes = State(initialValue: contact.notes ?? "")
            if let avatarData = contact.avatar {
                _avatarImage = State(initialValue: UIImage(data: avatarData))
            }
        }
    }
    
    var body: some View { // 视图主体
        NavigationView { // 导航视图容器
            ZStack { // 堆叠布局
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all) // 设置背景色，忽略安全区域
                
                ScrollView { // 滚动视图
                    VStack(spacing: 20) { // 垂直栈布局，元素间距 20
                        // 头像选择按钮
                        Button {
                            showingImagePicker = true // 点击时显示图片选择器
                        } label: {
                            if let image = avatarImage { // 如果有头像图片则显示
                                Image(uiImage: image)
                                    .resizable() // 使图片可调整大小
                                    .scaledToFill() // 填充模式
                                    .frame(width: 100, height: 100) // 设置尺寸
                                    .clipShape(Circle()) // 裁剪为圆形
                                    .softOuterShadow() // 添加柔和外阴影
                            } else { // 没有头像时显示默认图标
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                    .softOuterShadow()
                            }
                        }
                        .padding(.top) // 顶部间距
                        
                        // 基本信息表单
                        VStack(spacing: 16) { // 垂直栈，元素间距 16
                            // 姓名输入框
                            HStack {
                                Image(systemName: "person") // 人物图标
                                    .foregroundColor(.gray)
                                TextField("姓名", text: $name) // 文本输入框，绑定到 name 状态
                            }
                            .padding() // 内边距
                            .background(Color.Neumorphic.main) // 背景色
                            .cornerRadius(8) // 圆角
                            .softOuterShadow() // 外阴影
                            .padding(.horizontal) // 水平内边距
                            
                            // 关系层级选择器
                            HStack {
                                Image(systemName: "person.2") // 两人图标
                                    .foregroundColor(.gray)
                                Picker("关系层级", selection: $selectedTier) { // 下拉选择器，绑定到 selectedTier
                                    ForEach(RelationshipTier.allCases, id: \.self) { tier in
                                        Text(tier.title).tag(tier) // 显示每个关系层级的标题
                                    }
                                }
                                .pickerStyle(MenuPickerStyle()) // 菜单样式的选择器
                            }
                            .padding()
                            .background(Color.Neumorphic.main)
                            .cornerRadius(8)
                            .softOuterShadow()
                            .padding(.horizontal)
                            
                            // 生日选择器
                            HStack {
                                Image(systemName: "gift") // 礼物图标
                                    .foregroundColor(.gray)
                                DatePicker("生日", selection: $birthday, displayedComponents: .date) // 日期选择器，只显示日期
                            }
                            .padding()
                            .background(Color.Neumorphic.main)
                            .cornerRadius(8)
                            .softOuterShadow()
                            .padding(.horizontal)
                            
                            // 备注输入框
                            HStack {
                                Image(systemName: "note.text") // 笔记图标
                                    .foregroundColor(.gray)
                                TextField("备注", text: $notes) // 文本输入框，绑定到 notes
                            }
                            .padding()
                            .background(Color.Neumorphic.main)
                            .cornerRadius(8)
                            .softOuterShadow()
                            .padding(.horizontal)
                        }
                        
                        // 删除按钮 - 仅在编辑模式下显示
                        if contactToEdit != nil {
                            Button {
                                showingDeleteAlert = true // 点击时显示删除确认对话框
                            } label: {
                                HStack {
                                    Image(systemName: "trash") // 垃圾桶图标
                                    Text("删除联系人")
                                }
                                .foregroundColor(.red) // 红色文字
                                .padding()
                                .frame(maxWidth: .infinity) // 最大宽度
                                .background(Color.Neumorphic.main)
                                .cornerRadius(8)
                                .softOuterShadow()
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(contactToEdit == nil ? "添加联系人" : "编辑联系人") // 根据模式设置导航标题
            .navigationBarTitleDisplayMode(.inline) // 内联显示标题
            .toolbar { // 工具栏
                ToolbarItem(placement: .navigationBarLeading) { // 左侧工具栏项
                    Button("取消") {
                        dismiss() // 关闭视图
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) { // 右侧工具栏项
                    Button(contactToEdit == nil ? "保存" : "更新") { // 根据模式显示"保存"或"更新"
                        saveOrUpdateContact() // 保存或更新联系人
                    }
                    .disabled(name.isEmpty) // 如果姓名为空则禁用按钮
                }
            }
            .sheet(isPresented: $showingImagePicker) { // 显示图片选择器的 sheet
                ImagePicker(image: $avatarImage) // 自定义图片选择器，绑定到 avatarImage
            }
            .alert("确定删除该联系人？", isPresented: $showingDeleteAlert) { // 删除确认对话框
                Button("取消", role: .cancel) { } // 取消按钮
                Button("删除", role: .destructive) { // 删除按钮，具有破坏性操作样式
                    deleteContact() // 执行删除操作
                }
            } message: {
                Text("此操作无法撤销") // 警告信息
            }
        }
    }
    
    // 保存或更新联系人的方法
    private func saveOrUpdateContact() {
        let contact = contactToEdit ?? Contact(context: viewContext) // 使用现有联系人或创建新联系人
        contact.id = contactToEdit?.id ?? UUID() // 设置 ID
        contact.name = name // 设置姓名
        contact.tier = selectedTier.rawValue // 设置关系层级
        contact.birthday = birthday // 设置生日
        contact.notes = notes // 设置备注
        contact.lastInteraction = Date() // 设置最近互动时间为当前时间
        
        if contactToEdit == nil { // 如果是新建联系人
            contact.createdAt = Date() // 设置创建时间
        }
        contact.updatedAt = Date() // 更新最后修改时间
        
        if let imageData = avatarImage?.jpegData(compressionQuality: 0.8) { // 转换头像为 JPEG 数据
            contact.avatar = imageData // 保存头像数据
        }
        
        do {
            try viewContext.save() // 尝试保存到 Core Data
            bannerState.show(of: .success(message: contactToEdit == nil ? "联系人添加成功" : "联系人更新成功")) // 显示成功消息
            dismiss() // 关闭视图
        } catch {
            bannerState.show(of: .error(message: "保存失败：\(error.localizedDescription)")) // 显示错误消息
        }
    }
    
    // 删除联系人的方法
    private func deleteContact() {
        if let contact = contactToEdit {
            viewContext.delete(contact) // 从 Core Data 中删除联系人
            do {
                try viewContext.save() // 尝试保存更改
                bannerState.show(of: .success(message: "联系人删除成功")) // 显示成功消息
                dismiss() // 关闭视图
            } catch {
                bannerState.show(of: .error(message: "删除失败：\(error.localizedDescription)")) // 显示错误消息
            }
        }
    }
}

// 图片选择器 - 用于从相册选择头像
struct ImagePicker: UIViewControllerRepresentable { // UIKit 视图控制器的 SwiftUI 包装器
    @Binding var image: UIImage? // 绑定选中的图片
    @Environment(\.dismiss) private var dismiss // 获取关闭功能
    
    // 创建 UIKit 视图控制器
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController() // 创建图片选择控制器
        picker.delegate = context.coordinator // 设置代理
        return picker
    }
    
    // 更新 UIKit 视图控制器（此处不需要任何操作）
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    // 创建协调器，处理 UIKit 代理回调
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 协调器类，实现 UIImagePickerController 的代理协议
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker // 对父视图的引用
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        // 当用户选择了图片时调用
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage { // 获取选中的原始图片
                parent.image = image // 更新绑定的图片
            }
            parent.dismiss() // 关闭选择器
        }
        
        // 当用户取消选择时调用
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss() // 关闭选择器
        }
    }
}

// 预览提供者，用于在 Xcode 中预览视图
#Preview {
    AddContactView() // 预览添加联系人视图
        .environmentObject(BannerState()) // 注入横幅状态对象
}