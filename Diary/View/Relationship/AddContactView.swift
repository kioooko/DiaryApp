import SwiftUI
import Neumorphic

struct AddContactView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var bannerState: BannerState
    
    @State private var name = ""
    @State private var selectedTier: RelationshipTier = .acquaintance
    @State private var birthday: Date = Date()
    @State private var notes = ""
    @State private var showingImagePicker = false
    @State private var avatarImage: UIImage?
    @State private var showingDeleteAlert = false
    
    // 用于编辑现有联系人的属性
    var contactToEdit: Contact?
    
    // 初始化时检查是否有要编辑的联系人
    init(contactToEdit: Contact? = nil) {
        self.contactToEdit = contactToEdit
        if let contact = contactToEdit {
            _name = State(initialValue: contact.name ?? "")
            _selectedTier = State(initialValue: RelationshipTier(rawValue: contact.tier ?? "") ?? .acquaintance)
            _birthday = State(initialValue: contact.birthday ?? Date())
            _notes = State(initialValue: contact.notes ?? "")
            if let avatarData = contact.avatar {
                _avatarImage = State(initialValue: UIImage(data: avatarData))
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 头像选择
                        Button {
                            showingImagePicker = true
                        } label: {
                            if let image = avatarImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .softOuterShadow()
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                    .softOuterShadow()
                            }
                        }
                        .padding(.top)
                        
                        // 基本信息
                        VStack(spacing: 16) {
                            // 姓名
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.gray)
                                TextField("姓名", text: $name)
                            }
                            .padding()
                            .background(Color.Neumorphic.main)
                            .cornerRadius(8)
                            .softOuterShadow()
                            .padding(.horizontal)
                            
                            // 关系层级
                            HStack {
                                Image(systemName: "person.2")
                                    .foregroundColor(.gray)
                                Picker("关系层级", selection: $selectedTier) {
                                    ForEach(RelationshipTier.allCases, id: \.self) { tier in
                                        Text(tier.title).tag(tier)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            .padding()
                            .background(Color.Neumorphic.main)
                            .cornerRadius(8)
                            .softOuterShadow()
                            .padding(.horizontal)
                            
                            // 生日
                            HStack {
                                Image(systemName: "gift")
                                    .foregroundColor(.gray)
                                DatePicker("生日", selection: $birthday, displayedComponents: .date)
                            }
                            .padding()
                            .background(Color.Neumorphic.main)
                            .cornerRadius(8)
                            .softOuterShadow()
                            .padding(.horizontal)
                            
                            // 备注
                            HStack {
                                Image(systemName: "note.text")
                                    .foregroundColor(.gray)
                                TextField("备注", text: $notes)
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
                                showingDeleteAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("删除联系人")
                                }
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
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
            .navigationTitle(contactToEdit == nil ? "添加联系人" : "编辑联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(contactToEdit == nil ? "保存" : "更新") {
                        saveOrUpdateContact()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $avatarImage)
            }
            .alert("确定删除该联系人？", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteContact()
                }
            } message: {
                Text("此操作无法撤销")
            }
        }
    }
    
    private func saveOrUpdateContact() {
        let contact = contactToEdit ?? Contact(context: viewContext)
        contact.id = contactToEdit?.id ?? UUID()
        contact.name = name
        contact.tier = selectedTier.rawValue
        contact.birthday = birthday
        contact.notes = notes
        contact.lastInteraction = Date()
        
        if contactToEdit == nil {
            contact.createdAt = Date()
        }
        contact.updatedAt = Date()
        
        if let imageData = avatarImage?.jpegData(compressionQuality: 0.8) {
            contact.avatar = imageData
        }
        
        do {
            try viewContext.save()
            bannerState.show(of: .success(message: contactToEdit == nil ? "联系人添加成功" : "联系人更新成功"))
            dismiss()
        } catch {
            bannerState.show(of: .error(message: "保存失败：\(error.localizedDescription)"))
        }
    }
    
    private func deleteContact() {
        if let contact = contactToEdit {
            viewContext.delete(contact)
            do {
                try viewContext.save()
                bannerState.show(of: .success(message: "联系人删除成功"))
                dismiss()
            } catch {
                bannerState.show(of: .error(message: "删除失败：\(error.localizedDescription)"))
            }
        }
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddContactView()
        .environmentObject(BannerState())
} 