//
//  CustomAlignment.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/14/26.
//

import SwiftUI

// MARK: - 커스텀 정렬 확장 (Custom Alignment Extensions)
/// SwiftUI View에 대한 커스텀 정렬 메서드들을 제공하는 확장
/// 주요 목적: 코드 간소화, 일관된 레이아웃 패턴, 재사용성 향상
/// 활용처: 모든 SwiftUI 뷰에서 간편한 정렬 적용
extension View {
	
	// MARK: - 📏 세로 정렬 메서드들 (Vertical Alignment Methods)
	/// 세로 방향 정렬을 위한 편의 메서드들
	/// maxHeight: .infinity를 사용하여 사용 가능한 세로 공간을 모두 차지
	
	/// 세로 중앙 정렬: 뷰를 세로축의 중앙에 위치시킴
	/// - Returns: 세로 중앙에 정렬된 뷰
	///  내부 동작: frame(maxHeight: .infinity, alignment: .center)와 동일
	func vCenter() -> some View {
		self.frame(maxHeight: .infinity, alignment: .center)
	}

	/// 세로 상단 정렬: 뷰를 세로축의 맨 위에 위치시킴
	/// - Returns: 세로 상단에 정렬된 뷰
	///  사용 예시: VStack { headerView.vTop() } → 헤더를 상단에 고정
	func vTop() -> some View {
		self.frame(maxHeight: .infinity, alignment: .top)
	}

	/// 세로 하단 정렬: 뷰를 세로축의 맨 아래에 위치시킴
	/// - Returns: 세로 하단에 정렬된 뷰
	///  사용 예시: Button("확인").vBottom() → 버튼을 화면 하단에 배치
	func vBottom() -> some View {
		self.frame(maxHeight: .infinity, alignment: .bottom)
	}

	// MARK: - ↔️ 가로 정렬 메서드들 (Horizontal Alignment Methods)
	/// 가로 방향 정렬을 위한 편의 메서드들
	/// maxWidth: .infinity를 사용하여 사용 가능한 가로 공간을 모두 차지
	
	///  가로 중앙 정렬: 뷰를 가로축의 중앙에 위치시킴
	/// - Returns: 가로 중앙에 정렬된 뷰
	///  사용 예시: Image("logo").hCenter() → 로고를 화면 가로 중앙에 표시
	func hCenter() -> some View {
		self.frame(maxWidth: .infinity, alignment: .center)
	}
	
	///  가로 좌측 정렬: 뷰를 가로축의 좌측에 위치시킴 (Leading 정렬)
	/// - Returns: 가로 좌측에 정렬된 뷰
	///  사용 예시: Text("제목").hLeading() → 텍스트를 좌측에 정렬
	func hLeading() -> some View {
		self.frame(maxWidth: .infinity, alignment: .leading)
	}
	
	///  가로 우측 정렬: 뷰를 가로축의 우측에 위치시킴 (Trailing 정렬)
	/// - Returns: 가로 우측에 정렬된 뷰
	///  사용 예시: Button("닫기").hTrailing() → 버튼을 우측에 배치
	func hTrailing() -> some View {
		self.frame(maxWidth: .infinity, alignment: .trailing)
	}
}
