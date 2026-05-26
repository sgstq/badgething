import Foundation

enum BadgeStyle: String, Codable, CaseIterable {
    case dot
    case count

    var label: String {
        switch self {
        case .dot:   return "Dot"
        case .count: return "Count"
        }
    }
}

struct WatchedApp: Codable, Equatable, Identifiable {
    var id: String { bundleID }
    let bundleID: String
    var name: String
    var path: String
    var badgeStyle: BadgeStyle = .dot
}
