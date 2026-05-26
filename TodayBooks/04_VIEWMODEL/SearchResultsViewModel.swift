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
}
