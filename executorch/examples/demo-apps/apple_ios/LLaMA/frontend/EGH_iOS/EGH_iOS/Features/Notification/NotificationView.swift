//
//  NotificationView.swift
//  EGH_iOS
//
//  Created by 遠藤羊太郎 on 2025/09/10.
//  学習リマインダー通知画面

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var notificationVM: NotificationViewModel

    var body: some View {
        ZStack {
            LinearGradient(colors: [.appBlue, .appBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("📚")
                    .font(.system(size: 64))
                    .padding(.bottom, 8)
                Text("今日の学びを共有する時間です！")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Text("今から5分以内に、今日学んだことを200文字以内でまとめてください")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal)
                NavigationLink("まとめを書く") {
                    PostInputView()
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundColor(.appBlue)
                .padding(.top, 8)
            }
            .padding(40)
        }
        .onAppear { notificationVM.scheduleDailyWindow() }
    }
}
