import SwiftUI
import CoreData
import Neumorphic

struct RelationshipView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var bannerState: BannerState
    
    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var contactToEdit: Contact?
    
    @FetchRequest(
        entity: Contact.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)]
    ) private var contacts: FetchedResults<Contact>
    
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
                    
                    ForEach(RelationshipTier.allCases, id: \.self) { tier in
                        RelationshipTierSection(
                            tier: tier,
                            contacts: filteredContacts(for: tier),
                            onContactSelected: { contact in
                                self.contactToEdit = contact
                                self.showingAddContact = true
                            }
                        )
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
                    self.contactToEdit = nil
                    self.showingAddContact = true
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            // 显式传递环境以确保上下文正确
            AddContactView(contactToEdit: contactToEdit)
                .environmentObject(bannerState)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// 关系层级区块
struct RelationshipTierSection: View {
    let tier: RelationshipTier
    let contacts: [Contact]
    let onContactSelected: (Contact) -> Void
    
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
                            ContactCard(contact: contact)
                                .onTapGesture {
                                    onContactSelected(contact)
                                }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
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