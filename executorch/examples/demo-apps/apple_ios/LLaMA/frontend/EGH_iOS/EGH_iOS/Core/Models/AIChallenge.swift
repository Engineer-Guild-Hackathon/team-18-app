//
//  AIChallenge.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  AI生成文章と正誤情報の構造定義

import Foundation

struct AIChallenge: Identifiable, Hashable, Codable {
    let id: UUID
    var serverID: String? = nil        // 将来のサーバ側ID

    var text: String                   // 正誤不明のAI文章
    var correctVotes: Int
    var incorrectVotes: Int
}
