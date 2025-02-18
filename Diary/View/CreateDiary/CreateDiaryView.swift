//
//  CreateDiaryView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/02.
//

import PhotosUI
import SwiftUI
import Neumorphic

struct CreateDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var weatherData: WeatherData
    @EnvironmentObject private var bannerState: BannerState
    @EnvironmentObject private var textOptions: TextOptions

    @StateObject private var diaryDataStore: DiaryDataStore = DiaryDataStore()

    @State private var isPresentedDatePicker: Bool = false
    @State private var isTextEditorPresented: Bool = false
    @State private var selectedContentType: DiaryContentType = .text

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = .appLanguageLocale
        return formatter
    }()
    private let dateRange: ClosedRange<Date> = Date(timeIntervalSince1970: 0)...Date()

    var body: some View {
        NavigationStack {
            ZStack {
                  Color.Neumorphic.main // 设置背景颜色为 Neumorphic 风格
                .edgesIgnoringSafeArea(.all) // 确保背景颜色覆盖整个视图

                VStack {
                    dismissButton
                        .padding(.top)
                    header
                        .padding(.top)
                    scrollContent
                }
            }
        }
        .tint(.adaptiveBlack)
        .onReceive(weatherData.$todayWeather , perform: { todayWeather in
            guard let todayWeather else { return }
            diaryDataStore.selectedWeather = .make(from: todayWeather.symbolName)
        })
        .sheet(isPresented: $isTextEditorPresented, content: {
            DiaryTextEditor(bodyText: $diaryDataStore.bodyText) {
                isTextEditorPresented = false
            }
        })
    }
}

private extension CreateDiaryView {

    // MARK: View

    var dismissButton: some View {
        HStack {
            Spacer()
            XButton {
            dismiss()
            }
            .padding(.trailing)
        }
    }

    var header: some View {
        HStack {
            DiaryDateButton(selectedDate: $diaryDataStore.selectedDate)
                .padding(.leading)
            Spacer()
            createButton
                .padding(.trailing, 32)
        }
    }

    var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                DiaryImageView(selectedImage: $diaryDataStore.selectedImage)
                .padding(.horizontal, diaryDataStore.selectedImage == nil ? 20 : 0)

                VStack(alignment: .leading, spacing: 20) {
                    // 画像以外に水平方向のpaddingを設定したいので別のStackで管理
                    HStack {
                        InputTitle(title: $diaryDataStore.title)
                     //   weather
                    }
                    ContentTypeSegmentedPicker(selectedContentType: $selectedContentType)
                    diaryContent
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    var weather: some View {
        WeatherSelectButton(selectedWeather: $diaryDataStore.selectedWeather)
            .asyncState(
                weatherData.phase,
                loadingContent:
                    ProgressView()
                        .frame(width: WeatherIcon.size.width, height: WeatherIcon.size.height)
           )
    }

    @ViewBuilder
    var diaryContent: some View {
        switch selectedContentType {
        case .text:
            DiaryText(text: diaryDataStore.bodyText) {
                withAnimation {
                    isTextEditorPresented = true
                }
            }
        case .checkList:
            VStack(spacing: 60) {
                CheckList(diaryDataStore: diaryDataStore)
                
                NavigationLink {
                    CheckListEditor()
                } label: {
                    Spacer()
                    CheckListEditButton()
                    Spacer()
                }
            }
        case .expense:
            ExpenseEditor()
        }
    }

    var createButton: some View {
        Button(actionWithHapticFB: {
            createItemFromInput()
        }) {
            Text("作成")
        }  
      //  .softButtonStyle(RoundedRectangle(isActive: diaryDataStore.canCreate , cornerRadius: 10))
        .buttonStyle(ActionButtonStyle(isActive: diaryDataStore.canCreate , size: .extraSmall))
        .disabled(!diaryDataStore.canCreate)
    }
    //.softInnerShadow(RoundedRectangle(cornerRadius: 20), spread: 0.6)
    // MARK: Action

    func createItemFromInput() {
        do {
            try diaryDataStore.create()
            bannerState.show(of: .success(message: "恭喜！你已成功添加新的日记。🎉"))
            dismiss()
        } catch {
            bannerState.show(with: error)
        }
    }
}

#if DEBUG

struct CreateDiaryView_Previews: PreviewProvider {

    static var content: some View {
        NavigationStack {
            CreateDiaryView()
        }
        .environmentObject(TextOptions.preview)
        .environmentObject(WeatherData())
    }

    static var previews: some View {
        Group {
            content
                .environment(\.colorScheme, .light)
            content
                .environment(\.colorScheme, .dark)
        }
    }
}

#endif
