import SwiftUI
import Neumorphic
import CoreData

struct DiaryRow: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if item.amount != 0 {
                // 记账展示
                ExpenseContent(item: item)
            } else {
                // 日记展示
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let date = item.date {
                                Text(date, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            if item.isBookmarked {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                            }
                            
                            Spacer()
                        }
                        
                        if let title = item.title, !title.isEmpty {
                            Text(title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        if let body = item.body, !body.isEmpty {
                            Text(body)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                    }
                }
                .padding()
                .background(Color.Neumorphic.main)
                .cornerRadius(10)
                .softOuterShadow()
            }
        }
    }
} 