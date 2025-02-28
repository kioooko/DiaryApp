//
//  CreateDiaryView.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/05/02.
//

import PhotosUI
import SwiftUI
import Neumorphic
import Combine

struct CreateDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var weatherData: WeatherData
    @EnvironmentObject private var bannerState: BannerState
    @EnvironmentObject private var textOptions: TextOptions

    @StateObject private var diaryDataStore: DiaryDataStore = DiaryDataStore()
    @StateObject private var keyboardManager = KeyboardManager()

    @State private var isPresentedDatePicker: Bool = false
    @State private var isTextEditorPresented: Bool = false
    @State private var selectedContentType: DiaryContentType = .text
    @FocusState private var focusedField: FocusField?

    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = .appLanguageLocale
        return formatter
    }()
    private let dateRange: ClosedRange<Date> = Date(timeIntervalSince1970: 0)...Date()

    enum FocusField {
        case title
        case body
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.Neumorphic.main
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    dismissButton
                        .padding(.top)
                    header
                        .padding(.top)
                    scrollContent
                }
                .padding(.bottom, keyboardManager.isVisible ? keyboardManager.keyboardHeight : 0)
            }
        }
        .tint(.adaptiveBlack)
        .onReceive(weatherData.$todayWeather) { todayWeather in
            guard let todayWeather else { return }
            diaryDataStore.selectedWeather = .make(from: todayWeather.symbolName)
        }
        .sheet(isPresented: $isTextEditorPresented) {
            OptimizedDiaryTextEditor(bodyText: $diaryDataStore.bodyText) {
                isTextEditorPresented = false
            }
        }
        .animation(.easeOut(duration: 0.16), value: keyboardManager.keyboardHeight)
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                      to: nil,
                                      from: nil,
                                      for: nil)
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
                    HStack {
                        OptimizedInputTitle(title: $diaryDataStore.title)
                    }
                    ContentTypeSegmentedPicker(selectedContentType: $selectedContentType)
                    diaryContent
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
            }
        }
        .optimizedKeyboardHandling()
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
            .focused($focusedField, equals: .body)
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
