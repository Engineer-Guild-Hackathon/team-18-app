//
//  RootShell.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/11.
//


import SwiftUI

enum RootTab: Hashable { case home, post, profile }

struct RootShell: View {
    @State private var tab: RootTab = .home

    var body: some View {
        ZStack {
            // ===== コンテンツ層（Pager など）。Safe Area を尊重、ページ枠は今まで通り =====
            Group {
                switch tab {
                case .home:
                    TimelineView() // 既存の TimelineView（内部に NavigationStack があるならそのまま）
                case .post:
                    PostInputView() // 既存の投稿画面
                case .profile:
                    ProfileView()   // 既存のプロフィール
                }
            }
            .zIndex(0)

            // ===== タブバー層：常に最前面。コンテンツとは独立 =====
            VStack {
                Spacer()
                TabBarView(
                    selected: Binding(
                        get: { tab },
                        set: { tab = $0 }
                    )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: -2)
                .zIndex(10) // ← 最前面
                .allowsHitTesting(true)
                .ignoresSafeArea(.container, edges: .bottom) // ← HomeIndicator 領域まで覆う
            }
        }
    }
}
