//
//  AuthService.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  ユーザー認証とセッション管理

import Foundation

final class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var currentUser: User

    private init() {
        currentUser = User(id: UUID(), name: "田中太郎", bio: "毎日学習中", streakDays: 15, totalPosts: 42)
    }
}
