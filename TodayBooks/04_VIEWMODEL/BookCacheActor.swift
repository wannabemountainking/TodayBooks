//
//  BookCacheActor.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/16/26.
//

import Foundation

// MARK: - 캐시 데이터 구조
/// 캐시된 결과를 담는 구조체
struct CacheResult {
	let books: [Book]     // 도서 배열
	let totalCount: Int   // 전체 결과 수 (API의 meta.totalCount)
	let isEnd: Bool       // 마지막 페이지 여부 (API의 meta.isEnd)
	let timeStamp: Date   // 캐시 저장 시각 (만료시간 계산용)
}

// MARK: - 캐시 전담 관리 Actor
/// 스레드면에서 안전한 (ThreadSafe) 캐시 관리 Actor
///
/// Actor 의 역할
/// - API 응답을 메모리에 캐싱하여 중복 호출 방지
/// - 여러 ViewModel이 동시에 접근해도 스레드 안전하게 관리
/// - 캐시 만료 시간(TTL) 관리로 오래된 데이터 자동 제거
///
/// 왜 Actor 인가?
/// - 여러 스레드에서 동시 접근 가능
/// - Actor가 자동으로 접근을 직렬화함 (순차 처리)
/// - 데이터 레이스(data racing) 조건 완벽 방지
///
/// 🔄 Actor 캐시와의 협업 구조
/// ┌─────────────┐  1. 요청    ┌──────────┐
/// │  ViewModel  │ ─────────→ │  Actor   │
/// │ (메인 스레드)  |            │ (캐시)    │
/// └─────────────┘            └──────────┘
///       ↑                          ↓
///       │                     2. 캐시 확인
///       │                          ↓
///       │                    Cache Hit?
///       │                     ↙        ↘
///       │               YES (즉시)   NO
///       │                 ↓            ↓
///       │            캐시 반환      ┌──────────┐
///       │                 ↓       │ Service  │
///       │                         │   (API)  │
///       │                         └──────────┘
///       │                               ↓
///       │                          3. 캐시 저장
///       │                               ↓
///       └───────────────────────────────┘
///              4. ViewModel 업데이트 + UI 갱신

/// Thread safe 한 캐시 관리를 위한 Actor
// actor를 singleton으로 구성한 이유 : 싱글톤으로 만들면 여러 곳에서 참조가 일어날 수 있어서 경쟁상태 유발. 이를 해결하기 위해 actor 사용(직렬화로 경쟁상태 미연에 방지)
actor BookDataActor {
	
	// MARK: - 싱글톤 패턴
	// 하나의 캐시만 유지하게 하는 단일 인스턴스 == 싱글톤
	static let shared = BookDataActor()
	
	// 외부에서 새 인스턴스 생성 방지
	private init() { }
	
	// MARK: - Cache Storage
	
	/// 검색결과 캐시 (searchCache)
	///
	/// 	Dictionary 구조
	/// 		- Key: "검색어_page페이지번호" (예: "Swift_page1")
	/// 		- Value: CacheResult (도서배열 + 메타데이터 + 타임스템프)
	/// 	저장 예시
	/// 		["Swift_page1" : CacheResult(books: [...], ...)]
	/// 		["자기개발_page2" : CacheResult(books: [...], ...)]
	///
	/// 카테고리 결과 캐시 (categoryCache)
	///
	/// 	Dictionary 구조
	/// 		- Key: "카테고리명_page페이지번호" (예: "프로그래밍_page1")
	/// 		- Value: CacheResult
	/// 	검색 캐시와 분리한 이유
	/// 		- 카테고리는 고정된 6개만 (히트율 높음)
	/// 		- 검색은 사용자 입력 (다양함)
	/// 		- 분리하면 관리가 명확해짐
	/// 	저장 예시
	/// 		["프로그래밍_page1": CacheResult(books: [...], ...)]
	///			["소셜_page1": CacheResult(books: [...], ...)]
	///
	///	캐시 만료시간 TTL: Time To Live - 10분 설정 (cacheExpiration)
	
	private var searchCache: [String: CacheResult] = [:]
	private var categoryCache: [String: CacheResult] = [:]
	private let cacheExpiration: TimeInterval = 600 // 600초 == 10분
	
	// MARK: - 검색결과 캐싱
	/// 검색결과 가져오기 (캐시 우선)
	///
	/// 실행 흐름 (3단계)
	/// 	1. 캐시 키 생성: "검색어_page페이지번호"
	/// 	2. Dictionaryh에서 캐시 조회
	/// 	3. 캐시가 있으면:
	/// 		a. 만료 시간 확인 (현재 시각 - 저장 시간)
	/// 		b. 만료되었으면: 삭제 후 nil
	/// 		c. 유효하면: 캐시 반환
	/// 	4. 캐시가 없으면: nil 반환
	///
	/// 	Cache Hti vs Cache Miss
	/// 		- Cache Hit: 캐시에서 찾음 (0.01초, 빠름!)
	/// 		- Cache Miss: 캐시에 없음 (API 호출 필요, 1초)
	///
	/// 	성능 비교
	/// 		- Cache Hit: 100 배 빠름
	/// 		- 네트워크 비용 절약
	
	// READ (search)
	/// 검색결과 가져오는 함수
	func getCachedSearch(query: String, page: Int) -> CacheResult? {
		// 1단계: 캐시 키 생성
		// 예: query="Swift", page=1 ->"Swift_page1"
		let cacheKey = "\(query)_page\(page)"
		
		// 2단계: 캐시 조회
		guard let cached = searchCache[cacheKey] else {
			// Cache 값 없음 -> Missing Cache
			return nil // nil 반환 -> ViewModel에서 API 호출 넘어감
		}
		
		// 3단계: 캐시 만료 확인
		// 예: 현재 12:10:00 -> 저장시각 12:05:00 -> 300초 경과
		let elapsedTime = Date().timeIntervalSince(cached.timeStamp)
		
		// 경과 시간이 만료 시간 (600초)를 초과했는지 확인
		if elapsedTime > cacheExpiration {
			// 만료된 캐시 처리
			
			// 1. Dictionary에서 만료된 캐시만 삭제
			searchCache.removeValue(forKey: cacheKey)
			// 2. ViewModel API 호출
			return nil
		}
		
		// 4단계: 유효한 캐시 반환 -> Cache Hit!
		return cached // API 호출 없이 바로 ViewMode3l이 즉시 데이터 사용
	}
	
	// CREATE (SAVE) (search)
	/// 검색 결과를 캐시에 저장
	///
	/// 실행 시점
	/// - ViewModel이 API 호출 완료 후
	/// - Missing Cache 이후 데이터를 받을 때
	/// - 다음 같은 검색을 위해 저장
	func cacheSearch(query: String, page: Int, books: [Book], totalCount: Int, isEnd: Bool) {
		// 1단계: 캐시 키 생성
		// 예: query="Swift", page=1 ->"Swift_page1"
		let cacheKey = "\(query)_page\(page)"
		
		// 2단계: Dictionary 에 저장
		searchCache[cacheKey] = CacheResult(
			books: books,
			totalCount: totalCount,
			isEnd: isEnd,
			timeStamp: Date()  // 현재 시각 저장
		)
	}
	
	// MARK: - 카테고리 캐싱 함수
	// READ (category)
	/// 검색결과 가져오는 함수
	func getCachedCategory(_ category: String, page: Int) -> CacheResult? {
		// 1단계: 캐시 키 생성
		// 예: query="Swift", page=1 ->"Swift_page1"
		let cacheKey = "\(category)_page\(page)"
		
		// 2단계: 캐시 조회
		guard let cached = categoryCache[cacheKey] else {
			// Cache 값 없음 -> Missing Cache
			return nil // nil 반환 -> ViewModel에서 API 호출 넘어감
		}
		
		// 3단계: 캐시 만료 확인
		// 예: 현재 12:10:00 -> 저장시각 12:05:00 -> 300초 경과
		let elapsedTime = Date().timeIntervalSince(cached.timeStamp)
		
		// 경과 시간이 만료 시간 (600초)를 초과했는지 확인
		if elapsedTime > cacheExpiration {
			// 만료된 캐시 처리
			
			// 1. Dictionary에서 만료된 캐시만 삭제
			categoryCache.removeValue(forKey: cacheKey)
			// 2. ViewModel API 호출
			return nil
		}
		
		// 4단계: 유효한 캐시 반환 -> Cache Hit!
		return cached // API 호출 없이 바로 ViewMode3l이 즉시 데이터 사용
	}
	
	// CREATE (SAVE) (category)
	/// 검색 결과를 캐시에 저장
	///
	/// 실행 시점
	/// - ViewModel이 API 호출 완료 후
	/// - Missing Cache 이후 데이터를 받을 때
	/// - 다음 같은 검색을 위해 저장
	func cacheCategory(_ category: String, page: Int, books: [Book], totalCount: Int, isEnd: Bool) {
		// 1단계: 캐시 키 생성
		// 예: category="Swift", page=1 ->"Swift_page1"
		let cacheKey = "\(category)_page\(page)"
		
		// 2단계: Dictionary 에 저장
		categoryCache[cacheKey] = CacheResult(
			books: books,
			totalCount: totalCount,
			isEnd: isEnd,
			timeStamp: Date()  // 현재 시각 저장
		)
	}
}
