//
//  HomeViewModel.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/16/26.
//

import Foundation
import Observation


/// 홈 화면데이터와 상태를 관리하는 ViewModel: 여러 카테고리에서 actor인 캐시와 연결해서 빠른 데이터 로드를 하고 무한 스크롤 지원 -> 초기화 ViewModel
@Observable
@MainActor
final class HomeViewModel {
	// MARK: - State Properties
	
	/// category 도서 저장 딕셔너리
	/// 예: ["베스트셀러": [Book1, Book2, ...], "프로그래밍": [Book3, Book4, ...]]
	var categoryBooks: [String: [Book]] = [:]
	
	/// 전체 카테고리 로딩 상태 (최초 로딩 시에만 true)
	var isLoadingCategories: Bool = false
	
	// MARK: - 카테고리 상수들
	/// 앱에서 지원하는 카테고리 목록
	private let categories = ["베스트셀러", "프로그래밍", "소설", "자기개발", "영어", "비즈니스"]
	
	// MARK: - 의존성 주입 (Dependency Injection) -> 이미 만들어 놓은 네트워크 서비스, 액터를 끌어와 쓰는 것, 주로 singleton 패턴
	/// 네트워크 서비스
	private let networkService = KakaoBookService.shared
	/// 캐시 관리 Actor
	private let cacheActor = BookDataActor.shared
	
	// MARK: - pagenation 관련 변수들
	/// 카테고리별 현재 페이지 번호 추적
	/// 저장 예시: ["베스트 셀러": 3, "프로그래밍": 5]
	private var categoryPages: [String: Int] = [:]
	
	/// 카테고리 별 로딩 중 상태 추적 (중복 API 호출 방지용)
	/// 예시: ["베스트셀러": true, "프로그래밍": false]
	private var categoryLoadingState: [String: Bool] = [:]
	
	/// 카테고리 별 추가 페이지 존재 여부 (무한 스크롤 종료 조건)
	/// 예시: ["베스트셀러": true, "프로그래밍": false]
	private var categoryHasMorePages: [String: Bool] = [:]
	

	// MARK: - Init
	init() {
		Task {
			await loadInitialData()
		}
	}
	
	// MARK: - 데이터 로딩 메서드들
	
	/// 초기 데이터 로딩 (앱 시작 시 호출)
	///
	/// 실행 흐름
	/// 1. isLoadingCategories = true (로딩 시작)
	/// 2. 6개 카테고리를 병렬로 처리 (TaskGroup)
	/// 	- 각 카테고리 별로
	/// 	① 캐시 확인 (getCachedCategory)
	/// 	② Cache Hit: 즉시 반환
	/// 	③ Missing Cache: API 호출 -> 캐시 저장
	/// 3. 결과를 categoryBooks에 저장
	/// 4. isLoadingCategories = false (로딩 완료)
	func loadInitialData() async {
		// 1. 로딩 시작 알림
		isLoadingCategories = true
		
		// 2. 6개 카테고리를 병렬로 처리
		// TaskGroup으로 병렬 처리
		// of: (String, [Book]?).self -> 반환 타입 지정 (카테고리명, 도서목록)
		await withTaskGroup(of: (String, [Book]?).self) { group in
			
			// 각 카테고리별 별도의 Task 생성
			for category in categories {
				group.addTask { [weak self] in // self가 메모리에서 해제되면 nil 처리됨
					guard let self else {return (category, nil)}
					// A. 캐시 확인 (Actor 해제)
					if let cached = await self.cacheActor.getCachedCategory(category, page: 1) {
						return (category, cached.books) // 캐시된 데이터 반환
					}
					// B. 캐시가 없으니까 API 호출 필요
					do {
						// API 호출
						let response = try await self.networkService.searchBooks(
							query: category, // 검색어 (카테고리명)
							size: 20         // 한번에 20권씩 데이터 불러오기
						)
						// 캐시에 저장 ( 다음 진입 시 빠르게 로드하기 위함)
						await self.cacheActor.cacheCategory(
							category,
							page: 1,
							books: response.documents,
							totalCount: response.meta.totalCount,
							isEnd: response.meta.isEnd
						)
						// API 결과를 반환
						return (category, response.documents)
					} catch {
						return (category, nil) // nil 반환 (UI에서 빈 상태를 표시
					}
				}
			}
			
			// 3. ViewModel 상태 업데이트
			// for await 의 역할은 TaskGroup 의 결과를 하나씩 받아옴 (완료된 순서대로)
			for await (category, books) in group {
				if let books = books {  // nil 체크
					categoryBooks[category] = books // 딕셔너리에 저장
					categoryPages[category] = 1     // 현재 페이지를 1로 설정
					categoryLoadingState[category] = false // 로딩 상태. OFF
					categoryHasMorePages[category] = books.count >= 20 // 20권이면 다음 페이지 있을 가능성
				}
			}
		}
		
		// 4. 로딩 상태 OFF
		isLoadingCategories = false
	}
	
	// MARK: - 다음 페이지 로드 (무한 스크롤)
	/// 다음 페이지 로드 (무한 스크롤)
	///
	/// 실행 흐름
	/// 1. 중복 호출 방지 체크
	/// 	- hasMore 가 false이면 중단
	/// 	- isLoading이 true이면 중단
	/// 2. 캐시 확인
	/// 	- Cache Hit: 즉시 사용
	/// 	- Missing Cache: API 호출 -> 캐시 저장
	/// 3. 기존 배열에 추가 (append)
	/// 4. pagenation 상태 업데이트
	
	func loadMoreBook(category: String) async {
		
		// 1. 중복 호출 방지 체크 (3가지)
		guard  let hasMore = categoryHasMorePages[category], hasMore,  // 1. 더 불러올 페이지가 있는지 체크
			   let isLoading = categoryLoadingState[category], !isLoading // 2. 현재 로딩중인지 아닌지 체크
		else {
			return // 조건이 하나라도 false 면 함수를 바로 종료 (불필요한 API 호출 방지)
		}
		
		// 2. 로딩 상태 전환 및 페이지네이션
		categoryLoadingState[category] = true // 로딩 상태 ON (중복 호출 방지)
		let currentPage = categoryPages[category] ?? 1 // 현재 페이지 (기본값: 1)
		let nextPage = currentPage + 1 // 다음 페이지 계산
		
		// 3. 캐시 확인 -> Actor 에 요청
		if let cached = await cacheActor.getCachedCategory(category, page: nextPage) {
			
			// A. Cache Hit 상태 -> 즉시 사용 API 호출 건너뜀
			// 기존 배열에 추가 (Dictionary의 값을 수정하는 패턴)
			if var existingBooks = categoryBooks[category] { // var로 복사 (Dictionary와 같은 Value 타입)
				existingBooks.append(contentsOf: cached.books) // 배열에 추가
				categoryBooks[category] = existingBooks   // Dictionary에 다시 저장 (재할당) => a, b 변수의 값을 스위치하는 방식과 유사
			} else {
				categoryBooks[category] = cached.books
			}
			
			// 페이지네이션 상태 업데이트
			categoryPages[category] = nextPage // 현재 페이지 번호 증가
			categoryHasMorePages[category] = !cached.isEnd && cached.books.count >= 20 // 다음 페이지 있는 지 여부 체크
			categoryLoadingState[category] = false // 로딩상태 OFF
			return // 캐시 히트면 여기서 끝
		}
		
		// B. Missing Cache -> API 호출 필요
		do {
			// 1. API 호출
			let response = try await networkService.searchBooks(
				query: category,  // 검색어, 카테고리 명
				page: nextPage,   // 페이지 번호 2, 3, 4, ...
				size: 20          // 한 번에 20권씩 호출
			)
			// 2. 캐시에 저장 (다음 진입시 빠르게 로드하기 위함)
			await cacheActor.cacheCategory(
				category,
				page: nextPage,
				books: response.documents,
				totalCount: response.meta.totalCount,
				isEnd: response.meta.isEnd
			)
			
			// 3. ViewModel 에 업데이트 (기존 배열 추가)
			if var existingBook = categoryBooks[category] {  // 데이터가 있는 경우
				existingBook.append(contentsOf: response.documents) // 새로운 도서를 추가
				categoryBooks[category] = existingBook    // Dictionary 재할당
			} else {
				categoryBooks[category] = response.documents // 기존 데이터가 없으면 새로 생성
				categoryHasMorePages[category] = !response.meta.isEnd && response.documents.count >= 20 // 다음 페이지 있는 지 여부 체크
			}
		} catch {
			// 에러 발생시
			categoryHasMorePages[category] = false // 더 이상 로딩되지 않음 (무한 재시도 방지)
		}
		
		categoryLoadingState[category] = false // 로딩 상태 OFF (성공 / 실패와 상관 없이 항상 실행)
	}
    
    // MARK: - 데이터 접근 메서드들
    
    /// 특정 카테고리의 도서 목록 가져오기
    func getBooksForCategory(category: String) -> [Book] {
        return categoryBooks[category] ?? []    // 빈 배열을 기본값으로 제공하여 nil 체크 불필요
    }
	
	/// 특정 카테고리 추가 로딩 상태 확인
	func isLoadingMore(category: String) -> Bool {
		return categoryLoadingState[category] ?? false
	}
	
	/// 특정 카테고리 더 불러올 페이지가 있는지 확인
	func hasMorePages(category: String) -> Bool {
		return categoryHasMorePages[category] ?? false
	}
}
