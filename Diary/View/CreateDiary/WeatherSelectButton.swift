import SwiftUI
import WeatherKit

struct WeatherSelectButton: View {
    @Binding var selectedWeather: WeatherSymbol
    @State private var isPresentedSelectView: Bool = false
    @State private var isLocationPermissionAlertPresented: Bool = false

    var body: some View {
        Button(actionWithHapticFB: {
            isPresentedSelectView = true
        }) {
            WeatherIcon(weatherSymbolName: selectedWeather.symbol)
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

struct WeatherIcon: View {
    public static var size: CGSize = .init(width: 50, height: 50)
    let weatherSymbolName: String

    var body: some View {
        Image(systemName: weatherSymbolName)
            .font(.system(size: 24))
            .frame(width: WeatherIcon.size.width, height: WeatherIcon.size.height)
    }
}

struct WeatherSelect: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var weatherData: WeatherData

    @Binding var selectedWeather: WeatherSymbol

    @State private var isLocationPermissionTextPresented: Bool = false
    @State private var weatherAttribution: WeatherAttribution?
    private let weatherService = WeatherService()

    private static let itemWidth: CGFloat = 70
    private let columns: [GridItem] = Array(
        repeating: .init(
            .fixed(itemWidth),
            spacing: 40,
            alignment: .top
        ),
        count: 3
    )

    private let weatherSymbols: [WeatherSymbol] = [ .sun, .cloud, .rain, .snow, .wind]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLocationPermissionTextPresented {
                    Button(actionWithHapticFB: {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }) {
                        Text("要获取当前位置，请点击此处并通过设置应用允许访问位置服务。")
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 12))
                    }
                }

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
                    }

                    dataFromCurrentLocationButton
                }

                if let weatherAttribution {
                    appleWeatherAttribution(weatherAttribution)
                }
            }
            .padding(.top, 20)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("天气")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            weatherAttribution = try? await weatherService.attribution
        }
    }
}

private extension WeatherSelect {

    var dataFromCurrentLocationButton: some View {
        Button(actionWithHapticFB: {
            defer {
                dismiss()
            }
            if weatherData.hasTodayWeather {
                selectedWeather = .make(from: weatherData.todayWeather!.symbolName)
            } else {
                do {
                    try  weatherData.load()
                } catch WeatherDataError.noLocationAuth {
                    isLocationPermissionTextPresented = true
                } catch {
                    print(error.localizedDescription)
                }
            }
        }) {
            weatherItem(
                imageName: "arrow.2.squarepath",
                title: "获取当前位置"
            )
        }
    }

    func weatherItem(imageName: String, title: String) -> some View {
        VStack(alignment: .center, spacing: 16) {
            WeatherIcon(weatherSymbolName: imageName)
            Text(title)
        }
        .foregroundColor(.adaptiveBlack)
    }

    func appleWeatherAttribution(_ weatherAttribution: WeatherAttribution) -> some View {
        HStack {
            AsyncImage( url: weatherAttribution.combinedMarkLightURL) { image in
                image
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(height: 12)
                    .foregroundStyle(Color.adaptiveBlack)
            } placeholder: {
                ProgressView()
            }
            Button("Link") {
                UIApplication.shared.open(weatherAttribution.legalPageURL)
            }
            .tint(.blue)
        }
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

