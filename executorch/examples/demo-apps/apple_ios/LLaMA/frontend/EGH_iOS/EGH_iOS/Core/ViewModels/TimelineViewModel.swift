//
//  TimelineViewModel.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  タイムライン表示ロジックとデータ取得(一旦モックデータ後でBEと連携)

import Foundation

// 上部タブは2つだけ
enum TimelineFilter: CaseIterable { case related, social }

// 「フォロー中・トレンド」内のサブ切替
enum SocialFeed: String, CaseIterable, Identifiable {
    case following, trending
    var id: String { rawValue }
}

final class TimelineViewModel: ObservableObject {
    @Published var related: [Post] = []
    @Published var following: [Post] = []
    @Published var trending: [Post] = []

    // 上部メニュー：関連 or フォロー中・トレンド
    @Published var selectedFilter: TimelineFilter = .related
    // サブ切替（フォロー中 or トレンド）
    @Published var selectedSocial: SocialFeed = .following

    init() { loadMock() }

    // 投票（関連タイムラインのみ反映する簡易版）
    func vote(post: Post, isCorrect: Bool) {
        guard let idx = related.firstIndex(of: post), var ch = related[idx].aiChallenge else { return }
        if isCorrect { ch.correctVotes += 1 } else { ch.incorrectVotes += 1 }
        related[idx].aiChallenge = ch
        objectWillChange.send()
    }

    private func loadMock() {
        // ユーザー
        let u1 = User(id: UUID(), name: "田中太郎", bio: "数学好き", streakDays: 10, totalPosts: 30, isFollowed: true)
        let u2 = User(id: UUID(), name: "佐藤花子", bio: "機械学習勉強中", streakDays: 22, totalPosts: 58, isFollowed: true)
        let u3 = User(id: UUID(), name: "鈴木一郎", bio: "DB設計得意", streakDays: 5, totalPosts: 12)
        let u4 = User(id: UUID(), name: "山田次郎", bio: "Python沼", streakDays: 17, totalPosts: 41, isFollowed: true)
        let u5 = User(id: UUID(), name: "高橋健太", bio: "Webエンジニア", streakDays: 7, totalPosts: 19)
        let u6 = User(id: UUID(), name: "伊藤さくら", bio: "NLP専攻", streakDays: 33, totalPosts: 75)

        // 便利関数
        func makeAI(_ text: String) -> AIChallenge {
            AIChallenge(id: UUID(),
                        text: text,
                        correctVotes: Int.random(in: 0...30),
                        incorrectVotes: Int.random(in: 0...30))
        }

        func makePost(_ author: User, _ summary: String, minutesAgo: Int, ai: String?) -> Post {
            Post(id: UUID(),
                 author: author,
                 summary: summary,
                 createdAt: Date().addingTimeInterval(TimeInterval(-60 * minutesAgo)),
                 likeCount: Int.random(in: 0...80),
                 commentCount: Int.random(in: 0...20),
                 aiChallenge: ai.map { makeAI($0) })
        }

        // 関連（1画面=1投稿で表示される想定。すべてAIチャレンジ付き）
        related = [
            makePost(u2, "交差検証の目的と手順を整理。汎化性能の評価に使える。", minutesAgo: 2,
                     ai: "k-分割交差検証は1回だけ実行すれば十分です。"),
            makePost(u1, "行列の固有値・固有ベクトルを学習。対角化の直感が掴めた。", minutesAgo: 5,
                     ai: "固有値は常に実数になるため複素数は現れません。"),
            makePost(u3, "SQLのJOIN句（INNER/LEFT/RIGHT）の違いを復習。", minutesAgo: 9,
                     ai: "LEFT JOIN と RIGHT JOIN は常に同じ結果になります。"),
            makePost(u4, "Pythonのデコレータでログ付け・キャッシュの実装練習。", minutesAgo: 12,
                     ai: "デコレータはメソッドにしか使えず、関数には適用できません。"),
            makePost(u5, "Dockerで開発環境を整備。compose の基本も確認。", minutesAgo: 15,
                     ai: "Docker コンテナは仮想マシンと同じ仕組みで動作します。"),
            makePost(u6, "Transformer の自己注意の数式を読み直した。", minutesAgo: 18,
                     ai: "自己注意はクエリとキーを足し算するだけで計算されます。"),
            makePost(u2, "クロスエントロピー損失の意味を図で理解。", minutesAgo: 22,
                     ai: "クロスエントロピーは二値分類にしか使えません。"),
            makePost(u1, "確率分布と期待値の基本を復習。", minutesAgo: 26,
                     ai: "期待値は常に観測値の中央値と等しくなります。"),
            makePost(u4, "正規表現の先読み・後読みの違いを整理。", minutesAgo: 30,
                     ai: "先読みは必ず文字を消費するため、一致部分は短くなります。"),
            makePost(u3, "インデックス設計とクエリ最適化の基礎。", minutesAgo: 35,
                     ai: "複合インデックスは作成順序に関係なく同一の効果があります。"),
        ]

        // フォロー（まとめのみの一覧）
        following = [
            makePost(u2, "活性化関数の使い分け（ReLU/Swish/GELU）を調査。", minutesAgo: 40, ai: nil),
            makePost(u4, "イテレータ／ジェネレータの違いをコードで確認。", minutesAgo: 44, ai: nil),
            makePost(u1, "極限と微分の関係（導関数の定義）を復習。", minutesAgo: 47, ai: nil),
            makePost(u5, "アクセシビリティ対応（iOS の Dynamic Type）を試した。", minutesAgo: 51, ai: nil),
            makePost(u6, "形態素解析器の仕組みと辞書のカスタム。", minutesAgo: 55, ai: nil)
        ]

        // トレンド（まとめのみの一覧）
        trending = [
            makePost(u5, "TypeScript のユニオン／インターセクション型の実例。", minutesAgo: 60, ai: nil),
            makePost(u3, "正則化（L1/L2）とモデルのバイアス・バリアンス。", minutesAgo: 66, ai: nil),
            makePost(u6, "BPE と SentencePiece の違いを比較。", minutesAgo: 72, ai: nil),
            makePost(u2, "Early Stopping の実運用上の注意点を調べた。", minutesAgo: 80, ai: nil),
            makePost(u4, "async/await と並列実行（TaskGroup）の基本。", minutesAgo: 90, ai: nil)
        ]
    }
}
