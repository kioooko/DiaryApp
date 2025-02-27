import SwiftUI
import CoreData
import Neumorphic
import UniformTypeIdentifiers
import UIKit // 确保你已经导入了 UIKit

struct DataDownloadView: View {
    @EnvironmentObject private var bannerState: BannerState
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedFormat: FileFormat = .csv
    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var downloadedFileContent: String? = nil // 用于存储读取的文件内容
    @State private var showFileContent: Bool = false // 控制是否显示文件内容
    @State private var downloadError: Error? = nil // 用于存储下载错误

    enum FileFormat: String, CaseIterable, Identifiable {
        case csv = "csv"
        case txt = "txt"
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .csv: return "CSV 格式 (表格)"
            case .txt: return "TXT 格式 (文本)"
            }
        }
    }

    var body: some View {
        ScrollView {
             VStack(spacing: 10) {
               Spacer()
               .padding(30)
                     }
            NoticeText
            ImportData

            DownloadText
            SelectButton
            saveButton
   
        }
        .navigationTitle("管理日记数据")
        .padding(30)
        .background(Color.Neumorphic.main) // 设置 DataDownloadView 的背景颜色
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .sheet(isPresented: $isExporting) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        if let downloadedFileContent = downloadedFileContent {
            Text("文件内容：")
            Text(downloadedFileContent)
                .padding()
        }

        if let downloadError = downloadError {
            Text("下载错误: \(downloadError.localizedDescription)")
                .foregroundColor(.red)
        }
    }
    
    var  NoticeText: some View {
        VStack(spacing: 30) {
            Text("导入日记仅支持过去导出的历史日记数据，格式为txt或者csv格式。")
            .padding()
            .foregroundColor(.gray)
            .font(.system(size: 14))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

var ImportData: some View { // 导入数据
    NavigationLink {
        DataImportView()
    } label: {
        Text("导入")
            .fontWeight(.bold)
            .padding(.init(top: 30, leading: 120, bottom: 30, trailing: 120)) // 增加一些内边距，让按钮更好看
            .background(Color.white) // 设置背景色
            .cornerRadius(12) // 轻微圆角
            .overlay( // 添加虚线边框
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5])) // 2px宽度，虚线间隔 5
                    .foregroundColor(.gray) // 虚线颜色
            )
    }
}


     var  DownloadText: some View {
        VStack(spacing: 10) {
            Text("您可以选择导出历史数据为txt或者csv格式。")
                .foregroundColor(.gray)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding()
       
        }
    }

      var SelectButton: some View {
        VStack (spacing: 10) {
            Picker("选择格式", selection: $selectedFormat) {
                ForEach(FileFormat.allCases) { format in
                    Text(format.description).tag(format)
                }
            }
        }
     .padding(.bottom, 30)
    }

  var saveButton: some View {
Button(action: {  downloadData(format: selectedFormat)
            bannerState.show(of: .success(message: "导出成功🎉"))}) {
    Text("下载").fontWeight(.bold)
}
.softButtonStyle(RoundedRectangle(cornerRadius: 12))
  .padding(.horizontal)
  
    }

 
    private func downloadData(format: FileFormat) {
        // 1. 从 CoreData 获取所有数据
        let diaryObjects = CoreDataProvider.shared.exportAllDiaryEntries()
        let savingsObjects = CoreDataProvider.shared.fetchAllSavingsGoals()
        
        // 将 NSManagedObject 转换为具体类型
        let diaryEntries = diaryObjects.compactMap { $0 as? Item }
        let savingsGoals = savingsObjects.compactMap { $0 as? SavingsGoal }
        
        // 添加安全检查
        guard !diaryEntries.isEmpty else {
            print("警告: 没有找到日记条目")
            // 显示错误提示
            showAlert(title: "导出失败", message: "没有找到可导出的数据")
            return
        }
        
        // 2. 将数据转换为指定格式的字符串
        do {
            let fileContent = try convertToFileContent(entries: diaryEntries, goals: savingsGoals, format: format)
            
            // 3. 保存文件到本地
            saveFile(content: fileContent, format: format)
        } catch {
            print("数据转换错误: \(error)")
            showAlert(title: "导出失败", message: "数据转换过程中发生错误: \(error.localizedDescription)")
        }
        // 在保存文件后读取文件内容
        DispatchQueue.main.async { // 在主线程上更新UI
            if let fileURL = exportURL {
                readFileContent(fileURL: fileURL)
            }
        }
    }

    private func readFileContent(fileURL: URL) {
        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                self.downloadedFileContent = content
                self.showFileContent = true
                self.downloadError = nil
            } catch {
                self.downloadError = error
                self.downloadedFileContent = nil
                self.showFileContent = false
            }
        } else {
            self.downloadError = NSError(domain: "FileAccessError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法访问文件: 权限被拒绝"])
            self.downloadedFileContent = nil
            self.showFileContent = false
        }
    }

    private func convertToFileContent(entries: [Item], goals: [SavingsGoal], format: FileFormat) throws -> String {
        switch format {
        case .csv:
            return try convertToCSV(entries: entries)
        case .txt:
            return try convertToTXT(entries: entries, goals: goals)
        }
    }

    private func convertToCSV(entries: [Item]) throws -> String {
        var csvString = "日期,标题,内容,是否收藏,金额,是否支出,备注\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        for entry in entries {
            let dateString = entry.date != nil ? dateFormatter.string(from: entry.date!) : ""
            let title = entry.title?.replacingOccurrences(of: ",", with: " ") ?? ""
            let body = entry.body?.replacingOccurrences(of: ",", with: " ") ?? ""
            let isBookmarked = entry.isBookmarked ? "是" : "否"
            let amount = String(format: "%.2f", entry.amount)
            let isExpense = entry.isExpense ? "支出" : "收入"
            let note = entry.note?.replacingOccurrences(of: ",", with: " ") ?? ""
            
            let line = "\(dateString),\"\(title)\",\"\(body)\",\(isBookmarked),\(amount),\(isExpense),\"\(note)\"\n"
            csvString.append(line)
        }
        
        // 检查 CSV 字符串
        guard !csvString.isEmpty else {
            throw NSError(domain: "DataDownloadView", code: 3, userInfo: [NSLocalizedDescriptionKey: "生成的 CSV 数据为空"])
        }
        
        return csvString
    }

    private func convertToTXT(entries: [Item], goals: [SavingsGoal]) throws -> String {
        var txtString = "===== 我的日记导出 =====\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        
        // 添加日记条目
        txtString.append("【日记条目】\n\n")
        
        for entry in entries {
            if let date = entry.date {
                txtString.append("日期: \(dateFormatter.string(from: date))\n")
            }
            
            if let title = entry.title, !title.isEmpty {
                txtString.append("标题: \(title)\n")
            }
            
            if let body = entry.body, !body.isEmpty {
                txtString.append("内容: \(body)\n")
            }
            
            txtString.append("金额: \(String(format: "%.2f", entry.amount))\n")
            txtString.append("类型: \(entry.isExpense ? "支出" : "收入")\n")
            
            if let note = entry.note, !note.isEmpty {
                txtString.append("备注: \(note)\n")
            }
            
            txtString.append("收藏: \(entry.isBookmarked ? "是" : "否")\n")
            txtString.append("\n-------------------\n\n")
        }
        
        // 添加储蓄目标
        if !goals.isEmpty {
            txtString.append("【储蓄目标】\n\n")
            
            for goal in goals {
                if let title = goal.title {
                    txtString.append("名称: \(title)\n")
                }
                
                txtString.append("目标金额: \(String(format: "%.2f", goal.targetAmount))\n")
                txtString.append("当前金额: \(String(format: "%.2f", goal.currentAmount))\n")
                
                if let startDate = goal.startDate {
                    txtString.append("开始日期: \(dateFormatter.string(from: startDate))\n")
                }
                
                if let targetDate = goal.targetDate {
                    txtString.append("目标日期: \(dateFormatter.string(from: targetDate))\n")
                }
                
                let progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) * 100 : 0
                txtString.append("进度: \(String(format: "%.1f%%", progress))\n")
                txtString.append("\n-------------------\n\n")
            }
        }
        
        // 添加导出信息
        let currentDateString = dateFormatter.string(from: Date())
        txtString.append("导出时间: \(currentDateString)\n")
        txtString.append("条目总数: \(entries.count)\n")
        txtString.append("目标总数: \(goals.count)\n")
        
        return txtString
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    private func saveFile(content: String, format: FileFormat) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            showAlert(title: "保存失败", message: "无法访问文档目录")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "diary_export_\(dateString).\(format.rawValue)"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            showAlert(title: "导出成功", message: "文件已保存到: \(fileURL.path)")
            
            // 保存导出的 URL 并显示分享表单
            exportURL = fileURL
            isExporting = true
        } catch {
            showAlert(title: "保存失败", message: "无法保存文件: \(error.localizedDescription)")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DataDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DataDownloadView()
        }
    }
}
