//
//  NotificationViewModel.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  通知タイミング制御と状態管理

import Foundation

final class NotificationViewModel: ObservableObject {
    @Published var nextWindowText: String = "18:00〜21:00 のどこかで通知します"
    func scheduleDailyWindow() {
        // 実装は NotificationService へ。本VMでは文言だけ管理（モック）
        nextWindowText = "きょう 18:00〜21:00 のどこかで通知します"
    }
}
