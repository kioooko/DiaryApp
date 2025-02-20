import SwiftUI
import CoreData

struct RelationshipView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var bannerState: BannerState
    
    @State private var searchText = ""
    @State private var showingAddContact = false
    
    @FetchRequest(
        entity: Contact.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Contact.name, ascending: true)]
    ) private var contacts: FetchedResults<Contact>
    
    // 按关系层级过滤联系人
    private func contactsForTier(_ tier: RelationshipTier) -> [Contact] {
        contacts.filter { $0.relationshipTier == tier }
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
                            contacts: filteredContacts(for: tier)
                        )
                    }
                }
                .padding(.vertical)
            }
        }
        .background(Color.Neumorphic.main)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Text("人际关系")
                        .fontWeight(.bold)
                    Button {
                        showingAddContact = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddContactView()
                .environmentObject(bannerState)
        }
    }
}

struct RelationshipTierSection: View {
    let tier: RelationshipTier
    let contacts: [Contact]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tier.title)
                    .font(.headline)
                Spacer()
                Text("(\(contacts.count)/\(tier.limit)人)")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(contacts, id: \.objectID) { contact in
                        ContactCard(contact: contact)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ContactCard: View {
    let contact: Contact
    
    var body: some View {
        VStack {
            if let avatarData = contact.avatar,
               let uiImage = UIImage(data: avatarData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            Text(contact.name ?? "未命名")
                .font(.subheadline)
            
            if let lastInteraction = contact.lastInteraction {
                Text("最近联系：\(lastInteraction.timeAgoDisplay())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 80)
        .padding()
        .background(Color.Neumorphic.main)
        .cornerRadius(12)
        .softOuterShadow()
    }
}

// 时间显示扩展
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: self, to: now)
        
        if let day = components.day {
            if day > 30 {
                let formatter = DateFormatter()
                formatter.dateFormat = "MM-dd"
                return formatter.string(from: self)
            } else if day > 0 {
                return "\(day)天前"
            }
        }
        
        if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        }
        
        if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        }
        
        return "刚刚"
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
