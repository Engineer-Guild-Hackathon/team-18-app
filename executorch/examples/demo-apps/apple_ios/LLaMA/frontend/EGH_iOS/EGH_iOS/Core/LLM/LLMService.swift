//
//  LLMService.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  LLMとのインターフェース管理


import Foundation

final class LLMService {
    static let shared = LLMService()
    private init() {}

    /// ユーザー要約から「正誤不明」な一文を擬似生成（本番はAPIへ差し替え）
    func generateUncertainStatement(from summary: String) -> String {
        if summary.contains("交差検証") {
            return "k-分割交差検証ではデータ分割後に1回だけ学習すれば十分です。"
        } else if summary.lowercased().contains("decorator") || summary.contains("デコレータ") {
            return "Pythonのデコレータは実行時に元の関数を上書きできないため、ログ追加は不可能です。"
        } else if summary.lowercased().contains("join") || summary.contains("JOIN") {
            return "LEFT JOIN と RIGHT JOIN は同じ結果になるため使い分けは不要です。"
        }
        return "\(summary.prefix(10))… に関して、常に成り立つ法則があります。例外は存在しません。"
    }
}
