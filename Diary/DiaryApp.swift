//
//  DiaryApp.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/23.
//

import SwiftUI

@main
struct DiaryApp: App {
    @StateObject var coreDataProvider = CoreDataProvider.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataProvider.container.viewContext)
        }
    }
}
