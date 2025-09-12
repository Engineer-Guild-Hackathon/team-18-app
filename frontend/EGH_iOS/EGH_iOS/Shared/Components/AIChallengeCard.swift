//
//  AIChallengeCard.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  AI生成文章の表示カード

import SwiftUI

struct AIChallengeCard: View {
    let challenge: AIChallenge
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6).fill(
                    LinearGradient(colors: [.appBlue, .appBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 20, height: 20)
                Text("AIチャレンジ").font(.subheadline.weight(.semibold)).foregroundColor(.appBlue)
            }
            Text(challenge.text).font(.body)
            HStack(spacing: 16) {
                Label("\(challenge.correctVotes)", systemImage: "checkmark.circle")
                Label("\(challenge.incorrectVotes)", systemImage: "xmark.circle")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.appBlue.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBlue, lineWidth: 2))
        .cornerRadius(16)
    }
}
