//
//  PostViewModel.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  投稿機能のビジネスロジックと状態管理

import Foundation
import Combine

final class PostViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var remainingSec: Int = 5 * 60        // 5分
    @Published var justPostedChallenge: AIChallenge? // 投稿直後に評価する用

    private var timer: AnyCancellable?

    func startTimer() {
        timer?.cancel()
        remainingSec = 5 * 60
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.remainingSec > 0 { self.remainingSec -= 1 }
            }
    }

    func stopTimer() { timer?.cancel() }

    func submit(currentUser: User) -> Post {
        stopTimer()

        let post = Post(
            id: UUID(),
            author: currentUser,
            summary: text.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            likeCount: Int.random(in: 0...50),
            commentCount: Int.random(in: 0...10),
            aiChallenge: nil
        )

        // 擬似的に LLM から正誤不明文を生成
        let challengeText = LLMService.shared.generateUncertainStatement(from: post.summary)
        let challenge = AIChallenge(id: UUID(), text: challengeText, correctVotes: 0, incorrectVotes: 0)
        justPostedChallenge = challenge

        return Post(
            id: post.id,
            author: post.author,
            summary: post.summary,
            createdAt: post.createdAt,
            likeCount: post.likeCount,
            commentCount: post.commentCount,
            aiChallenge: challenge
        )
    }
}
