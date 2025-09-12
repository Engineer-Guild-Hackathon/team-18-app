//
//  PostInputView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  200文字まとめ入力画面

import SwiftUI

struct PostInputView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var postVM: PostViewModel
    @EnvironmentObject var timelineVM: TimelineViewModel

    // 投稿後に Push するためのフラグと、遷移先に渡すチャレンジを退避
    @State private var goJudge = false
    @State private var navChallenge: AIChallenge?

    var body: some View {
        VStack {
            NavigationBar(title: "今日の学び")

            VStack(spacing: 12) {
                // ★ タイマー表示はやめる（startTimer も呼ばない）

                Text("今日学んだことをまとめてください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 入力欄
                TextEditor(text: $postVM.text)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    )
                    .padding(.bottom, 4)

                HStack {
                    Spacer()
                    Text("\(postVM.text.count) / 200")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 投稿ボタン
                Button {
                    // 200文字にクリップ
                    let clipped = String(postVM.text.prefix(200))
                    postVM.text = clipped

                    // 投稿 & AIの正誤不明文を生成（submit 内で justPostedChallenge を設定）
                    let newPost = postVM.submit(currentUser: auth.currentUser)

                    // タイムライン（関連）に先頭追加
                    timelineVM.related.insert(newPost, at: 0)

                    // 遷移用にチャレンジを退避して Push
                    navChallenge = postVM.justPostedChallenge
                    goJudge = true
                } label: {
                    Text("投稿する")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .tint(.appBlue)
                .disabled(postVM.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)

            Spacer()
        }
        // ★ NavigationStack 配下なので navigationDestination が使える
        .navigationDestination(isPresented: $goJudge) {
            Group {
                if let ch = navChallenge {
                    AIJudgementView(challenge: ch)
                } else {
                    // 万一データが無い場合のフォールバック
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("読み込み中…").foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

