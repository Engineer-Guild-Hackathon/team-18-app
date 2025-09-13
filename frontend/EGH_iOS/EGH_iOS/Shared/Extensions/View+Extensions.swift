//
//  View+Extensions.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  View拡張（共通UI処理）

import SwiftUI

extension View {
    func fullWidth() -> some View { frame(maxWidth: .infinity) }
}
