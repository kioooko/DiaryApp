//
//  WeatherDataStore.swift
//  Diary
//
//  Created by Higashihara Yoki on 2023/04/26.
// 

import Combine
import WeatherKit

/**
 The data provider that loads weather forecast data.
 */
@MainActor
public class WeatherData: ObservableObject {

    @Published public var phase: AsyncStatePhase = .initial
    @Published public var todayWeather: DayWeather?

    private let service = WeatherService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        // 初始化时不再请求位置服务
    }

    public func loadWeather(for symbolName: String) async {
        phase = .loading
        // 模拟从符号名称加载天气数据
        let simulatedWeather = DayWeather(date: Date(), symbolName: symbolName)
        await Task.sleep(1_000_000_000) // 模拟网络延迟
        self.todayWeather = simulatedWeather
        phase = .success(Date())
    }
}

public enum WeatherDataError: Error, LocalizedError {
    case notFoundTodayWeatherError

    public var errorDescription: String? {
        switch self {
        case .notFoundTodayWeatherError:
            return "无法获取今日天气"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notFoundTodayWeatherError:
            return "发生错误，请重试"
        }
    }
}
