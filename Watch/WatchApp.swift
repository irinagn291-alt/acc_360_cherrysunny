import SwiftUI

@main
struct WatchApplication: App {
    @StateObject private var hub = CompanionHub.shared
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 5) {
                            Label(hub.snapshot.title, systemImage: Brand.symbol).font(.caption2.bold()).foregroundStyle(Brand.accent)
                            Text(hub.snapshot.value).font(.title3.weight(.semibold))
                            Text(hub.snapshot.detail).font(.caption2)
                        }.padding(.vertical, 4)
                    }
                    if !hub.snapshot.items.isEmpty {
                        Section(Brand.section) {
                            ForEach(hub.snapshot.items) { item in
                                NavigationLink {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 10) {
                                            Image(systemName: Brand.symbol).foregroundStyle(Brand.accent)
                                            Text(item.title).font(.headline)
                                            Text(item.detail).font(.body)
                                        }.frame(maxWidth: .infinity, alignment: .leading)
                                    }.navigationTitle(Brand.section)
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(item.title).font(.headline)
                                        Text(item.detail).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                    Section {
                        if hub.snapshot.updated > Date.distantPast {
                            Text("Updated " + hub.snapshot.updated.formatted(.dateTime.month(.abbreviated).day().hour().minute().locale(Locale(identifier: "en_US"))))
                        } else { Text("Open " + Brand.name + " on your paired iPhone to sync.") }
                        Button { hub.refresh() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                        if let status = hub.syncStatus { Text(status).accessibilityLabel(status) }
                    }.font(.caption2).foregroundStyle(.secondary)
                }.navigationTitle(Brand.name)
            }.environment(\.locale, Locale(identifier: "en_US"))
        }
    }
}
