//
//  Date.swift
//  Portefeuille
//
//  Created by Shayan Alizadeh on 1/14/22.
//

import Foundation

extension Date {
    
    private var dayFormatterPersian: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.calendar = Calendar(identifier: .persian)
        formatter.locale = Locale(identifier: "fa_IR")
        return formatter
    }
    
    private var dateFormatterPersian: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        formatter.calendar = Calendar(identifier: .persian)
        formatter.locale = Locale(identifier: "fa_IR")
        return formatter
    }
    
    private var monthFormatterPersian: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.calendar = Calendar(identifier: .persian)
        formatter.locale = Locale(identifier: "fa_IR")
        return formatter
    }
    
    private var monthFormatterEng: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }
    
    private var shortFormatterPersian: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = Calendar(identifier: .persian)
        formatter.locale = Locale(identifier: "fa_IR")
        return formatter
    }
    
    private var shortFormatterEng: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "fa_IR")
        return formatter
    }
    
    private var shortFormatterAr: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = Calendar(identifier: .islamic)
        formatter.locale = Locale(identifier: "fa_IR")
        return formatter
    }
    
    func asPersianDay() -> String {
        return dayFormatterPersian.string(from: self)
    }
    
    func asPersianMonth() -> String {
        return monthFormatterPersian.string(from: self)
    }
    
    func asPersianDate() -> String {
        return dateFormatterPersian.string(from: self)
    }
    
    func asEngMonth() -> String {
        return monthFormatterEng.string(from: self)
    }
    
    func asShortDateString() -> String {
        return shortFormatterPersian.string(from: self)
    }
    
    func asShortDateStringEng() -> String {
        return shortFormatterEng.string(from: self)
    }
    
    func asShortDateStringAr() -> String {
        return shortFormatterAr.string(from: self)
    }
    
}
