import SwiftUI
import CoreData
import Neumorphic

struct RelationshipView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var bannerState: BannerState
    
    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var selectedContactID: NSManagedObjectID? = nil
    
    @FetchRequest(
        entity: Contact.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)]
    ) private var contacts: FetchedResults<Contact>
    
    // 获取选中的联系人
    private var selectedContact: Contact? {
        if let id = selectedContactID {
            return viewContext.object(with: id) as? Contact
        }
        return nil
    }
    
    // 按关系层级过滤联系人
    private func contactsForTier(_ tier: RelationshipTier) -> [Contact] {
        contacts.filter { $0.tier == tier.rawValue }
    }
    
    // 搜索过滤
    private func filteredContacts(for tier: RelationshipTier) -> [Contact] {
        let tierContacts = contactsForTier(tier)
        if searchText.isEmpty {
            return tierContacts
        }
        return tierContacts.filter { contact in
            guard let name = contact.name else { return false }
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 16) {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // 调试按钮
                    Button("测试添加联系人") {
                        selectedContactID = nil
                        showingAddContact = true
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    
                    ForEach(RelationshipTier.allCases, id: \.self) { tier in
                        VStack(alignment: .leading) {
                            Text(tier.title)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(filteredContacts(for: tier), id: \.objectID) { contact in
                                        VStack {
                                            if let name = contact.name {
                                                Text(name)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            Button("编辑") {
                                                print("点击编辑: \(contact.name ?? "")")
                                                selectedContactID = contact.objectID
                                                showingAddContact = true
                                            }
                                            .padding(8)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                        }
                                        .padding()
                                        .background(Color.Neumorphic.main)
                                        .cornerRadius(12)
                                        .softOuterShadow()
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color.Neumorphic.main)
        .navigationTitle("人际关系")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedContactID = nil
                    showingAddContact = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            if let contact = selectedContact {
                AddContactView(contactToEdit: contact)
                    .environmentObject(bannerState)
                    .environment(\.managedObjectContext, viewContext)
            } else {
                AddContactView()
                    .environmentObject(bannerState)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onChange(of: showingAddContact) { showing in
            if !showing {
                selectedContactID = nil
            }
        }
    }
}

// 联系人区域
struct ContactSection: View {
    let tier: RelationshipTier
    let contacts: [Contact]
    let onSelect: (Contact) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题栏
            HStack {
                Text(tier.title)
                    .font(.headline)
                Spacer()
                Text("(\(contacts.count)/\(tier.limit)人)")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 联系人列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if contacts.isEmpty {
                        Text("没有\(tier.title)联系人")
                            .foregroundColor(.gray)
                            .frame(height: 80)
                            .padding(.horizontal)
                    } else {
                        ForEach(contacts, id: \.objectID) { contact in
                            Button {
                                onSelect(contact)
                            } label: {
                                ContactCard(contact: contact)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }
}

// 联系人卡片
struct ContactCard: View {
    let contact: Contact
    
    var body: some View {
        VStack {
            // 头像
            if let avatarData = contact.avatar,
               let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .softOuterShadow()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
                    .softOuterShadow()
            }
            
            // 姓名
            Text(contact.name ?? "未命名")
                .font(.subheadline)
                .lineLimit(1)
            
            // 最近联系时间
            if let lastInteraction = contact.lastInteraction {
                Text("最近：\(timeAgoString(from: lastInteraction))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 80)
        .padding()
        .background(Color.Neumorphic.main)
        .cornerRadius(12)
        .softOuterShadow()
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: date, to: now)
        
        if let days = components.day {
            if days == 0 {
                return "今天"
            } else if days == 1 {
                return "昨天"
            } else {
                return "\(days)天前"
            }
        }
        return "未知"
    }
}

// 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索联系人...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(8)
        .background(Color.Neumorphic.main)
        .cornerRadius(8)
        .softOuterShadow()
    }
}

#Preview {
    RelationshipView()
        .environmentObject(BannerState())
} 