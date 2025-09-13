//
//  RelatedPostView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  関連投稿の詳細表示

import SwiftUI

/// 「関連」タブは1画面1投稿でAI文章と投票をデフォルト表示
/// ※ ナビゲーションは親が管理するため、ここでは onOpenDiscussion をコールするだけ
struct RelatedPostView: View {
    @EnvironmentObject var timelineVM: TimelineViewModel
    let post: Post
    var onOpenDiscussion: (Post) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // ヘッダー
            PostHeader(author: post.author, createdAt: post.createdAt)
                .padding(.top, 8)

            // ユーザー要約
            Text(post.summary)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 20)

            // AIチャレンジ & 投票
            if let ch = post.aiChallenge {
                AIChallengeCard(challenge: ch)
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    VoteButton(title: "✓ 正しい", isCorrect: true) {
                        timelineVM.vote(post: post, isCorrect: true)
                    }
                    VoteButton(title: "✗ 正しくない", isCorrect: false) {
                        timelineVM.vote(post: post, isCorrect: false)
                    }
                }
                .padding(.horizontal, 20)
            }

            // 議論を見る（→ 親に通知して Push）
            Button {
                onOpenDiscussion(post)
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

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        // ★ デバッグ用：外側ボックスの境界線を可視化
        .overlay(
            VStack {
                Rectangle()
                    .fill(Color.red.opacity(0.3))
                    .frame(height: 2)
                Spacer()
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 2)
            }
        )
    }
}
