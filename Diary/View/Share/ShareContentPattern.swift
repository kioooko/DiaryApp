//
//  ShareContentPattern.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/07/27.
//

enum ShareContentPattern {
    case imageAndText
    case text
    case checkList

    var name: String {
        switch self {
        case .imageAndText:
            return "画像和文字"
        case .text:
            return "文字"
        case .checkList:
            return "CheckList"
        }
    }
}
