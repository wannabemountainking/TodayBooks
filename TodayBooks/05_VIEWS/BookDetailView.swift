//
//  BookDetailView.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/25/26.
//

import SwiftUI
import SwiftData
import WebKit


/// 선택된 도서의 모든 정보를 표시하는 상세 화면
struct BookDetailView: View {
	// MARK: - Properties
	let book: Book // 표시할 도서 정보 (외부에서 전달 받은 도서 데이터)
	
	// 환경 변수들
	@Environment(\.dismiss) private var dismiss // 화면 닫기 액션
	
	// TODO: 상태 관리 값들
	
    var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				ZStack {
					// Background Color
					Color.bookYellow
						.opacity(0.1)
						.ignoresSafeArea()
					// Content
					ScrollView {
						VStack(spacing: 0) {
							bookHeaderSection // 헤더 섹션
							bookMainInfoSection // 메인 섹션 썸네일 기본 정보 2 칼럼
							bookContentSection // 책 내용 섹션 (설명)
							actionButtonSection // 액션 버튼 색션 (온라인 링크, 공유 버튼)
						}
					}
				} //:ZSTACK
			} //:VSTACK
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				// 툴바 왼쪽: 북마크 버튼
				ToolbarItem(placement: .topBarLeading) {
					Button {
						//action
						// TODO: 북마크 상태 토글 함수 (MyList )
					} label: {
						Image(systemName: "bookmark.fill")
							.font(.title2)
							.foregroundStyle(Color.bookRed)
					}
				}
				
				// 툴바 오른쪽: 창 닫기 버튼
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						// Action
						dismiss()  // 현재 화면 닫기 (환경 변수값 사용)
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.title2)
							.foregroundStyle(Color.bookOrange)
					}
				}
			}
		} //:NAVSTACK
    }
}

// MARK: - EXTENSION
extension BookDetailView {
	// MARK: - Header Section
	/// 도서 제목 표시 헤더
	@ViewBuilder
	private var bookHeaderSection: some View {
		Text(book.title)
			.font(.title2)
			.fontWeight(.bold)
			.foregroundStyle(.bookDarkBrown)
			.multilineTextAlignment(.center)
			.padding(.horizontal, 20)
			.padding(.bottom, 20)
	}
	
	// MARK: - Main Info Section
	/// 썸네일과 기본 정보를 2컬럼으로 표시하는 섹션
	@ViewBuilder
	private var bookMainInfoSection: some View {
		HStack(spacing: 20) {
			// 왼쪽: 썸네일 이미지 (제목 없음)
			BookThumbnail.large(book: book, showTitle: false)
				.shadow(
					color: Color.bookDarkBrown.opacity(0.5),
					radius: 10,
					x: 0,
					y: 5
				)
			// 오른쪽: 기본정보 (저자, 출판사, 가격)
			VStack(spacing: 15) {
				infoRow(
					title: "저자",
					icon: "person.fill",
					value: book.authorsText,
					color: Color.bookRed
				)
				
				infoRow(
					title: "출판사",
					icon: "building.2.fill",
					value: book.publisher,
					color: Color.bookOrange
				)
				
				infoRow(
					title: "가격",
					icon: "wonsign",
					value: "\(book.price.formatted())원",
					color: Color.bookRed
				)
				
				Spacer()
			} //:VSTACK
			.frame(maxWidth: .infinity, alignment: .leading)
		} //:HSTACK
		.padding(.horizontal, 20)
		.padding(.bottom, 30)
	}
	
	///기본 정보 행 생성함수
	@ViewBuilder
	private func infoRow(title: String, icon: String, value: String, color: Color) -> some View {
		VStack(alignment: .leading, spacing: 5) {
			// 아이콘 + 제목
			HStack(spacing: 5) {
				Image(systemName: icon)
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(color)
				
				Text(title)
					.font(.caption)
					.fontWeight(.medium)
					.foregroundStyle(.secondary)
			}
			
			// 값 - Value
			Text(value)
				.font(.subheadline)
				.fontWeight(.medium)
				.foregroundStyle(.bookDarkBrown)
				.lineLimit(2)
			
		} //:VSTACK
		.padding(10)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 10)
				.fill(.white)
				.shadow(color: Color.bookDarkBrown.opacity(0.1), radius: 2)
		)
	}
	
	// MARK: - Book Content Section
	/// 도서 상세 설명과 온라인 구매 링크를 표시하는 섹션
	@ViewBuilder
	private var bookContentSection: some View {
		VStack(spacing: 20) {
			// Content Section Header
			HStack(spacing: 10) {
				// 책 페이지 아이콘
				Image(systemName: "book.pages")
					.font(.headline)
					.foregroundStyle(.bookRed)
				// 설명 제목 텍스트
				Text("책 소개")
					.font(.headline)
					.fontWeight(.bold)
					.foregroundStyle(.bookDarkBrown)
			} //:HSTACK
			.hLeading()
			
			// 도서 설명 텍스트 영역
			Text(book.contents)
				.font(.body)
				.lineSpacing(4)
				.foregroundStyle(.bookDarkBrown)
				.padding(.horizontal, 15)
				.padding(.vertical, 20)
				.background(
					RoundedRectangle(cornerRadius: 15)
						.fill(.white)
						.shadow(color: Color.bookDarkBrown.opacity(0.1), radius: 3)
				)
			
		} //:VSTACK
		.padding(20)
	}
	
	// MARK: - Action Button Section
	/// 웹링크, 공유버튼 색션
	@ViewBuilder
	private var actionButtonSection: some View {
		/// 온라인 서점 링크: 웹뷰 페이지 이동
		if let url = URL(string: book.url) {
			NavigationLink {
				// 링크
				WebView(url: url)
			} label: {
				<#code#>
			}

		}
	}
	
}

#Preview {
	BookDetailView(book: Book.mockList[0])
}
