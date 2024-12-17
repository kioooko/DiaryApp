import SwiftUI
import WeatherKit
import Neumorphic

struct WeatherSelectButton: View {
    @Binding var selectedWeather: WeatherSymbol
    @State private var isPresentedSelectView: Bool = false

    var body: some View {
        Button(actionWithHapticFB: {
            isPresentedSelectView = true
        }) {
            WeatherIcon(weatherSymbolName: selectedWeather.symbol)
                .background(
                    Circle()
                        .fill(Color.Neumorphic.main)
                        .softOuterShadow()
                )
        }
        .foregroundColor(.adaptiveBlack)
        .sheet(isPresented: $isPresentedSelectView) {
            NavigationStack {
                WeatherSelect(selectedWeather: $selectedWeather)
                    .padding(.horizontal)
            }
            .presentationDetents([.height(340)])
        }
    }
}

struct WeatherSelect: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedWeather: WeatherSymbol

    private static let itemWidth: CGFloat = 70
    private let columns: [GridItem] = Array(
        repeating: .init(
            .fixed(itemWidth),
            spacing: 40,
            alignment: .top
        ),
        count: 3
    )

    private let weatherSymbols: [WeatherSymbol] = [.sun, .cloud, .rain, .snow, .wind]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                    ForEach(weatherSymbols, id: \.symbol) { weatherSymbol in
                        Button(actionWithHapticFB: {
                            selectedWeather = weatherSymbol
                            dismiss()
                        }) {
                            weatherItem(
                                imageName: weatherSymbol.symbol,
                                title: weatherSymbol.name
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.Neumorphic.main)
                                .softOuterShadow()
                        )
                    }
                }
            }
            .padding(.top, 20)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("选择天气")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension WeatherSelect {
    func weatherItem(imageName: String, title: String) -> some View {
        VStack(alignment: .center, spacing: 16) {
            WeatherIcon(weatherSymbolName: imageName)
            Text(title)
        }
        .foregroundColor(.adaptiveBlack)
    }
}

struct WeatherIcon: View {
    public static var size: CGSize = .init(width: 50, height: 50)
    let weatherSymbolName: String

    var body: some View {
        Image(systemName: weatherSymbolName)
            .font(.system(size: 24))
            .frame(width: WeatherIcon.size.width, height: WeatherIcon.size.height)
    }
}

#if DEBUG

struct WeatherPicker_Previews: PreviewProvider {
    static var content: some View {
        NavigationStack {
            WeatherSelectButton(selectedWeather: .constant(.sun))
        }
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

