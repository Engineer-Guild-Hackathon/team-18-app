//
//  DiscussionView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  ユーザー間の議論スレッド画面


//import SwiftUI
//
//struct DiscussionView: View {
//    let post: Post
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//
//                // --- ナビゲーションバーに潜り込まないための上側余白 ---
//                // （iOS16でも効くようにシンプルに固定値で確保）
//                Color.clear.frame(height: 12)
//
//                // --- ユーザー情報 ---
//                PostHeader(author: post.author, createdAt: post.createdAt)
//                    .padding(.horizontal, 16)
//
//                // --- ユーザーのまとめ ---
//                Text(post.summary)
//                    .font(.body)
//                    .foregroundColor(.primary)
//                    .padding(16)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(12)
//                    .padding(.horizontal, 16)
//
//                // --- AIチャレンジ（元の文脈） ---
//                if let ch = post.aiChallenge {
//                    VStack(alignment: .leading, spacing: 12) {
//                        HStack(spacing: 8) {
//                            RoundedRectangle(cornerRadius: 6)
//                                .fill(Color.blue)
//                                .frame(width: 20, height: 20)
//                            Text("AIチャレンジ")
//                                .font(.subheadline.bold())
//                                .foregroundColor(.blue)
//                        }
//
//                        Text(ch.text)
//                            .font(.body)
//                            .foregroundColor(.primary)
//                            .fixedSize(horizontal: false, vertical: true)
//
//                        HStack(spacing: 16) {
//                            Label("\(ch.correctVotes)", systemImage: "checkmark.circle")
//                            Label("\(ch.incorrectVotes)", systemImage: "xmark.circle")
//                        }
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    }
//                    .padding(16)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .background(
//                        RoundedRectangle(cornerRadius: 16)
//                            .stroke(Color.blue, lineWidth: 2)
//                            .background(
//                                RoundedRectangle(cornerRadius: 16)
//                                    .fill(Color.blue.opacity(0.06))
//                            )
//                    )
//                    .padding(.horizontal, 16)
//                }
//
//                // --- 区切り線 ---
//                Divider().padding(.horizontal, 16)
//
//                // --- 議論スレッド ---
//                VStack(spacing: 0) {
//                    ForEach(post.discussions) { d in
//                        DiscussionRow(discussion: d)
//                        Divider().padding(.leading, 16)
//                    }
//                }
//                .padding(.top, 4)
//            }
//            .padding(.bottom, 24) // 下に少し余白
//        }
//        .navigationTitle("議論")
//        .navigationBarTitleDisplayMode(.inline)
//        .background(Color(.systemBackground))
//    }
//}



import SwiftUI

struct DiscussionView: View {
    let post: Post

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // ユーザー情報
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.author.name)
                            .font(.headline)
                        Text(post.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // ユーザーのまとめ（summary）
                Text(post.summary)
                    .font(.body)
                    .padding(.vertical, 8)

                // AI チャレンジ
                if let challenge = post.aiChallenge {
                    AIChallengeCard(challenge: challenge)
                }

                Divider()

                // 議論コメント
                VStack(spacing: 0) {
                    ForEach(post.discussions) { d in
                        DiscussionRow(discussion: d)
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16) // ← 適切な余白（SafeArea対応なら GeometryReader 併用も可）
        }
        .navigationTitle("議論")
        .navigationBarTitleDisplayMode(.inline)
    }
}



// MARK: - 行アイテム

private struct DiscussionRow: View {
    let discussion: Discussion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(discussion.author.name)
                        .font(.subheadline).bold()
                    Text(discussion.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(discussion.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
