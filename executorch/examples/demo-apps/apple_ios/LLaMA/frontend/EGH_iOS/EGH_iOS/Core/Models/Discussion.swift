//
//  Discussion.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  議論コメントの構造定義

import Foundation

struct Discussion: Identifiable, Hashable, Codable {
    let id: UUID
    var serverID: String? = nil        // 将来のサーバ側ID

    let postID: UUID                   // ひも付く Post の id（サーバ移行時は serverID と併用可）
    let author: User
    let text: String
    let createdAt: Date
}
