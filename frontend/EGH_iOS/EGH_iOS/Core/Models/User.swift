//
//  User.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  ユーザー情報の構造定義

import Foundation

struct User: Identifiable, Hashable, Codable {
    let id: UUID                   // ローカル一意ID
    var serverID: String? = nil    // 将来のサーバ側ID（移行時に付与）

    var name: String
    var bio: String
    var streakDays: Int
    var totalPosts: Int
    var isFollowed: Bool = false

    // 将来: ＠ハンドルやアイコンURLを追加してもOK（Codableのまま拡張可）
    // var username: String?
    // var avatarURL: URL?
}
