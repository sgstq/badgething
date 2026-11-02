import Cocoa

final class StatusItemController: NSObject {
    private(set) var app: WatchedApp
    let item: NSStatusItem

    private let onUpdate: (WatchedApp) -> Void
    private let onRemove: (WatchedApp) -> Void
    private let onAddApp: () -> Void

    init(app: WatchedApp,
         onUpdate: @escaping (WatchedApp) -> Void,
         onRemove: @escaping (WatchedApp) -> Void,
         onAddApp: @escaping () -> Void) {
        self.app = app
        self.onUpdate = onUpdate
        self.onRemove = onRemove
        self.onAddApp = onAddApp
        self.item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureButton()
        applyBadge(nil)
    }

    func dispose() {
        NSStatusBar.system.removeStatusItem(item)
    }

    private func configureButton() {
        guard let button = item.button else { return }
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.image = appIcon()
        button.imagePosition = .imageLeft
        button.toolTip = app.name
    }

    private func appIcon() -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: app.path)
        icon.size = NSSize(width: 18, height: 18)
        return icon
    }

    func applyBadge(_ badge: String?) {
        guard let button = item.button else { return }
        let hasBadge = (badge?.isEmpty == false)
        button.alphaValue = hasBadge ? 1.0 : 0.45

        switch app.badgeStyle {
        case .count:
            button.title = hasBadge ? " \(badge!)" : ""
        case .dot:
            button.title = hasBadge ? " •" : ""
        }
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isRightClick = event?.type == .rightMouseUp
            || (event?.modifierFlags.contains(.control) ?? false)
        if isRightClick {
            showMenu()
        } else {
            activateApp()
        }
    }

    // Open via LaunchServices like a Dock click: a running app gets a reopen
    // event, so apps whose windows were closed (Slack's red ×) show one again.
    // NSRunningApplication.activate only fronts the app, and since macOS 14
    // the system may refuse it from a non-active menu bar app.
    private func activateApp() {
        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(toApplicationWithBundleIdentifier: app.bundleID)
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: app.path),
            configuration: config,
            completionHandler: nil)
    }

    private func showMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: app.name, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let open = NSMenuItem(title: "Open \(app.name)",
                              action: #selector(menuActivate),
                              keyEquivalent: "")
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let styleHeader = NSMenuItem(title: "Badge style",
                                     action: nil,
                                     keyEquivalent: "")
        let styleSub = NSMenu()
        for s in BadgeStyle.allCases {
            let mi = NSMenuItem(title: s.label,
                                action: #selector(menuSetStyle(_:)),
                                keyEquivalent: "")
            mi.target = self
            mi.representedObject = s.rawValue
            mi.state = (app.badgeStyle == s) ? .on : .off
            styleSub.addItem(mi)
        }
        styleHeader.submenu = styleSub
        menu.addItem(styleHeader)

        menu.addItem(.separator())

        let remove = NSMenuItem(title: "Remove from menu bar",
                                action: #selector(menuRemove),
                                keyEquivalent: "")
        remove.target = self
        menu.addItem(remove)

        menu.addItem(.separator())

        let add = NSMenuItem(title: "Add app…",
                             action: #selector(menuAddApp),
                             keyEquivalent: "n")
        add.target = self
        menu.addItem(add)

        let launch = NSMenuItem(title: "Launch at login",
                                action: #selector(menuToggleLaunchAtLogin),
                                keyEquivalent: "")
        launch.target = self
        launch.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launch)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit BadgeThing",
                              action: #selector(menuQuit),
                              keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc private func menuActivate() { activateApp() }
    @objc private func menuRemove() { onRemove(app) }
    @objc private func menuAddApp() { onAddApp() }
    @objc private func menuQuit() { NSApp.terminate(nil) }
    @objc private func menuToggleLaunchAtLogin() {
        LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
    }

    @objc private func menuSetStyle(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = BadgeStyle(rawValue: raw) else { return }
        var updated = app
        updated.badgeStyle = style
        app = updated
        onUpdate(updated)
    }
}
