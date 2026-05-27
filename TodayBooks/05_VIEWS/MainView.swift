//
//  MainView.swift
//  TodayBooks
//
//  Created by yoonie on 5/16/26.
//

import SwiftUI
import SwiftData

/// 앱에서 지원하는 카테고리들의 기본 정보를 정의
struct CategoryDatum {
    let title: String // 카테고리 제목
    let icon: String // 아이콘 이름
}

/// 엡의 핵심화면으로 모든 주요 기능에 접근할 수 있는 초기 화면
struct MainView: View {
	
    // MARK: - Properties
	@Environment(\.modelContext) private var modelContext // SwiftData 컨택스트
	@Query private var myBooks: [MyBook] = []  // 저장된 도서 목록
	
    /// 홈 화면 데이터 관리 ViewModel
    @State private var homeViewModel: HomeViewModel = .init()
	/// 나의 서재 관리 ViewModel
	@State private var myLibraryViewModel: MyLibraryViewModel = .init()
	
    /// 선택된 도서 상세보기 용
    @State private var selectedBook: Book?
    /// 검색 화면 표시 상태 값
    @State private var showSearchView: Bool = false
    /// 나의 서재 화면 표시 상태
    @State private var showMyLibrary: Bool = false
    
    /// 앱에서 지원하는 카테고리들의 정적 데이터 배열
    private var categoryData: [CategoryDatum] = [
        CategoryDatum(title: "베스트셀러", icon: "star.fill"),       // 인기 도서
        CategoryDatum(title: "프로그래밍", icon: "laptopcomputer"),  // 개발/기술 도서
        CategoryDatum(title: "소설", icon: "book"),                // 문학/소설
        CategoryDatum(title: "자기개발", icon: "person.fill"),      // 자기개발
        CategoryDatum(title: "영어", icon: "globe"),               // 영어학습
        CategoryDatum(title: "비즈니스", icon: "briefcase")         // 비즈니스
    ]
    
    // MARK: - MainView Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background View 배경
                backgroundView
                // Content
                VStack(spacing: 0) {
                    headerSection // 상단 헤더 (로고, 검색, 서재 버튼)
                    mainContentScrollView // 메인 컨텐츠 스크롤 뷰
                    
                } //:VSTACK
            } //:ZSTACK
            
            // MARK: - Sheet 들 -> 다양한 화면을 시트 형태로 표시
            // 도서 상세 보기 시트
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book) // 선택된 도서의 상세 정보 화면
            }
			// 도서 검색 화면 시트
			.sheet(isPresented: $showSearchView) {
				SearchView()
			}
			// 나의 서재 시트
			.sheet(isPresented: $showMyLibrary) {
				MyLibraryView()
			}
			// 뷰 나타날 때: 초기 설정 수행
			.onAppear {
				myLibraryViewModel.setModelContext(context: modelContext)
			}
        }//: NAVIGATIONSTACK
    }
}

// MARK: - View Components
/// 메인 화면을 구성하는 개별 UI 요소 컴포넌트
extension MainView {
    /// 배경 뷰
    @ViewBuilder
    private var backgroundView: some View {
        Color.bookYellow
            .opacity(0.1)
            .ignoresSafeArea()
    }
    
    /// 헤더 섹션: 상단 고정 헤더 (로고 + 액션 버튼들)
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 0) {
            appLogoView               // 앱 로고
                .hLeading()
            HStack(spacing: 20) {
                searchButton          // 검색 버튼
                myLibraryButton       // 나의 서재 버튼
            } //:HSTACK
            .hTrailing()
        } //:HSTACK
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(
            Color.white
                .shadow(
                    color: Color.bookDarkBrown.opacity(0.1),
                    radius: 3,
                    x: 0,
                    y: 3
                )
        )
    }
    
    /// 앱 로고 뷰
    @ViewBuilder
    private var appLogoView: some View {
        HStack(spacing: 5) {
            Text("today")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.bookOrange)
            
            Text("Books")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.bookRed)
        } //:HSTACK
    }
    
    /// 검색 버튼: 검색 화면을 여는 액션 버튼
    @ViewBuilder
    private var searchButton: some View {
        Button {
            // Action
            showSearchView = true // 검색 화면 시트 표시
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundStyle(.bookOrange)
                .frame(width: 45, height: 45)  // 45*45 이 frame을 설정하지 않으면 터치 영역 보장
        }
        .buttonStyle(.plain) // 기존 버튼 스타일 제거
    }
    
    /// 나의 서재 버튼: 저장된 도서 목록을 여는 버튼 (badge 포함)
    @ViewBuilder
    private var myLibraryButton: some View {
        Button {
            // Action
            showMyLibrary = true   // 나의 서재 화면 시트 표시
        } label: {
            ZStack { // 아이콘과 badge를 겹쳐서 표시
                // 서재 아이콘
                Image(systemName: "books.vertical")
                    .font(.title)
                    .foregroundStyle(.bookDarkBrown)
                    .frame(width:  45, height: 45)
                
                // TODO: 저장된 도서수 배지로 할 것
				if myBooks.count > 0 {
					Text("\(myBooks.count)") // 저장된 도서 개수
						.font(.caption2)
						.fontWeight(.bold)
						.foregroundStyle(.white)
						.frame(minWidth: 18, minHeight: 18)
						.background(
							Circle().fill(.bookRed)
						)
						.offset(x: 10, y: -10)
				}
            } //:ZSTACK
            .buttonStyle(.plain)
        }
    }
    
    /// 메인 컨텐츠 영역 스크롤 뷰: 카테고리별 도서목록을 표시하는 스크롤 영역
    @ViewBuilder
    private var mainContentScrollView: some View {
        ScrollView {
            LazyVStack(
                // 지연 로딩 VSTACK
                spacing: 25,
                pinnedViews: [.sectionHeaders],
                content: {
                    // 로딩 상태에 따른 조건부 렌더링
                    if homeViewModel.isLoadingCategories {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.bookRed)
                    } else {
                        // 로딩이 끝나고 도서 별 섹션 표시
                        VStack(spacing: 30) {
                            // 카테고리 데이터 배열을 반복하여 각 카테고리 섹션 생성
                            ForEach(categoryData, id: \.title) { categoryDatum in
                                categorySection(
                                    title: categoryDatum.title,
                                    icon: categoryDatum.icon,
                                    books: homeViewModel.getBooksForCategory(category: categoryDatum.title),
									category: categoryDatum.title
                                )
                            }
                            
                        } //:VSTACK
                    }
                }
            )
            .padding(.top, 15)
        } //:SCROLL
    }
    
    @ViewBuilder
    private func categorySection(
        title: String,
        icon: String,
        books: [Book],
		category: String
    ) -> some View {
		VStack(spacing: 15) { // 헤더와 도서 목록 사이 15 포인트 간격
			// 카테고리 헤더
			CategoryHeaderView(
				title: title,
				subTitle: "\(books.count)권",
				icon: icon
			)
			// 도서 목록 뷰
			ScrollView(.horizontal) {
				LazyHStack(spacing: 15) {
					ForEach(books) { book in
						BookThumbnail.medium(book: book)
							.onTapGesture {
								selectedBook = book // 선택된 도서 설정 (상세보기 트리거)
							}
						// 무한 스크롤 구현 : 마지막 책이 나타나면 더 로드
							.onAppear {
								// 마지막에서 3번째 책이 나타나면 미리 로딩 시작
								if let lastIndex = books.lastIndex(of: book),
								   lastIndex >= books.count - 3,
								   homeViewModel.hasMorePages(category: category),
								   !homeViewModel.isLoadingMore(category: category) {
									Task {
										await homeViewModel.loadMoreBook(category: category)
									}
								}
							}
					}
				}
				.padding()
			}
			.scrollIndicators(.hidden)
			.background(
				Color.white
					.clipShape(RoundedRectangle(cornerRadius: 10))
					.shadow(radius: 5)
			)
			.padding(.horizontal, 15)
			
		} //:VSTACK
    }
}

#Preview {
    MainView()
}
