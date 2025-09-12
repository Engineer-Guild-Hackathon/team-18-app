//
//  TimelineFilterView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  関連/フォロー/トレンドのタブ切り替え
  
import SwiftUI

struct TimelineFilterView: View {
    @Binding var selected: TimelineFilter

    var body: some View {
        HStack(spacing: 12) {
            // 左右に Spacer を入れてボタン群を中央へ
            Spacer(minLength: 0)

            pill(title: "関連", isActive: selected == .related) {
                selected = .related
            }

            pill(title: "フォロー中・トレンド", isActive: selected == .social) {
                selected = .social
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)                 // コンテナいっぱい
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func pill(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isActive ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color.blue : Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize() // 文字幅にフィットさせ、中央寄せを安定
    }
}
