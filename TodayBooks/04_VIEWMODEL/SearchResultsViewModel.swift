//
//  SearchResultsViewModel.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/26/26.
//

import Foundation
import Observation


/// 도서 검색 기능과 검색 결과의 페이지네이션을 관리하는 ViewModel
@MainActor
@Observable
final class SearchResultsViewModel {
	// MARK: - Singleton instances
	/// 네트워크 서비스 (API 호출)
	private let networkService = KakaoBookService.shared
	/// 캐시 관리 Actor
	private let cacheActor = BookDataActor.shared
	
	// MARK: - 검색 결과 데이터
	/// 검색된 도서 목록
	var searchResults: [Book] = []
	/// 검색 중 상태 (로딩 인디케이터 표시용)
	var isSearching = false
	/// 검색을 한 번이라도 수행했는지 여부 (빈 상태 UI  판단용)
	var hasSearched = false
	/// 현재 검색어 (추가 페이지 로딩 시 사용)
	var currentSearchQuery: String = ""
	
	// MARK: - 페이지네이션 관련
	/// 현재 로드된 페이지 번호
	var currentPage = 1
	/// 추가 페이지 로딩 중 상태
	var isLoadingMore = true
	/// 더 불러올 페이지가 있는지 여부
	var hasMorePages = true
	/// 전체 검색 결과 수(API 의 meta.totalCount)
	var totalCount = 0
	
	// MARK: - Public Method
	
	/// 도서 검색 메인 함수 (캐시 연동)
	/// 실행 흐름
	/// 1. 검색어 유효성 검사
	/// 2. 검색 상태 설정 (isSearching = true)
	/// 3. 캐시 확인
	///    - Cache Hit: 즉시 반환 (0.01초)
	///    - Cache Miss: API 호출 (1초) -> 캐시 저장
	/// 4. searchResults 업데이트
	/// 5. isSearching = false
	
	func searchBooks(query: String) async {
		// 1. 검색어 유효성 검사 - 빈 검색어인지 확인
		guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {return}
		print("SearchView: 검색 시작 - \(query)")
		// 2. 검색 상태 설정
		isSearching = true
		currentSearchQuery = query
		
		// 3. 캐시 확인
		if let cached = await cacheActor.getCachedSearch(query: query, page: 1) {
			// 캐시가 있는 경우 Cache Hit - 즉시 반환
			print("Cache Hit - \(query)")
			//ViewModel에 상태 즉시 업데이트
			searchResults = cached.books
			hasSearched = true
			currentPage = 1
			totalCount = cached.totalCount
			hasMorePages = !cached.isEnd
			
			isSearching = false
			return // 함수 종료
		}
		
		// 캐시가 없는 경우 - API 호출
		print("Cache Miss - API 호출 시작 - \(query)")
		
		do {
			// API 호출
			let response = try await networkService.searchBooks(
				query: query,
				page: 1,
				size: 20
			)
			
			// 다음 검색을 위한 캐시 저장
			await cacheActor.cacheSearch(
				query: query,
				page: 1,
				books: response.documents,
				totalCount: response.meta.totalCount,
				isEnd: response.meta.isEnd
			)
			
			print("API 호출 완료 + 캐시 저장 - \(query) - \(response.documents.count)권")
			
			// ViewModel 업데이트
			searchResults = response.documents
			hasSearched = true
			currentPage = 1
			totalCount = response.meta.totalCount
			hasMorePages = !response.meta.isEnd
			
		} catch {
			print("\(query) 에 대한 검색 결과 없음")
		}
		
		// searching 종료
		isSearching = false
	}
	
	/// 추가 페이지 로드 (무한 스크롤 + 캐시) -> 이건 특정 조건이 충족되면 자동 작동
	///
	/// 실행 흐름
	/// 1. 중복 호출 방지 체크
	/// 2. 캐시 확인
	/// 	- Cache Hit: 즉시 (searchResults에) 추가
	/// 	- Cache Miss: API 호출 -> 캐시 저장
	/// 3. 기존 배열(searchResults)에 추가 (append)
	/// 4. 페이지네이션 상태 없데이트
	func loadMoreBooks() async {
		/*
		 1. 중복 호출 방지: 아래 조건이 모두 충족되어야 호출 함 ( 즉 뭔가 로딩 작업중이 아니고 페이지가 더 있을 떼)
			1) isLoadingMore == false 이고 (추가 페이지가 로딩 중이 아니며 -> loadMoreBooks가 실행중이 아니며)
			2) isSearching == false 이고 (지금 searchBooks가 실행 중이 아니며 아니며)
			3) hasMorePages == true 일 때 ( 찾아야 할 페이지가 아직 남아 있을 때 )
		*/
		guard !isLoadingMore && !isSearching && hasMorePages else { return }
		
		// 상태 설정
		print("SearchViewModel: 추가 페이지 로딩 시작")
		isLoadingMore = true
		
		// 다음 페이지 설정
		let nextPage = currentPage + 1
		
		// 캐시 확인 
		if let cached = await cacheActor.getCachedSearch(query: currentSearchQuery, page: nextPage) {
			print("캐시에서 추가 페이지 로드 \(currentSearchQuery) - \(nextPage) 페이지")
			
			// 기존 배열에 추가, 현재 페이지에 nextpage추가, 이 페이지가 마지막 장인지
			searchResults.append(contentsOf: cached.books)
			currentPage = nextPage
			hasMorePages = !cached.isEnd
			
			isLoadingMore = false
			return  // cache Hit이면 함수 종료
		}
		
		print("API 호출 - Cache Miss \(currentSearchQuery) - \(nextPage) 페이지")
		
		do {
			// API 호출
			let response = try await networkService.searchBooks(
				query: currentSearchQuery,
				page: nextPage,
				size: 20
			)
			
			// 캐시 저장
			await cacheActor.cacheSearch(
				query: currentSearchQuery,
				page: nextPage,
				books: response.documents,
				totalCount: response.meta.totalCount,
				isEnd: response.meta.isEnd
			)
			
			print("API 완료 + 캐시 저장 총\(searchResults.count + response.documents.count)권")
			
			// ViewModel 업데이트
			searchResults.append(contentsOf: response.documents)
			currentPage = nextPage
			hasMorePages = !response.meta.isEnd
		} catch {
			print("\(currentSearchQuery)의 검색 결과가 없습니다")
		}
		isLoadingMore = false
	}
}

// MARK: - Computed Properties
extension SearchResultsViewModel {
	
	// 검색 결과가 있는 지 여부
	var hasResults: Bool {
		!searchResults.isEmpty && hasSearched
	}
	
	// 빈 상태 표시 여부 (검색 결과 없음)
	var showEmptyState: Bool {
		searchResults.isEmpty && hasSearched && !isSearching
	}
	
	// 더보기 버튼 표시 여부
	var showLoadMoreButton: Bool {
		hasResults && hasMorePages && !isSearching && !isLoadingMore
	}
}
