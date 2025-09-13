//
//  TimerView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  カウントダウンタイマー表示

import SwiftUI

struct TimerView: View {
    let seconds: Int
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color.red).frame(width: 10, height: 10)
            Text("残り時間: \(format(seconds))")
                .foregroundColor(.red)
                .font(.subheadline.weight(.semibold))
        }
    }
    private func format(_ s: Int) -> String {
        let m = s / 60, sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
}
