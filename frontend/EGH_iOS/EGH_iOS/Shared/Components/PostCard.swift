//
//  PostCard.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  投稿カードの表示コンポーネント

import SwiftUI

struct PostCard: View {
    let post: Post
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle().fill(Color.gray.opacity(0.2)).frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.name).font(.subheadline.bold())
                    Text(post.createdAt.relativeString).font(.caption).foregroundColor(.secondary)
                }
            }
            Text(post.summary)
                .font(.body)
                .lineLimit(3)
            HStack(spacing: 16) {
                Label("\(post.likeCount)", systemImage: "hand.thumbsup")
                Label("\(post.commentCount)", systemImage: "bubble.right")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}
