import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appStore = AppStore()
    private var controllers: [StatusItemController] = []
    private var emptyController: StatusItemController?
    private var emptyStatusItem: NSStatusItem?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = BadgeReader.requestPermission(prompt: true)

        appStore.onChange = { [weak self] in
            DispatchQueue.main.async { self?.rebuild() }
        }

        rebuild()
        startTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshBadges()
        }
    }

    private func rebuild() {
        for c in controllers { c.dispose() }
        controllers.removeAll()
        if let empty = emptyStatusItem {
            NSStatusBar.system.removeStatusItem(empty)
            emptyStatusItem = nil
        }

        if appStore.apps.isEmpty {
            installEmptyPlaceholder()
        } else {
            controllers = appStore.apps.map { app in
                StatusItemController(
                    app: app,
                    onUpdate: { [weak self] u in self?.appStore.update(u) },
                    onRemove: { [weak self] u in self?.appStore.remove(bundleID: u.bundleID) },
                    onAddApp: { [weak self] in self?.addAppFlow() }
                )
            }
            refreshBadges()
        }
    }

    private func installEmptyPlaceholder() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.title = "+ Badge"
            button.toolTip = "Click to add an app"
            button.target = self
            button.action = #selector(addAppFlow)
        }
        let menu = NSMenu()
        let add = NSMenuItem(title: "Add app…", action: #selector(addAppFlow), keyEquivalent: "n")
        add.target = self
        menu.addItem(add)

        let launch = NSMenuItem(title: "Launch at login",
                                action: #selector(toggleLaunchAtLogin),
                                keyEquivalent: "")
        launch.target = self
        launch.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launch)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit BadgeThing", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        emptyStatusItem = item
    }

    private func refreshBadges() {
        let badges = BadgeReader.readAll()
        for controller in controllers {
            controller.applyBadge(badges[controller.app.name])
        }
    }

    @objc private func addAppFlow() {
        let panel = NSOpenPanel()
        panel.title = "Add app to watch"
        panel.message = "Pick a Mac app whose unread badge you want in the menu bar."
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        NSApp.activate(ignoringOtherApps: true)
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            guard let bundle = Bundle(url: url),
                  let bundleID = bundle.bundleIdentifier else { return }

            let name: String = {
                if let n = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String { return n }
                if let n = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String { return n }
                return url.deletingPathExtension().lastPathComponent
            }()

            let app = WatchedApp(bundleID: bundleID,
                                 name: name,
                                 path: url.path,
                                 badgeStyle: .dot)
            self?.appStore.add(app)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
    }
}
