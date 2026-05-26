//
//  SearchView.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/26/26.
//

import SwiftUI

/// 도서 검색을 위한 전용 화면
struct SearchView: View {
	// MARK: - Properties
	
	// 현재 뷰를 닫는 환경 값
	@Environment(\.dismiss) private var dismiss
	
	// @State
	@State private var searchText: String = "" // 검색창에 입력된 텍스트
	@State private var selectedBook: Book?  // 선택된 책 (nil이면 시트가 닫힘)
	
	/// TextField의 포커스 상태를 추적 / 제어
	/// true: 키보드가 올라와 았음 - 포커스 됨
	/// false: 키보드가 내려감 - 포커스 해제
	@FocusState private var isSearchFocused: Bool
	
    var body: some View {
		NavigationStack {
			ZStack {
				// 배경색
				Color.bookYellow.opacity(0.1).ignoresSafeArea()
				
				// contents
				VStack(spacing: 0) {
					searchInputSection
					searchResultsSection
				} //:VSTACK
				.padding(.top)
			} //:ZSTACK
			.toolbar {
				// Close 버튼
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						// Action
						dismiss()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.title2)
							.foregroundStyle(.bookOrange)
					}
				}
				
			} //:TOOLBAR
			.navigationTitle("도서 검색")
			.navigationBarTitleDisplayMode(.large)
		} //:NAVSTACK
    }
}

// MARK: - EXTENSION (뷰 컴포넌트)
extension SearchView {
	// MARK: - 검색 입력 색션
	/// 검색 입력 색션
	@ViewBuilder
	private var searchInputSection: some View {
		VStack(spacing: 15) {
			searchBar
			
			searchGuideView
			
		} //:VSTACK
	}
	
	/// 검색 바 (통합) - 기능: 포커스 상태에 따라 동적으로 스타일 변화. 텍스트 입력시 클리어 버튼(x) 표시
	@ViewBuilder
	private var searchBar: some View {
		HStack(spacing: 12) {
			// 검색 아이콘
			Image(systemName: "magnifyingglass")
				.font(.system(size: 15, weight: .medium))
				.foregroundStyle(.bookRed)
			
			// 검색 텍스트 필드
			TextField("책 제목, 저자, 출판사를 검색하세요", text: $searchText)
				.font(.system(size: 15, weight: .regular))
				.focused($isSearchFocused)               // TextField가 포커스 되면 true가 됨
				.textInputAutocapitalization(.never)     // 자동 대문자 활성화를 비활성화함
				.autocorrectionDisabled()                // 자동 수정 비활성화
				.onSubmit {                // 키보드 완료 / 검색 버튼 탭 시 실행
					//TODO: 검색 시작 로직 넣기
				}
				.submitLabel(.search)      // 키보드 완료 버튼 텍스트 변경
			
			// 클리어 버튼 (X) - 텍스트가 있을 때만 표시
			if !searchText.isEmpty {
				Button {
					// Action
					searchText = ""
					isSearchFocused = false
				} label: {
					Image(systemName: "xmark.circle.fill")
						.font(.system(size: 15, weight: .medium))
						.foregroundStyle(Color.bookOrange)
				}
			} //:CONDITION
		} //:HSTACK
		.padding(15)
		.background(
			RoundedRectangle(cornerRadius: 15)
				.fill(Color.bookYellow.opacity(0.1))
				.stroke(Color.bookRed)
				.shadow(
					color: Color.bookRed.opacity(0.3),
					radius: 5,
					x: 0,
					y: 2
				)
		)
		.padding(.horizontal, 20)

	}
	
	/// 검색 가이드 뷰 - (초기 상태만 나타남)
	@ViewBuilder
	private var searchGuideView: some View {
		ContentUnavailableView(
			"찾고 싶은 도서명을 입력해보세요",
			systemImage: "magnifyingglass",
			description: Text("작가명, 출판사, ISBN 으로도 검색할 수 있어요")
				.foregroundStyle(.bookDarkBrown)
		)
	}
	
	// MARK: - 검색 결과 색션
	/// 검색 결과 색션
	@ViewBuilder
	private var searchResultsSection: some View {
		ScrollView {
			
		} //:SCROLL
	}
}


#Preview {
    SearchView()
}
