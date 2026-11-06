import SwiftUI
import WatchConnectivity
#if os(iOS)
import WidgetKit
#endif

@MainActor
final class CompanionHub: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = CompanionHub()
    @Published private(set) var snapshot = CompanionSnapshot.read()
    #if os(watchOS)
    @Published private(set) var syncStatus: String?
    #endif
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    #if os(iOS)
    func publish(title: String, value: String, detail: String, items: [CompanionItem]) {
        // WatchConnectivity application contexts have a finite payload budget.
        let items = items.prefix(24).map {
            CompanionItem(id: $0.id, title: String($0.title.prefix(120)), detail: String($0.detail.prefix(180)))
        }
        let value = String(value.prefix(160))
        let now = Date()
        guard snapshot.title != title || snapshot.value != value || snapshot.detail != detail ||
                snapshot.items != items || !Calendar.current.isDate(snapshot.updated, inSameDayAs: now) else { return }
        let next = CompanionSnapshot(title: title, value: value, detail: detail, items: items, updated: now)
        guard let data = try? JSONEncoder().encode(next) else { return }
        CompanionSnapshot.defaults.set(data, forKey: CompanionSnapshot.key)
        snapshot = next
        WidgetCenter.shared.reloadTimelines(ofKind: Brand.widget)
        transmit()
    }

    private func transmit() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled,
              let data = CompanionSnapshot.defaults.data(forKey: CompanionSnapshot.key) else { return }
        try? session.updateApplicationContext([CompanionSnapshot.key: data])
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        let stored = CompanionSnapshot.defaults.data(forKey: CompanionSnapshot.key)
        replyHandler(stored ?? Data())
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) { Task { @MainActor in transmit() } }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #else
    func refresh() {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated, WCSession.default.isReachable else {
            syncStatus = "Waiting for the paired iPhone."
            return
        }
        syncStatus = "Checking iPhone…"
        WCSession.default.sendMessageData(Data([1]), replyHandler: { [weak self] data in
            Task { @MainActor in
                self?.receive(data)
                self?.syncStatus = data.isEmpty ? "Open the app on iPhone to start." : "Up to date"
            }
        }, errorHandler: { [weak self] _ in
            Task { @MainActor in self?.syncStatus = "iPhone unavailable. Try again later." }
        })
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable { Task { @MainActor in refresh() } }
    }

    private func receive(_ data: Data?) {
        guard let data, let next = try? JSONDecoder().decode(CompanionSnapshot.self, from: data),
              next.updated >= snapshot.updated else { return }
        CompanionSnapshot.defaults.set(data, forKey: CompanionSnapshot.key)
        snapshot = next
        syncStatus = nil
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext[CompanionSnapshot.key] as? Data
        Task { @MainActor in receive(data) }
    }
    #endif

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        #if os(iOS)
        Task { @MainActor in transmit() }
        #else
        let data = session.receivedApplicationContext[CompanionSnapshot.key] as? Data
        Task { @MainActor in
            receive(data)
            if WCSession.default.isReachable { refresh() }
        }
        #endif
    }
}
