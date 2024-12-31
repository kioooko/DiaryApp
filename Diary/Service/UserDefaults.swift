//
//  UserDefaults.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/30.
//

enum UserDefaultsKey: String { // 定义一个枚举 UserDefaultsKey，遵循 String 类型
    case fontSize // 定义一个枚举值 fontSize，用于存储字体大小的键
    case lineSpacing // 定义一个枚举值 lineSpacing，用于存储行间距的键
    case hasBeenLaunchedBefore // 定义一个枚举值 hasBeenLaunchedBefore，用于存储应用是否已启动过的键
    case reSyncPerformed // 定义一个枚举值 reSyncPerformed，用于存储是否已执行重新同步的键
}