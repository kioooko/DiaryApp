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
