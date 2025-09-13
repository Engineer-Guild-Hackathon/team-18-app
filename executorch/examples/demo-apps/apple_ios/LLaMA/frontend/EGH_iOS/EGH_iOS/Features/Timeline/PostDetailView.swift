//
//  PostDetailView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  個別投稿の詳細画面

import SwiftUI

/// 一覧からタップ後にAI文章と投票を表示
struct PostDetailView: View {
    @EnvironmentObject var timelineVM: TimelineViewModel
    let post: Post
    @State private var showDiscussion = false

    var body: some View {
        ScrollView {
            PostHeader(author: post.author, createdAt: post.createdAt)
            Text(post.summary)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(20)

            if let ch = post.aiChallenge {
                AIChallengeCard(challenge: ch).padding(.horizontal, 20)
                HStack(spacing: 12) {
                    VoteButton(title: "✓ 正しい", isCorrect: true) { timelineVM.vote(post: post, isCorrect: true) }
                    VoteButton(title: "✗ 正しくない", isCorrect: false) { timelineVM.vote(post: post, isCorrect: false) }
                }
                .padding(.horizontal, 20)
            }

            Button {
                showDiscussion = true
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("議論を見る")
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            .buttonStyle(.plain)
            .navigationDestination(isPresented: $showDiscussion) {
                DiscussionView(post: post)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
