//
//  ProfileViewModel.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//

import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var userPosts: [Post] = []
    @Published var userStats: UserStats?
    @Published var accuracyStats: AccuracyStats?
    @Published var userBadges: [Badge] = []
    
    init() {
        loadUserData()
    }
    
    func loadUserData() {
        // モックデータ
        currentUser = User(
            id: UUID(),
            name: "田中太郎",
            bio: "毎日少しずつ学習を続けています",
            streakDays: 15,
            totalPosts: 42
        )
        
        userStats = UserStats(
            accuracyRate: 78,
            discussionCount: 35,
            likesReceived: 156
        )
        
        loadUserPosts()
        loadBadges()
    }
    
    private func loadUserPosts() {
        // TODO: API実装
    }
    
    private func loadBadges() {
        userBadges = [
            Badge(id: UUID(), name: "初投稿", icon: "star.fill", color: .yellow),
            Badge(id: UUID(), name: "7日継続", icon: "flame.fill", color: .orange),
            Badge(id: UUID(), name: "議論マスター", icon: "bubble.left.and.bubble.right.fill", color: .blue)
        ]
    }
}

struct UserStats {
    let accuracyRate: Int
    let discussionCount: Int
    let likesReceived: Int
}

struct AccuracyStats {
    let totalVotes: Int
    let correctVotes: Int
    let incorrectVotes: Int
}

struct Badge: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
}
