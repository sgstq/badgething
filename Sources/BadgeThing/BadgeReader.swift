import Cocoa
import ApplicationServices

enum BadgeReader {
    /// Map of Dock-tile display name → badge text. Tiles without a badge are omitted.
    static func readAll() -> [String: String] {
        guard let dock = NSRunningApplication
                .runningApplications(withBundleIdentifier: "com.apple.dock").first else {
            return [:]
        }
        let dockApp = AXUIElementCreateApplication(dock.processIdentifier)

        var topRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(dockApp,
                                            kAXChildrenAttribute as CFString,
                                            &topRef) == .success,
              let topChildren = topRef as? [AXUIElement] else {
            return [:]
        }

        var result: [String: String] = [:]
        for listEl in topChildren {
            var tilesRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(listEl,
                                                kAXChildrenAttribute as CFString,
                                                &tilesRef) == .success,
                  let tiles = tilesRef as? [AXUIElement] else { continue }

            for tile in tiles {
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(tile,
                                              kAXTitleAttribute as CFString,
                                              &titleRef)
                guard let title = titleRef as? String else { continue }

                var badgeRef: CFTypeRef?
                AXUIElementCopyAttributeValue(tile,
                                              "AXStatusLabel" as CFString,
                                              &badgeRef)
                if let badge = badgeRef as? String, !badge.isEmpty {
                    result[title] = badge
                }
            }
        }
        return result
    }

    @discardableResult
    static func requestPermission(prompt: Bool = true) -> Bool {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }
}
