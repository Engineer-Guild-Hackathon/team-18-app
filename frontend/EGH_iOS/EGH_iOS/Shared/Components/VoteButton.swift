//
//  VoteButton.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  正誤投票ボタン

import SwiftUI

struct VoteButton: View {
    var title: String
    var isCorrect: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.body.weight(.semibold)).frame(maxWidth: .infinity).padding(14)
        }
        .buttonStyle(.bordered)
        .tint(isCorrect ? .green : .red)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isCorrect ? Color.green : Color.red, lineWidth: 2))
    }
}
