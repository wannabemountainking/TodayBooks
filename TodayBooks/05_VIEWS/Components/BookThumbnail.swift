//
//  BookThumbnail.swift
//  TodayBooks
//
//  Created by yoonie on 5/16/26.
//

import SwiftUI

struct BookThumbnail: View {
    // MARK: - Properties
    let book: Book
    let width: CGFloat
    let height: CGFloat
    let showTitle: Bool
    
    init(book: Book = Book.mockList[0], width: CGFloat = 90, height: CGFloat = 130, showTitle: Bool = true) {
        self.book = book
        self.width = width
        self.height = height
        self.showTitle = showTitle
    }
    
    var body: some View {
        VStack(spacing: 10) {
            bookThumbnailImage // 도서 표시 이미지
            
            // 제목 표시 옵션에 따라 조건부 렌더링
            if showTitle {
                bookTitleText // 도서 제목 텍스트
            }
            
        } //:VSTACK
        .frame(width: width)   // 전체 컴포넌트의 너비를 지정된 값으로 고정
    }
}

// MARK: - 뷰 컴포넌트
extension BookThumbnail {
    /// 도서 표시 이미지 컴포넌트
    @ViewBuilder
    private var bookThumbnailImage: some View {
        ImageLoaderView(book.thumbnail)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(
                color: Color.bookDarkBrown.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.bookOrange.opacity(0.3), lineWidth: 1)
            }
    }
    
    // 도서 제목 텍스트 컴포넌트
    @ViewBuilder
    private var bookTitleText: some View {
        Text(book.title)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.bookDarkBrown)
            .lineLimit(2)
            .hCenter()
            .frame(width: width, height: 32)
            .background(.clear)
    }
}

// MARK: - 크기 변형들
extension BookThumbnail {
    /// 중간 크기 썸네일 (90*130) : MainView 카테고리 뷰, MyView 도서 목록
    static func medium(book: Book, showTitle: Bool = true) -> BookThumbnail {
        BookThumbnail(book: book, width: 90, height: 130, showTitle: showTitle)
    }
    
    /// 큰 크기 썸네일 (140 * 200) : DetailView에서 사용
    static func large(book: Book, showTitle: Bool = true) -> BookThumbnail {
        BookThumbnail(book: book, width: 140, height: 200, showTitle: showTitle)
    }
}

// MARK: - Grid 레이아웃
extension BookThumbnail {
    
    /// 3열 그리드 레이아웃
    @ViewBuilder
	static func grid(
		books: [Book],
		showTitle: Bool = true,
		onBookTapped: @escaping (Book) -> Void,
		onBookLongPressed: ((Book) -> Void)? = nil // 추가 롱프레스 콜백 - optional 이라서 기존 코드에서 수정 안해도 됨
	) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 15),
                GridItem(.flexible(), spacing: 15),
                GridItem(.flexible(), spacing: 15)
            ],
            spacing: 20,
            content: {
                ForEach(books) { book in
                    BookThumbnail.medium(book: book, showTitle: showTitle)
                        .onTapGesture {
                            onBookTapped(book)
                        }
					// 롱프레스: 길게 0.5초 길게 누르면 onBookLongPressed 클로져 실행
						.onLongPressGesture(minimumDuration: 0.5) {
							onBookLongPressed?(book)
						}
                }
            }
        )
    }
}

#Preview("썸네일 사이즈") {
    HStack(spacing: 20) {
        // 두 가지 크기 변형을 비교
        BookThumbnail.medium(book: Book.mockList[1]) // 중간 크기
        BookThumbnail.large(book: Book.mockList[0]) // 큰 크기
    } //:HSTACK
}

#Preview("그리드 레이아웃") {
    ScrollView {
        BookThumbnail.grid(books: Book.mockList) { book in
            print("Book 클릭")
        }
    }
}

