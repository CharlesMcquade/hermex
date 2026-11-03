import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum AppIconChoice: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let lightAlternateIconName = "AppIconLight"
    static let darkAlternateIconName = "AppIconDark"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            String(localized: "System")
        case .light:
            String(localized: "Light")
        case .dark:
            String(localized: "Dark")
        }
    }

    var subtitle: String {
        switch self {
        case .system:
            String(localized: "Matches device appearance")
        case .light:
            String(localized: "Always use the light icon")
        case .dark:
            String(localized: "Always use the dark icon")
        }
    }

    var alternateIconName: String? {
        switch self {
        case .system:
            nil
        case .light:
            Self.lightAlternateIconName
        case .dark:
            Self.darkAlternateIconName
        }
    }

    var previewImageName: String? {
        switch self {
        case .system:
            nil
        case .light:
            "AppIconLightPreview"
        case .dark:
            "AppIconDarkPreview"
        }
    }

    static func resolved(from alternateIconName: String?) -> AppIconChoice {
        switch alternateIconName {
        case Self.lightAlternateIconName:
            .light
        case Self.darkAlternateIconName:
            .dark
        default:
            .system
        }
    }

    #if canImport(UIKit)
    @MainActor
    static var current: AppIconChoice {
        resolved(from: UIApplication.shared.alternateIconName)
    }
    #endif
}
