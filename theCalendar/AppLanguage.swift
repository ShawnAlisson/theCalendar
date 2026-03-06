import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case persian

    var id: String { rawValue }

    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .system: return "language_system"
        case .english: return "language_english"
        case .persian: return "language_persian"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return Locale.autoupdatingCurrent
        case .english:
            return Locale(identifier: "en_US_POSIX")
        case .persian:
            return Locale(identifier: "fa_IR")
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .persian:
            return .rightToLeft
        case .system:
            let code = Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
            return code == "fa" ? .rightToLeft : .leftToRight
        case .english:
            return .leftToRight
        }
    }
}
