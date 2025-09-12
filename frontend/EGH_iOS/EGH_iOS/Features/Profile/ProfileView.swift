//
//  ProfileView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  ユーザープロフィール画面
import SwiftUI

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 64, height: 64)
                    VStack(alignment: .leading) {
                        Text(vm.currentUser?.name ?? "ゲスト").font(.title3.bold())
                        Text(vm.currentUser?.bio ?? "").foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                if let stats = vm.userStats {
                    HStack {
                        StatItem(title: "正答率", value: "\(stats.accuracyRate)%")
                        StatItem(title: "議論数", value: "\(stats.discussionCount)")
                        StatItem(title: "いいね", value: "\(stats.likesReceived)")
                    }
                    .padding(.horizontal, 20)
                }

                // バッジ
                VStack(alignment: .leading, spacing: 8) {
                    Text("バッジ").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(vm.userBadges) { b in
                                VStack {
                                    Image(systemName: b.icon)
                                        .font(.title2)
                                        .foregroundColor(b.color)
                                        .frame(width: 48, height: 48)
                                        .background(b.color.opacity(0.15))
                                        .cornerRadius(12)
                                    Text(b.name).font(.caption)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
        .navigationTitle("プロフィール")
    }
}

private struct StatItem: View {
    var title: String; var value: String
    var body: some View {
        VStack {
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
    }
}
