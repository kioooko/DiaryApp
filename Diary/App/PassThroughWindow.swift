//
//  PassThroughWindow.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/08.
//

import UIKit // 导入 UIKit 框架，用于构建用户界面

/**
- 当用户交互触及该窗口中显示的某个内容时，处理用户交互
- 否则，将交互传递给其他窗口

与 RootVC 的视图相同 → 直接传递 = 事件透过 = 返回 nil
不同 → 在该视图捕获事件 = 返回 hitView
 */
class PassThroughWindow: UIWindow { // 定义一个名为 PassThroughWindow 的类，继承自 UIWindow

    /*
    从被点击的视图层次结构的最深位置（根视图）开始，递归调用以找到接收事件的视图。
     */
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { // 重写 hitTest 方法，用于确定哪个视图应该接收触摸事件
        guard let hitView = super.hitTest(point, with: event) else { return nil } // 调用父类的 hitTest 方法，获取被点击的视图，如果没有视图被点击，返回 nil
        let isRootView = rootViewController?.view == hitView // 检查被点击的视图是否是根视图控制器的视图
        return isRootView ? nil : hitView // 如果被点击的是根视图，返回 nil（事件透过），否则返回被点击的视图
    }
}