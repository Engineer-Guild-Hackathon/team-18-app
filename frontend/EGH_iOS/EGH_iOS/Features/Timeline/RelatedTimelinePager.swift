//
//  RelatedTimelinePager.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  縦スクロールのページング

//import SwiftUI
//
///// 「関連」タブを 1画面=1投稿 で縦ページング表示するビュー
//struct RelatedTimelinePager: View {
//    @EnvironmentObject var timelineVM: TimelineViewModel
//    var onOpenDiscussion: (Post) -> Void
//
//    var body: some View {
//        if #available(iOS 17.0, *) {
//            ScrollView(.vertical) {
//                LazyVStack(spacing: 0) {
//                    ForEach(timelineVM.related) { post in
//                        RelatedPostView(post: post, onOpenDiscussion: onOpenDiscussion)
//                            .containerRelativeFrame(.vertical)   // 1ページ＝可視領域にフィット
//                    }
//                }
//                .scrollTargetLayout()
//            }
//            .scrollTargetBehavior(.paging)
//            // 自動マージンを明示ゼロ（SDKあり）
//            .contentMargins(.top, 0, for: .scrollContent)
//            .contentMargins(.bottom, 0, for: .scrollContent)
//            .scrollIndicators(.hidden)
//            // ★ この ScrollView だけ上インセット無効化
//            .background(ScrollViewInsetFix())
//        } else {
//            // iOS 16 以前は通常スクロール（スナップなし）
//            ScrollView(.vertical) {
//                VStack(spacing: 0) {
//                    ForEach(timelineVM.related) { post in
//                        RelatedPostView(post: post, onOpenDiscussion: onOpenDiscussion)
//                            .frame(maxWidth: .infinity, minHeight: 0)
//                    }
//                }
//            }
//            .scrollIndicators(.hidden)
//            .background(ScrollViewInsetFix()) // 同様に適用
//        }
//    }
//}





import SwiftUI

/// 「関連」タブを 1画面=1投稿 で縦ページング表示するビュー
struct RelatedTimelinePager: View {
    @EnvironmentObject var timelineVM: TimelineViewModel
    var onOpenDiscussion: (Post) -> Void

    var body: some View {
        if #available(iOS 17.0, *) {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(timelineVM.related) { post in
                        RelatedPostView(post: post, onOpenDiscussion: onOpenDiscussion)
                            .containerRelativeFrame(.vertical)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .contentMargins(.top, 0, for: .scrollContent)
            .contentMargins(.bottom, 0, for: .scrollContent)
            .scrollIndicators(.hidden)
        } else {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(timelineVM.related) { post in
                        RelatedPostView(post: post, onOpenDiscussion: onOpenDiscussion)
                            .frame(maxWidth: .infinity, minHeight: 0)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}
