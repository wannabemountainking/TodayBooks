//
//  TodayBooksApp.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/14/26.
//

import SwiftUI

@main
struct TodayBooksApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
				.preferredColorScheme(.light) // 앱을 라이트 모드로 고정
        }
    }
}
