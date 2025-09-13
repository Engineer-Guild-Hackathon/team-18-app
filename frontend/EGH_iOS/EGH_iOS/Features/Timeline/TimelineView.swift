//
//  TimelineView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  タイムラインのメイン画面

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject var timelineVM: TimelineViewModel
    // Lazyの外でナビゲーション管理（議論表示）
    @State private var discussionPost: Post?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                NavigationBar(title: "みんなの学び")
                // 上部メニュー：2タブ
                TimelineFilterView(selected: $timelineVM.selectedFilter)

                // 残り領域を各ビューに割当
                switch timelineVM.selectedFilter {
                case .related:
                    RelatedTimelinePager(onOpenDiscussion: { post in
                        discussionPost = post
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .social:
                    VStack(spacing: 8) {
                        // セグメントで「フォロー中 / トレンド」を切替
                        Picker("", selection: $timelineVM.selectedSocial) {
                            Text("フォロー中").tag(SocialFeed.following)
                            Text("トレンド").tag(SocialFeed.trending)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // 一覧はこれまで通り（スクロールリスト）
                        switch timelineVM.selectedSocial {
                        case .following:
                            PostListView(posts: timelineVM.following)
                        case .trending:
                            PostListView(posts: timelineVM.trending)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(item: $discussionPost) { post in
                DiscussionView(post: post)
            }
        }
    }
}
