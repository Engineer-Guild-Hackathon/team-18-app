//
//  Date+Extensions.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  日付フォーマット処理
 
import Foundation

extension Date {
    var relativeString: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: self, relativeTo: Date())
    }
}

