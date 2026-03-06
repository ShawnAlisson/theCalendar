//
//  Date.swift
//  Portefeuille
//
//  Created by Shayan Alizadeh on 1/14/22.
//

import Foundation

extension Date {
    // Static cached formatters to avoid repeated allocation and to be thread-safe enough for UI usage.
    private static let persianCalendar = Calendar(identifier: .persian)
    private static let gregorianCalendar = Calendar(identifier: .gregorian)
    private static let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)

    private static let faIR = Locale(identifier: "fa_IR")
    private static let enUSPOSIX = Locale(identifier: "en_US_POSIX")
    private static let arSA = Locale(identifier: "ar_SA")

    private static let dayFormatterPersianCached: DateFormatter = {
        let f = DateFormatter()
        f.calendar = persianCalendar
        f.locale = faIR
        f.dateFormat = "EEEE"
        return f
    }()

    private static let dateFormatterPersianCached: DateFormatter = {
        let f = DateFormatter()
        f.calendar = persianCalendar
        f.locale = faIR
        f.dateFormat = "d" // No leading zero for Persian numerals
        return f
    }()

    private static let monthFormatterPersianCached: DateFormatter = {
        let f = DateFormatter()
        f.calendar = persianCalendar
        f.locale = faIR
        f.dateFormat = "MMMM"
        return f
    }()

    private static let monthFormatterEngCached: DateFormatter = {
        let f = DateFormatter()
        f.calendar = gregorianCalendar
        f.locale = enUSPOSIX
        f.dateFormat = "d MMMM"
        return f
    }()

    private static let shortFormatterPersianCached: DateFormatter = {
        let f = DateFormatter()
        f.calendar = persianCalendar
        f.locale = faIR
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let shortFormatterEngCached: DateFormatter = {
        let f = DateFormatter()
        f.calendar = gregorianCalendar
        f.locale = enUSPOSIX
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let shortFormatterArCached: DateFormatter = {
        let f = DateFormatter()
        f.calendar = islamicCalendar
        f.locale = arSA
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    func asPersianDay() -> String {
        Self.dayFormatterPersianCached.string(from: self)
    }

    func asPersianMonth() -> String {
        Self.monthFormatterPersianCached.string(from: self)
    }

    func asPersianDate() -> String {
        Self.dateFormatterPersianCached.string(from: self)
    }

    func asEngMonth() -> String {
        Self.monthFormatterEngCached.string(from: self)
    }

    func asShortDateString() -> String {
        Self.shortFormatterPersianCached.string(from: self)
    }

    func asShortDateStringEng() -> String {
        Self.shortFormatterEngCached.string(from: self)
    }

    func asShortDateStringAr() -> String {
        Self.shortFormatterArCached.string(from: self)
    }
}
