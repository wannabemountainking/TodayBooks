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
	private let categories = ["베스트셀러", "프로그래밍", "소설", "자기개발", "영어", "비지니스"]
	
	// MARK: - 의존성 주입 (Dependency Injection) -> 이미 만들어 놓은 네트워크 서비스, 액터를 끌어와 쓰는 것, 주로 singleton 패턴
	/// 네트워크 서비스
	private let networkService = KakaoBookService.shared
	/// 캐시 관리 Actor
	private let cacheActor = BookDataActor.shared
	
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
				}
			}
		}
		
		// 4. 로딩 상태 OFF
		isLoadingCategories = false
	}
    
    // MARK: - 데이터 접근 메서드들
    
    /// 특정 카테고리의 도서 목록 가져오기
    func getBooksForCategory(category: String) -> [Book] {
        return categoryBooks[category] ?? []    // 빈 배열을 기본값으로 제공하여 nil 체크 불필요
    }
}
