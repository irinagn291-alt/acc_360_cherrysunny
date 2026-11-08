import SwiftUI

@main
struct FoodApplication: App {
    @StateObject private var launch = AppLaunch()

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG && targetEnvironment(simulator)
                if ScreenshotLaunch.screen != nil {
                    FeatureRoot()
                        .transaction { $0.animation = nil; $0.disablesAnimations = true }
                } else {
                    normalRoot
                }
                #else
                normalRoot
                #endif
            }
            .environment(\.locale, Locale(identifier: "en_US"))
        }
    }

    private var normalRoot: some View {
        Group {
            switch launch.mode {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .webContent:
                if let url = launch.contentURL { InAppBrowser(url: url) }
                else { FeatureRoot() }
            case .nativeInterface:
                FeatureRoot()
            }
        }
        .task { launch.start() }
    }
}

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotLaunch {
    enum Screen: String, CaseIterable {
        case day = "day-journal", week = "week-review", catalog = "food-catalog"
        case scanner = "barcode-scanner", editor = "portion-editor"
    }

    static let screen: Screen? = {
        let process = ProcessInfo.processInfo
        let args = process.arguments
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        if let key = value(after: "-ReviewScreen") { return Screen(rawValue: key) }
        let environmentFlag = process.environment["APPSTORE_SCREENSHOTS"]?.lowercased() ?? ""
        let enabled = args.contains("-AppStoreScreenshots") ||
            !["", "0", "false", "no"].contains(environmentFlag)
        guard enabled else { return nil }
        let rawIndex = value(after: "-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"]
        guard let rawIndex, let index = Int(rawIndex), (1...Screen.allCases.count).contains(index) else { return nil }
        return Screen.allCases[index - 1]
    }()

    static var starter: [OFFProduct] {
        guard let url = Bundle.main.url(forResource: "StarterCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? FoodCatalog.parse(data, barcode: false)) ?? []
    }

    static func product(_ code: String) -> OFFProduct? { starter.first { $0.id == code } }

    static var previousMonday: Date {
        let monday = Daybook.week(containing: .now).first ?? Daybook.calendar.startOfDay(for: .now)
        return Daybook.calendar.date(byAdding: .day, value: -7, to: monday) ?? monday
    }

    static func entries(for screen: Screen) -> [Portion] {
        guard let weetabix = product("5010029000016"), let spaghetti = product("8076800195057"),
              let muesli = product("5010029226133") else { return [] }
        let today = Daybook.calendar.startOfDay(for: .now)
        if screen == .week {
            let samples: [(Int, OFFProduct, Double, MealSlot)] = [
                (0, weetabix, 50, .breakfast), (1, spaghetti, 150, .lunch),
                (2, muesli, 100, .snack), (3, spaghetti, 200, .dinner),
                (5, weetabix, 75, .breakfast), (6, muesli, 125, .snack)
            ]
            return samples.compactMap { sample in
                guard let date = Daybook.calendar.date(byAdding: .day, value: sample.0, to: previousMonday) else { return nil }
                return Portion(product: sample.1, amount: sample.2, meal: sample.3, date: date)
            }
        }
        return [Portion(product: weetabix, amount: 50, meal: .breakfast, date: today),
                Portion(product: spaghetti, amount: 150, meal: .lunch, date: today),
                Portion(product: muesli, amount: 100, meal: .snack, date: today)]
    }
}

#endif
