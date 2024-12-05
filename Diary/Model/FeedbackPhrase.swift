//
//  FeedbackPhrase.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/07/03.
//

import Foundation

final class FeedbackPhrase {

    private let motivationalPhrases: [String] = [
        "将每天的点滴化作文字吧",
        "让文字化作针线，编织你的日常，这是一段属于你自己的故事",
        "日记是与自己的对话",
        "回顾过去，为未来铺路",
        "你的每一天都是宝贵的",
        "记录今天，为明天迈出一步",
        "感受的一切，都值得珍惜",
        "编织日记为你的生活增添色彩"
    ]
    private let praisePhrases: [String] = [
        "记录了你成长的每一天",
        "回顾一天，是美好的习惯",
        "你的文字为每一天增添了色彩",
        "今天，你的故事又向前迈进了一步",
        "太棒了！让我们为你的每一天喝彩",
        "编织你的每一天，你真了不起"
    ]
    let motivationalPhrase: String
    let praisePhrase: String

    init() {
        self.motivationalPhrase = motivationalPhrases.randomElement()!
        self.praisePhrase = praisePhrases.randomElement()!
    }
}
