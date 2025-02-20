import SwiftUI
import CoreData

struct RelationshipView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var bannerState: BannerState
    
    @State private var searchText = ""
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.Neumorphic.main.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // 搜索栏
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                        
                        // 关系层级列表
                        ForEach(RelationshipTier.allCases, id: \.self) { tier in
                            RelationshipTierSection(tier: tier)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("人际关系")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddContact = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
                    .environmentObject(bannerState)
            }
        }
    }
}

// 关系层级区块
struct RelationshipTierSection: View {
    let tier: RelationshipTier
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题栏
            HStack {
                Text(tier.title)
                    .font(.headline)
                Spacer()
                Text("(\(tier.limit)人)")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 联系人列表
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3) { _ in // 临时使用固定数量，后续会替换为实际数据
                        ContactCard()
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

// 联系人卡片
struct ContactCard: View {
    var body: some View {
        VStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            
            Text("姓名")
                .font(.subheadline)
            
            Text("最近联系：3天前")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(Color.Neumorphic.main)
        .cornerRadius(12)
        .softOuterShadow()
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
