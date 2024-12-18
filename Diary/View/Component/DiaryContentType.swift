//
//  DiaryContentType.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/06/16.
//  Change by KIOOOKO on 2024/12/17


enum DiaryContentType: CaseIterable {
    case text
    case checkList

    var name: String {
        switch self {
        case .text:
            return "文本"
        case .checkList:
            return "每天的CheckList"
        }
    }
}
