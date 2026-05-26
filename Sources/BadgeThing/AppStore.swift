import Foundation

final class AppStore {
    private(set) var apps: [WatchedApp] {
        didSet {
            save()
            onChange?()
        }
    }
    var onChange: (() -> Void)?

    private let defaultsKey = "watchedApps"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([WatchedApp].self, from: data) {
            self.apps = decoded
        } else {
            self.apps = []
        }
    }

    func add(_ app: WatchedApp) {
        guard !apps.contains(where: { $0.bundleID == app.bundleID }) else { return }
        apps.append(app)
    }

    func remove(bundleID: String) {
        apps.removeAll { $0.bundleID == bundleID }
    }

    func update(_ app: WatchedApp) {
        guard let idx = apps.firstIndex(where: { $0.bundleID == app.bundleID }) else { return }
        apps[idx] = app
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(apps) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
