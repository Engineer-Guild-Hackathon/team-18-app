//
//  Modifiers.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  カスタムViewModifier定義

import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
    }
}
extension View { func cardStyle() -> some View { modifier(CardModifier()) } }
