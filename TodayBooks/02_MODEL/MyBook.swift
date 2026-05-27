//
//  MyBook.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/27/26.
//

import Foundation
import SwiftData

/// 사용자가 북마크한 도서를 로컬에 저장하기 위한 SwiftData 모델 - 이 모델은 자동으로 Observable이 됨
@Model
final class MyBook {
	// MARK: - 저장 프로퍼티 들
	var title: String // 도서 제목
	var contents: String // 도서 소개/설명
	let url: String // 도서 상세 페이지 URL
	var isbn: String // 도서 고유 번호(International Standard Book Number)
	var authors: [String] // 저자 목록 (배열인 이유: 공저자가 여럿일 수 있음)
	var publisher: String // 출판사
	var price: Int // 가격 (정수형, 원화 기준)
	var thumbnail: String // 표지 이미지 URL
	var dateAdded: Date // 도서를 내 서재에 추가한 날짜 (Book 모델에는 없는 추가 정보)
	
	// MARK: - INIT
	// SwiftData 클래스는 모든 프로퍼티를 초기화하는 생성자가 반드시 필요
	init(title: String, contents: String, url: String, isbn: String, authors: [String], publisher: String, price: Int, thumbnail: String) {
		self.title = title
		self.contents = contents
		self.url = url
		self.isbn = isbn
		self.authors = authors
		self.publisher = publisher
		self.price = price
		self.thumbnail = thumbnail
		self.dateAdded = Date() // 현재 시간을 자동으로 설정
	}
	
	// MARK: - 편의 생성자 (Convenience Init)
	/// Book 객체 (API 에서 받은 데이터를) Mybook 객체 (로컬 저장용)으로 쉽게 변환
	/// 사용자가 북마크 버튼을 눌렀을 때 Book -> MyBook 변환이 간단해짐
	convenience init(from book: Book) {
		self.init(
			title: book.title,
			contents: book.contents,
			url: book.url,
			isbn: book.isbn,
			authors: book.authors,
			publisher: book.publisher,
			price: book.price,
			thumbnail: book.thumbnail
		)
		// dateAdded는 지정 초기 생성자 에서 자동으로 현재시간으로 설정됨
	}
}

extension MyBook {
	/// 문자열 URLK을 실제 URL 객체로 변환
	var thumbnailURL: URL? {
		return URL(string: thumbnail)
	}
	
	/// 저자 배열을 쉼표로 구분된 문자열로 변환 -> "홍길동, 제이콥"
	var authorsText: String {
		return authors.joined(separator: ", ")
	}
	
	/// MyBook -> Book 으로 다시 API 모델로 변환하는 계산 프로퍼티
	var asBook: Book {
		return Book(
			title: self.title,
			contents: self.contents,
			url: self.url,
			isbn: self.isbn,
			authors: self.authors,
			publisher: self.publisher,
			price: self.price,
			thumbnail: self.thumbnail
		)
		// 주의: dateAdded는 Book 모델에 없으므로 변환 시 제외
	}
}
