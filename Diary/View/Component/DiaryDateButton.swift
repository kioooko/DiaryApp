//
//  DiaryDateButton.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/08/22.
//

import SwiftUI

struct DiaryDateButton: View {

    @Binding var selectedDate: Date

    @State private var isPresentedDatePicker: Bool = false

    var body: some View {
          Button(actionWithHapticFB: {
              isPresentedDatePicker.toggle()
          }, label: {
              HStack(spacing: 4) {
                  HStack {
                      Image(systemName: "calendar")
                          .foregroundColor(.adaptiveBlack)
                      Text(selectedDate, style: .date)
                          .bold()
                          .foregroundColor(.adaptiveBlack)
                  }
                  .padding(.vertical, 12)

                  Text("的日记")
                      .foregroundColor(.adaptiveBlack)
              }
              .font(.system(size: 20))
          })
          .foregroundColor(.appBlack)
          .sheet(isPresented: $isPresentedDatePicker) {
              ZStack {
                  Color.Neumorphic.main
                      .edgesIgnoringSafeArea(.all)
                  DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                      .padding(.horizontal)
                      .datePickerStyle(GraphicalDatePickerStyle())
                      .presentationDetents([.medium])
              }
          }
          .onChange(of: selectedDate) {
              isPresentedDatePicker = false
          }
      }
}


#if DEBUG

struct DiaryDateButton_Previews: PreviewProvider {

    struct Demo: View {
        @State var selectedDate: Date = .now
        var body: some View {
            NavigationStack {
                VStack {
                    DiaryDateButton(selectedDate: $selectedDate)
                }
            }
        }
    }

    static var previews: some View {
        Group {
            Demo()
                .environment(\.colorScheme, .light)
            Demo()
                .environment(\.colorScheme, .dark)
        }
    }
}

#endif
