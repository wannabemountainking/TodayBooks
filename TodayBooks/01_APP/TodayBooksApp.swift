//
//  TodayBooksApp.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/14/26.
//

import SwiftUI
import SwiftData

@main
struct TodayBooksApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
				.preferredColorScheme(.light) // 앱을 라이트 모드로 고정
        }
		// SwiftData 모델 컨테이너: 앱 전체에서 SwiftData 기능을 사용할 수 있게
		.modelContainer(for: MyBook.self)
    }
}
