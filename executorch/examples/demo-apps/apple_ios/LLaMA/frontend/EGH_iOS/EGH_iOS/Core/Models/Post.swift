//
//  Post.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  投稿データの構造定義

import Foundation

/// 投稿（1日の学び）
struct Post: Identifiable, Hashable, Equatable, Codable {
    // 基本メタ
    let id: UUID                         // アプリ内ユニークID（ローカル）
    var serverID: String?                // ← 将来用：サーバー側ID（移行時に付与）
    let author: User
    var summary: String                  // 200文字以内の学び要約
    var createdAt: Date

    // 集計
    var likeCount: Int
    var commentCount: Int                // サーバー集計 or ローカル推定

    // AI 生成テキスト（正誤不明）
    var aiChallenge: AIChallenge?

    // --- 議論（コメント） ---
    /// 表示用に保持するコメント（ページングの最初のチャンクを想定）
    var discussions: [Discussion] = []

    /// サーバーが教えてくれる総コメント数（ページング UI に使える）
    var discussionTotalCount: Int?

    /// 次ページ取得のためのカーソル（opaque なトークン）
    var discussionNextCursor: String?

    /// すでに最初のページをロードしたか（初回フェッチの判定に使う）
    var isDiscussionsLoaded: Bool = false

    // MARK: - Equatable / Hashable
    static func == (lhs: Post, rhs: Post) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - 将来のAPI移行を見据えたヘルパ
    /// サーバーから受け取ったコメントページを適用
    mutating func appendDiscussionPage(items: [Discussion],
                                       nextCursor: String?,
                                       totalCount: Int?) {
        // 既にあるものと重複しないようにユニークマージ
        let existingIDs = Set(discussions.map { $0.id })
        let newOnes = items.filter { !existingIDs.contains($0.id) }
        discussions.append(contentsOf: newOnes)

        discussionNextCursor = nextCursor
        discussionTotalCount = totalCount ?? discussionTotalCount
        isDiscussionsLoaded = true

        // commentCount をサーバー値で上書きできる場合はそちらを優先
        if let total = totalCount { commentCount = total }
    }

    /// コメントをリフレッシュ（先頭から）
    mutating func replaceDiscussions(items: [Discussion],
                                     nextCursor: String?,
                                     totalCount: Int?) {
        discussions = items
        discussionNextCursor = nextCursor
        discussionTotalCount = totalCount
        isDiscussionsLoaded = true
        if let total = totalCount { commentCount = total }
    }
}

// MARK: - モック生成（開発時のみ使用）
extension Post {
    /// 手早くポストを作るモック用ファクトリ
    static func mock(
        author: User,
        summary: String,
        minutesAgo: Int,
        likes: Int = 0,
        comments: Int = 0,
        challenge: AIChallenge? = nil,
        discussions: [Discussion] = []
    ) -> Post {
        Post(
            id: UUID(),
            serverID: nil,
            author: author,
            summary: summary,
            createdAt: Date().addingTimeInterval(TimeInterval(-60 * minutesAgo)),
            likeCount: likes,
            commentCount: max(comments, discussions.count),
            aiChallenge: challenge,
            discussions: discussions,
            discussionTotalCount: max(comments, discussions.count),
            discussionNextCursor: nil,
            isDiscussionsLoaded: !discussions.isEmpty
        )
    }
}

