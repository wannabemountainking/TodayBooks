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
    @Environment(\.modelContext) private var modelContext // SwiftData 컨텍스트
    
    // 상태 관리
    @State private var myLibraryViewModel: MyLibraryViewModel = .init()  // 나의 서재 관리 ViewModel
    @State private var showBookmarkAlert: Bool = false // 북마크 알림 표시 상태
    @State private var bookmarkMessage: String = "" // 북마크 관련 메시지
    @State private var forceUpdateTrigger: Bool = false // 강제 UI 업데이트 트리거
	
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
						toggleBookmark() // 북마크 상태 토글 함수 호출
					} label: {
						Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
							.font(.title2)
							.foregroundStyle(isBookmarked ? Color.bookRed : .bookOrange)
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
			} //:TOOLBAR
            .onAppear {  // 뷰가 나타날 때 실행: SwiftData 컨텍스트 설정
				myLibraryViewModel.setModelContext(context: modelContext) // ViewModel에 DB 컨텍스트(MyBooks의 ??) 전달
            }
            // 북마크 메시지 나오는 곳
            // 토스트 알림: 북마크 추가 / 제거 상태를 오버레이로 표시
            .overlay(alignment: .top) {
                if showBookmarkAlert {
                    toastNotification // 토스트 알림 컴포넌트
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
                HStack(spacing: 12) {
                    // 사파리 브라우져 아이콘
                    Image(systemName: "safari.fill")
                        .font(.title3)
                        .foregroundStyle(.bookOrange)
                    
                    // 링크 버튼 텍스트
                    Text("상세 페이지 보기")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.bookOrange)
                        .hLeading()
                    
                    // 오른쪽 화살표 아이콘
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.bookOrange)
                        .hTrailing()
                    
                } //:HSTACK
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.bookOrange, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.bookOrange.opacity(0.1))
                        )
                )
			} //:NavLink
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)

		}
        
        // MARK: - Share Button
        ShareLink(
            item: shareText,                        // 공유할 텍스트 내용
            subject: Text(book.title),              // 이메일, 제목 등에 사용될 주제
            message: Text("\(book.title)책 공유")     // 공유 시 추가 메시지
        ) {
            // Label 부분
            HStack(spacing: 12) {
                // 공유 아이콘
                Image(systemName: "square.and.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                // 공유 버튼 텍스트
                Text("이 책 공유하기")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .hCenter()
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.bookRed)
                    .shadow(color: Color.bookYellow.opacity(0.1), radius: 3)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
	}
    
    /// 공유 텍스트 생성: 도서 정보를 포멧된 텍스트로 변환
    private var shareText: String {
        """
        \(book.title)
        
        저자: \(book.authorsText)
        출판사: \(book.publisher)
        가격: \(book.price.formatted()) 원
        
        \(book.contents)
        
        자세히 보기: \(book.url)
        """
    }
	
	/// 북마크 상태 확인: 지금 도서가 나의 서재에 저장되어 있는지 확인(북마크가 되어 있는지)
	private var isBookmarked: Bool {
		// forceUpdateTrigger 를 참조하여 UI 강제 업데이트
		_ = forceUpdateTrigger
		return myLibraryViewModel.isBookmarked(book: book)
	}
	
	// MARK: - 북마크 로직
	/// 도서를 나의 서재에 추가 / 제거 하는 비즈니스 로직을 처리
	/// SwiftData를 통해 삭제 그리고 추가 로직을 담당
	private func toggleBookmark() {
		// 토글 전 현재 북마크 상태 확인 / 저장
		let wasBookmarked = isBookmarked
		
		// MyLibraryViewModel을 통한 북마크 상태 토글
		myLibraryViewModel.toggleBookmark(book: book)
		
		// 에러처리: ViewModel에서 발생한 오류 확인
		if let errorMessage = myLibraryViewModel.errorMessage {
			bookmarkMessage = errorMessage // 에러메시지 표시
		} else {
			// 성공시: 토글 전 상태에 따라서 적절한 성공 메시지
			bookmarkMessage = wasBookmarked
			? "\(book.title) 이(가) 내 서재에서 제거되었습니다" // 북마크 해제 메시지
			: "\(book.title) 이(가) 내 서재에 추가되었습니다"  // 북마크 추가 메시지
		}
		
		// 사용자 피드백: 토스트 알림 표시
		withAnimation(.spring) {
			showBookmarkAlert = true
		}
		
		// 상태 정리: ViewModel의 에러 상태 초기화 (다음 작업을 위해)
		myLibraryViewModel.clearError()
		
		// 즉시 UI 업데이트를 위해 강제 새로고침 (색상 변경 반영)
		forceUpdateTrigger.toggle()  
	}
    
    /// 토스트 알림 컴포넌트: 북마크 상태 변경 시 상단에 표시되는 알림
    @ViewBuilder
    private var toastNotification: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // 성공 아이콘
                Image(systemName: bookmarkMessage.contains("추가") ? "bookmark.fill" : "bookmark.slash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                // 알림 메시지
                Text(bookmarkMessage)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            } //:HSTACK
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.bookRed)
            )
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
        } //:VSTACK
        .transition(.move(edge: .top).combined(with: .opacity))
        // 3초 후에 자동으로 토스트 알림 숨기기
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showBookmarkAlert = false
                }
            }
        }
    }
    
    
}

#Preview {
	BookDetailView(book: Book.mockList[0])
}
