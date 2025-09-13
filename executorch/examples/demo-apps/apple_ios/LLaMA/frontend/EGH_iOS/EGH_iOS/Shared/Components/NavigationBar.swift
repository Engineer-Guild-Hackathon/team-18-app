//
//  NavigationBar.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  カスタムナビゲーションバー

import SwiftUI

struct NavigationBar: View {
    var title: String
    var body: some View {
        HStack {
            Text(title).font(.title2.bold())
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider(), alignment: .bottom)
    }
}
