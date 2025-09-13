//
//  ScrollViewInsetFix.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//

import SwiftUI
import UIKit

/// 親の UIScrollView を探して contentInsetAdjustmentBehavior を .never にするデバッグレスユーティリティ。
/// これを .background(...) に差すだけで、その画面の ScrollView にだけ作用します。
struct ScrollViewInsetFix: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        DispatchQueue.main.async {
            // 親方向に辿って最初の UIScrollView を探す
            if let scroll = findEnclosingScrollView(from: view) {
                scroll.contentInsetAdjustmentBehavior = .never
            }
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}

    private func findEnclosingScrollView(from view: UIView?) -> UIScrollView? {
        var v = view?.superview
        while let current = v {
            if let s = current as? UIScrollView { return s }
            v = current.superview
        }
        return nil
    }
}
