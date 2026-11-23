import Foundation

enum Localization {
    /// The package language the user's preferences select ("en" or "fr"); English when none matches.
    static var current: String { Bundle.module.preferredLocalizations.first ?? "en" }

    /// `key` in `language` (the user's when nil): tests pin a language, the app passes none.
    static func string(_ key: String.LocalizationValue, _ language: String? = nil) -> String {
        let bundle = language.flatMap { Bundle.module.path(forResource: $0, ofType: "lproj") }.flatMap(Bundle.init(path:)) ?? .module
        return String(localized: key, bundle: bundle)
    }
}
