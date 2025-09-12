//
//  PostHeader.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//

import SwiftUI
import Foundation

struct PostHeader: View {
    let author: User
    let createdAt: Date

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(author.name).font(.headline)
                Text(createdAt.relativeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}
