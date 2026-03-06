//
//  theCalendarApp.swift
//  theCalendar
//
//  Created by Shayan Alizadeh on 11/8/22.
//

import SwiftUI

@main
struct theCalendarApp: App {
    @AppStorage("app_language") private var appLanguageRawValue = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(appLanguageRawValue)
                .environment(\.locale, appLanguage.locale)
                .frame(minWidth: 800, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
        }

        Settings {
            SettingsView()
        }
    }
}
