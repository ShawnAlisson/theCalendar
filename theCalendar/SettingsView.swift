import SwiftUI

struct SettingsView: View {
    @AppStorage("app_language") private var appLanguageRawValue = AppLanguage.system.rawValue

    var body: some View {
        Form {
            Section("settings_general_section") {
                Picker("settings_language_label", selection: $appLanguageRawValue) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.localizedTitleKey).tag(language.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
