import SwiftUI

enum Brand {
    static let name = "CherrySunny"
    static let group = "group.app.portionnote.food"
    static let route = "portionnote"
    static let widget = "app.portionnote.food.summary"
    static let section = "Today’s portions"
    static let hint = "Log a portion on iPhone."
    static let blurb = "Your daily nutrition totals and latest portions."
    static let symbol = "fork.knife"
    #if os(iOS)
    static let accent = Color(red: 0.686, green: 0.949, blue: 0.796)
    static let ground = Color(red: 0.158, green: 0.123, blue: 0.242)
    #else
    static let accent = Color(red: 1.0000, green: 0.6863, blue: 0.4706)
    static let ground = Color(red: 0.1490, green: 0.1725, blue: 0.1294)
    #endif
    static let preview = CompanionSnapshot(title: "Daybook · Today", value: "384 kcal", detail: "18 g protein · 42 g carbs · 16 g fat", items: [], updated: .now)
}
