//
//  FeedbackPhrase.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/07/03.
//

import Foundation

final class FeedbackPhrase {

    private let motivationalPhrases: [String] = [
        "将琐碎的生活变成一段段珍贵的记忆",
        "用文字和习惯编织生活，这是一段属于你自己的旅程",
        "日记是心灵的栖息地",
        "规划任务，为梦想铺路",
        "你的人际关系，也值得用心记录",
        "管理财务，感受每一分钱的意义",
        "每一个微小的进步，都是成长的足迹",
        "编织生活，让你的每一天都更充实"
    ]
    private let praisePhrases: [String] = [
        "陪伴你成长的每一天",
        "总结一天，是为更好地迎接明天",
        "你的记录让每一天都更有意义",
        "今天，你又为生活增添了一抹亮色",
        "真棒！你正在用心经营属于自己的故事",
        "编织你的世界，每一刻都独一无二"
    ]
    let motivationalPhrase: String
    let praisePhrase: String

    init() {
        self.motivationalPhrase = motivationalPhrases.randomElement()!
        self.praisePhrase = praisePhrases.randomElement()!
    }
}
