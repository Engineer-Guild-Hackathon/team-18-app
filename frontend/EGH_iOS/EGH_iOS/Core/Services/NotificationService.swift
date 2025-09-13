//
//  NotificationService.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  プッシュ通知の設定と管理

import Foundation
// 実機でのローカル通知はUserNotificationsを使うが、ここではプレースホルダ
final class NotificationService {
    static let shared = NotificationService()
    private init() {}
    func scheduleRandomWindow(startHour: Int = 18, endHour: Int = 21) {
        // TODO: UNUserNotificationCenter でローカル通知設定
    }
}
