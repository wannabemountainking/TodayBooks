//
//  ContentView.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/14/26.
//

/*
 Asset Custom 색상들
 - `BookRed`: #DC2626 (빨간색)
 - `BookOrange`: #EA580C (주황색)
 - `BookYellow`: #D97706 (노란색)
 - `BookDarkBrown`: #78350F (진한 갈색)
 */

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
