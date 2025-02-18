import SwiftUI
import CoreData

struct SavingsGoalCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavingsGoal.startDate, ascending: true)],
        animation: .default)
    private var goals: FetchedResults<SavingsGoal>
    
    var body: some View {
        if let currentGoal = goals.first {
            VStack(spacing: 12) {
                HStack {
                    Text(currentGoal.title ?? "储蓄目标")
                        .font(.headline)
                    Spacer()
                    Text("¥\(Int(currentGoal.targetAmount))")
                        .font(.subheadline)
                }
                .background(Color.Neumorphic.main)
        
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: geometry.size.width * CGFloat(currentGoal.progress))
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(Int(currentGoal.progress * 100))%")
                        .font(.caption)
                    Spacer()
                    Text("还剩\(currentGoal.remainingDays)天")
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.Neumorphic.main)
            .cornerRadius(15)
            .softOuterShadow()
        }
    }
} 

private func calculateProgress(for goal: SavingsGoal) -> Double {
    var totalIncome: Double = 0
    var totalExpense: Double = 0
    
    debugPrint("Debug: 开始计算收支...")
    
    // 确保目标日期存在且有效
    guard let startDate = goal.startDate,
          let targetDate = goal.targetDate,
          targetDate > startDate else {
        debugPrint("Debug: 日期无效")
        return 0
    }
    
    // 计算在目标开始日期之后的收入和支出
    let calendar = Calendar.current
    let now = Date()
    
    for item in items {
        guard let itemDate = item.date else { continue }
        
        // 只计算开始日期到当前日期之间的收支
        if itemDate >= startDate && itemDate <= now {
            if item.amount > 0 {
                totalIncome += item.amount
            } else {
                totalExpense += abs(item.amount)
            }
        }
    }
    
    debugPrint("Debug: 总收入 - ¥\(totalIncome)")
    debugPrint("Debug: 总支出 - ¥\(totalExpense)")
    
    // 计算实际存储的金额（收入-支出）
    let actualSavings = totalIncome - totalExpense
    debugPrint("Debug: 实际存储 - ¥\(actualSavings)")
    debugPrint("Debug: 目标金额 - ¥\(goal.targetAmount)")
    
    // 计算时间进度
    let totalDays = max(1, calendar.dateComponents([.day], from: startDate, to: targetDate).day ?? 1)
    // 设置已过天数最小为1，确保第一天就有进度
    let passedDays = max(1, calendar.dateComponents([.day], from: startDate, to: now).day ?? 1)
    
    debugPrint("Debug: 总天数 - \(totalDays)")
    debugPrint("Debug: 已过天数 - \(passedDays)")
    
    // 计算进度：(收入-支出)/目标金额 × 已过去天数/总天数
    let savingsProgress = min(1.0, actualSavings / goal.targetAmount) // 限制最大为 100%
    let timeProgress = Double(passedDays) / Double(totalDays)
    let finalProgress = savingsProgress * timeProgress
    
    debugPrint("Debug: 存储进度 - \(savingsProgress * 100)%")
    debugPrint("Debug: 时间进度 - \(timeProgress * 100)%")
    debugPrint("Debug: 最终进度 - \(finalProgress * 100)%")
    
    // 确保进度在 0-1 之间
    return max(0, min(1, finalProgress))
}
