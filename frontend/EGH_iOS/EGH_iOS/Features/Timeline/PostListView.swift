//
//  PostListView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  投稿一覧のリスト表示

import SwiftUI

/// フォロー中/トレンドは一覧のみ（タップで詳細へ）
struct PostListView: View {
    let posts: [Post]

    var body: some View {
        List(posts) { post in
            NavigationLink {
                PostDetailView(post: post)
            } label: {
                PostCard(post: post)
            }
        }
        .listStyle(.plain)
    }
}
