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
                    }
                    .padding()
                }
            }
            .navigationTitle("添加联系人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveContact()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $avatarImage)
            }
        }
    }
    
    private func saveContact() {
        let contact = Contact(context: viewContext)
        contact.name = name
        contact.tier = selectedTier.rawValue
        contact.birthday = birthday
        contact.notes = notes
        contact.createdAt = Date()
        contact.updatedAt = Date()
        
        if let imageData = avatarImage?.jpegData(compressionQuality: 0.8) {
            contact.avatar = imageData
        }
        
        do {
            try viewContext.save()
            bannerState.show(of: .success(message: "联系人添加成功"))
            dismiss()
        } catch {
            bannerState.show(of: .error(message: "保存失败：\(error.localizedDescription)"))
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