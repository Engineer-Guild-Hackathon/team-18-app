//
//  TabBarView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  カスタムタブバー

// TabView を使っているため個別の TabBar 実装は不要。
// もしカスタムが必要ならここに置く。いまはダミー。
import Foundation
import SwiftUI

struct TabBarView: View {
    @Binding var selected: RootTab

    var body: some View {
        HStack {
            Spacer()

            Button {
                selected = .home
            } label: {
                VStack {
                    Image(systemName: "house.fill")
                    Text("ホーム").font(.caption2)
                }
                .foregroundColor(selected == .home ? .blue : .gray)
            }

            Spacer()

            Button {
                selected = .post
            } label: {
                VStack {
                    Image(systemName: "square.and.pencil")
                    Text("投稿").font(.caption2)
                }
                .foregroundColor(selected == .post ? .blue : .gray)
            }

            Spacer()

            Button {
                selected = .profile
            } label: {
                VStack {
                    Image(systemName: "person.fill")
                    Text("プロフィール").font(.caption2)
                }
                .foregroundColor(selected == .profile ? .blue : .gray)
            }

            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 16) // HomeIndicator にかからないよう余白
        .background(Color.white)
    }
}
