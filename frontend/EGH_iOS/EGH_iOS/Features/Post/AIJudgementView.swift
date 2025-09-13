//
//  AIJudgementView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  AI文章の正誤判定画面

import SwiftUI

/// 投稿直後に最初のユーザーへ正誤を問う画面
struct AIJudgementView: View {
    let challenge: AIChallenge
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            NavigationBar(title: "AIチャレンジ")
            VStack(alignment: .leading, spacing: 12) {
                Label("AIが生成した文章", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                Text(challenge.text)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                VoteButton(title: "✓ 正しい", isCorrect: true) { dismiss() }
                VoteButton(title: "✗ 正しくない", isCorrect: false) { dismiss() }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
