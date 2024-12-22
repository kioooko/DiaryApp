//
//  BookmarkListView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/11.
//

import SwiftUI
import Neumorphic

struct BookmarkListView: View {

    @FetchRequest(fetchRequest: Item.bookmarks)
    private var bookmarks: FetchedResults<Item>

    var body: some View {
        VStack() {
            Text("\(bookmarks.count)件")
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(bookmarks) { item in
                        NavigationLink {
                            DiaryDetailView(diaryDataStore: .init(item: item))
                        } label: {
                            DiaryItem(item: item, withYear: true)
                        }
                        .padding(.horizontal, 30)
                        .buttonStyle(PlainButtonStyle())
                      //  .softButtonStyle(RoundedRectangle(cornerRadius: 12)) // 确保 softButtonStyle 应用于 Button
                      //  .buttonStyle(softButtonStyle(RoundedRectangle(cornerRadius: 12)))
                    }
                }
                .padding(.vertical)
                .background(Color.Neumorphic.main)
              //  .softOuterShadow()
            }
            .navigationTitle("收藏")
        }
        .background(Color.Neumorphic.main)
    }
}

private extension BookmarkListView {

    // MARK: View

    var streak: some View {
        NavigationLink("持续天数") {
            TextOptionsView()
        }
    }

    var totalCount: some View {
        NavigationLink("合計") {
            TextOptionsView()
        }
    }

    var textOption: some View {
        NavigationLink("文本设定") {
            TextOptionsView()
        }
    }

    var bookMark: some View {
        NavigationLink("收藏的日记") {
            TextOptionsView()
        }
    }

    // MARK: Action
}

#if DEBUG

struct BookmarkListView_Previews: PreviewProvider {

    static var content: some View {
        BookmarkListView()
    }

    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light)
            content
                .environment(\.colorScheme, .dark)
        }
    }
}

#endif
