//
//  MyLibraryViewModel.swift
//  TodayBooks
//
//  Created by YoonieMac on 5/27/26.
//

import Foundation
import SwiftData
import Observation


/// 사용자가 북마크한 도서들의 CRUD 작업을 관리하는 ViewModel
@MainActor
@Observable
final class MyLibraryViewModel {
	
	// MARK: - Properties
	/// SwiftData 모델 컨텍스트 (데이터베이스 연결) -> 처음 vm이 만들어질 때 모델 컨텍스트가 없는 상태 이기때문
	private var modelContext: ModelContext?
	
	/// 읽기 전용으로 저장된 도서 목록 (읽기 전용)
	/// 외부 (여기서는 View) 에서는 읽기만 가능함: let books = viewModel.myBooks 가능
	/// 쓰기 경우에는 내부 (여기서는 ViewModel) 에서만 사용하게끔 set
	private(set) var myBooks: [MyBook] = []
	
	/// 로딩 상태 (데이터베이스에서 읽어오는 중...)
	private(set) var isLoading = false
	
	/// DB 작업 실패 시 사용할 에러 메시지
	private(set) var errorMessage: String?
	
	/// 초기 데이러 로드
	///
	/// 실행 흐름
	/// 1. modelContext 저장 (DB 연결 설정)
	/// 2. loadBooks() 호출로 기존 북마크들(내 서재에 저장된 도서 목록)을 불러오기
	/// 3. UI 자동 업데이트
	///
	/// 호출 시점
	/// View의 .onAppear 에서 호출
	func setModelContext(context: ModelContext) {
		self.modelContext = context
		loadBooks() // 컨텍스트 설정 후 즉시 데이터 로드
	}
	
	// MARK: - CRUD 작업
	
	/// READ: SwfitData에서 모든 저장된 도서 불러오기
	/// 실행 흐름
	/// 1. 컨텍스트 확인 (없으면 중단)
	/// 2. 로딩 상태 시작 (isLoading = true)
	/// 3. FetchDescriptor로 DB 쿼리 실행
	/// 4. 결과를 myBooks에 저장
	/// 5. 성공 / 실패 여부에 따라 상태 업데이트
	func loadBooks() {
		// 1. 컨텍스트 확인 - 없으면 DB 작업 불가능
		guard let context = modelContext else { return }
		// 2. 로딩 상태 시작
		isLoading = true   // 로딩 시작 알림
		errorMessage = nil // 이전 에러 초기화
		
		// 3. FetchDescriptor로 데이터 불러오기
		do {
			/// FetchDescriptor: MyBook 테이블에서 모든 데이터를 datgaAdded 순으로 가져와 (SortDescriptor랑 비슷)
			let descriptor = FetchDescriptor<MyBook>(sortBy: [SortDescriptor(\.dateAdded, order: .reverse)])
			// DB 데이터 읽기 (== myBooks에 저장하기)
			myBooks = try context.fetch(descriptor)
		} catch {
			// DB 읽기 실패 (myBooks 저장 실패)
			errorMessage = "책 목록을 불러올 수 없습니다: \(error.localizedDescription)"
		}
		
		isLoading = false // 로딩 완료
	}
	
	/// CREATE: 도서를 라이브러리에 추가하기
	/// 실행 흐름
	///
	/// 1. 컨텍스트 확인
	/// 2. 중복 체크 (이미 북마크되어 있는지)
	/// 3. Book -> MyBook 변환 (API 모델 -> DB 모델)
	/// 4. DB에 삽입 (context.insert)
	/// 5. 변경 사항 저장 (context.save)
	/// 6. 목록 새로고침 (UI업데이트)
    func addBook(book: Book) {
        // 1. 컨텍스트 확인
        guard let context = modelContext else {return}
        
        // 2. 중복 체크 - 이미 북마크 된 책인지 확인
        if isBookmarked(book: book) {
            // True: 이미 북마크 되어 있음
            errorMessage = "이미 라이브러리에 추가된 책입니다"
            return
        }
        
        do {
            // 3. Book -> MyBook 변환
            let myBook = MyBook(from: book)
            
            // 4. DB에 새 데이터 삽입
            context.insert(myBook)
            
            // 5. 변경 사항을 디스크에 영구 저장
            try context.save()
            
            // 6. 목록 새로 고침
            loadBooks()
        } catch {
            // 저장 실패
            errorMessage = "책 추가에 실패했습니다: \(error.localizedDescription)"
        }
    }
    
    /// DELETE: 라이브러리에서 도서 삭제
    ///
    /// 실행 흐름
    /// 1. 컨텍스트 확인
    /// 2. FetchDescriptor + Predicate 으로 삭제할 도서 찾기
    /// 3. DB에서 삭제 (context.delete)
    /// 4. 변경 사항 저장 (context.save)
    /// 5. 목록 새로 고침
    func removeBook(book: Book) {
        // 1. 컨텍스트 확인
        guard let context = modelContext else {return}
        
        // 2. FetchDescriptor + Predicate 으로 삭제할 도서 찾기
        do {
            // 삭제할 도서 찾기 - ISBN 기준
            // #Predicate: myBooks 중에서 isbn이 일치하는 것을 찾아라
            let descriptor = FetchDescriptor<MyBook>(predicate: #Predicate { myBook in
                myBook.isbn == book.isbn
            })
            
            // 찾아온 결과물을 가져오기, isbn은 유일하기 때문에 0개 또는 1개
            if let myBook = try context.fetch(descriptor).first {
                // 3. DB에서 삭제
                context.delete(myBook)
                // 4. 변경사항 저장
                try context.save()
                // 5. 목록 새로 고침
                loadBooks()
            } else {
                print("MyLibraryViewModel 삭제할 책을 찾을 수 없음")
            }
        } catch  {
            // 삭제 실패 - 에러처리
            errorMessage = "책 삭제를 실패했습니다: \(error.localizedDescription)"
        }
        
    }
    
    
    // MARK: - Helper Methods
    
    /// 도서가 북마크 되어 있는지 안되어 있는지 확인하는 메서드 -> myBooks에 이 도서가 있는지 없는지 확인하는 메서드
    /// 북마크가 되어 있으면 true, 아니면 false
    func isBookmarked(book: Book) -> Bool {
        return myBooks.contains { myBook in
            myBook.isbn == book.isbn
        }
    }
	
	/// 북마크 상태 토글 (추가 / 삭제 자동 전환)
	func toggleBookmark(book: Book) {
		if isBookmarked(book: book) {
			removeBook(book: book) // 이미 북마크 되어 있으면 -> 삭제
		} else {
			addBook(book: book) // 북마크가 안 되어있으면 -> 추가
		}
	}
	
	/// 저장된 도서가 있는지 확인하는 property
	var hasBooks: Bool {
		return !myBooks.isEmpty
	}
	
	/// 에러 메시지 초기화
	func clearError() {
		errorMessage = nil
	}
}
