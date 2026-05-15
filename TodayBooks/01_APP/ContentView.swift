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
    
    @State private var message: String = "버튼을 눌러 API 테스트하세요."
    @State private var isSuccess: Bool = false // 성공 / 실패 상태
    @State private var isLoading: Bool = false // 로딩 중 상태
    
    var body: some View {
        VStack(spacing: 30) {
            Button(action: {
                Task {
                    await testAPI() // 비동기 함수 호출
                }
            }, label: {
                Text("API 테스트")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            if isLoading {
                ProgressView() // 로딩 중 인디케이터
            } else {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(isSuccess ? .green : .red)
                
                // 결과 메시지
                Text(message)
                    .font(.title)
                    .foregroundStyle(isSuccess ? .green : .red)
            }
        }
        .padding()
    }
    
    /// API 테스트 함수
    @MainActor // UI 업데이트를 메인 스레드에서 처리
    private func testAPI() async {
        isLoading = true // 로딩 시작
        do {
            // 카카오 API 로 "Swift" 검색 요청
            let response = try await KakaoBookService.shared.searchBooks(query: "Swift")
            // 성공 시
            isSuccess = true
            message = "성공! \(response.documents.count) 권 검색됨"
        } catch {
            // 실패 시 에러처리
            isSuccess = false
            message = "실패!"
        }
        isLoading = false // 로딩 종료
    }
}

#Preview {
    ContentView()
}
