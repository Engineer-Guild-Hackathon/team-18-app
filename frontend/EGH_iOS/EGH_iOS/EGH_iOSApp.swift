//
//  EGH_iOSApp.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  アプリ起動時の初期設定とルートビュー管理


//
//import SwiftUI
//
//@main
//struct EGH_iOSApp: App {
//    init() {
//        // すべての UIScrollView で自動コンテンツインセット調整を無効化
//        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
//    }
//
//    @StateObject private var timelineVM = TimelineViewModel()
//    @StateObject private var postVM = PostViewModel()
//
//    var body: some Scene {
//        WindowGroup {
//            TimelineView()
//                .environmentObject(timelineVM)
//                .environmentObject(postVM)
//        }
//    }
//}


import SwiftUI

@main
struct EGH_iOSApp: App {
    init() {
        // ← これは “ズレない” を維持するため残します
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
    }

    @StateObject private var timelineVM = TimelineViewModel()
    @StateObject private var postVM = PostViewModel()

    var body: some Scene {
        WindowGroup {
            RootShell() // ← タブを最前面オーバーレイするシェル
                .environmentObject(timelineVM)
                .environmentObject(postVM)
        }
    }
}




/// アプリ下部のタブ
struct RootTabView: View {
    @EnvironmentObject var postVM: PostViewModel
    @EnvironmentObject var timelineVM: TimelineViewModel

    var body: some View {
        TabView {
            // ホームは内部で NavigationStack を持っている
            TimelineView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }

            // ★ 投稿タブは NavigationStack 配下にする（Push 遷移のため）
            NavigationStack {
                PostInputView()
            }
            .tabItem { Label("投稿", systemImage: "square.and.pencil") }

            ProfileView()
                .tabItem { Label("プロフィール", systemImage: "person.fill") }
        }
    }
}
