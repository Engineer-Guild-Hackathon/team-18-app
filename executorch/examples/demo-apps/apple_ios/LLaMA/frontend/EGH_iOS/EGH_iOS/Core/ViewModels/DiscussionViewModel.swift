//
//  DiscussionViewModel.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  議論データの取得と投稿管理

import Foundation

final class DiscussionViewModel: ObservableObject {
    @Published var discussions: [Discussion] = []

    func loadMock(for post: Post) {
        let u1 = User(id: UUID(), name: "山田太郎", bio: "", streakDays: 0, totalPosts: 0)
        let u2 = User(id: UUID(), name: "鈴木美咲", bio: "", streakDays: 0, totalPosts: 0)
        let u3 = User(id: UUID(), name: "高橋健太", bio: "", streakDays: 0, totalPosts: 0)
        discussions = [
            Discussion(id: UUID(), postID: post.id, author: u1, text: "k回繰り返して平均化するのが一般的です。", createdAt: Date().addingTimeInterval(-180)),
            Discussion(id: UUID(), postID: post.id, author: u2, text: "「1回だけ実行」は誤りですね。", createdAt: Date().addingTimeInterval(-300)),
            Discussion(id: UUID(), postID: post.id, author: u3, text: "Leave-One-Out も参考になります。", createdAt: Date().addingTimeInterval(-600)),
        ]
    }
}
