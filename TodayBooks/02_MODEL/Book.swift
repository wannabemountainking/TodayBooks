//
//  Book.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/14/26.
//

import Foundation

// MARK: - 카카오 도서 검색 API 응답 모델

/// API 응답 전체를 감싸는 레퍼 구조체
struct BookResponse: Codable {
	let documents: [Book] // 실제 도서 데이터 배열
	let meta: BookMeta // 검색 결과의 메타 데이터
}

/// 검색 결과의 메타 데이터를 담는 구조체: pagenation과 무한 스크롤을 사용하기 위해 활용
struct BookMeta: Codable {
	let pageableCount: Int // 전체 검색 결과 개수
	let totalCount: Int // 페이지네이션 가능한 문서 수
	let isEnd: Bool // 마지막 페이지 여부
	
	// Json 키와 Swift 프로퍼티 이름을 매핑(연결)
	enum CodingKeys: String, CodingKey {
		case pageableCount = "pageable_count"
		case totalCount = "total_count"
		case isEnd = "is_end"
	}
}

// MARK: - Book 모델
/// 카카오 도서 검색 API에서 받아오는 도서 정보 모델
struct Book: Identifiable, Codable, Equatable {
	// MARK: - Stored Properties
	let title: String // 도서 제목
	let contents: String // 도서 소개/설명
	let url: String // 도서 상세 페이지 URL
	let isbn: String // 도서 고유 번호(International Standard Book Number)
	let authors: [String] // 저자 목록 (배열인 이유: 공저자가 여럿일 수 있음)
	let publisher: String // 출판사
	let price: Int // 가격 (정수형, 원화 기준)
	let thumbnail: String // 표지 이미지 URL
	
	// MARK: - Computed Properties
	/// SwiftUI Identifiable 프로토콜을 위한 고유 ID
	var id: String {
		return isbn.isEmpty ? "\(title)_\(publisher)" : isbn
	}
	/// 문자열 URLK을 실제 URL 객체로 변환
	var thumbnailURL: URL? {
		return URL(string: thumbnail)
	}
	
	/// 저자 배열을 쉼표로 구분된 문자열로 변환 -> "홍길동, 제이콥"
	var authorsText: String {
		return authors.joined(separator: ", ")
	}
}
