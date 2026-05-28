//
//  MyLibraryView.swift
//  TodayBooks
//
//  Created by yoonie on 5/27/26.
//

import SwiftUI
import SwiftData

/// 사용자가 저장한 (북마크한) 도서들을 관리하는 내 서재 화면
struct MyLibraryView: View {
    
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext // SwiftData 컨텍스트
    @Environment(\.dismiss) private var dismiss // 화면 닫기
    /// @Query는 SwiftData 자동 데이터 매칭 프로퍼티 래퍼임
    @Query private var myBooks: [MyBook] // @Query로 SwiftData 가져오기
    
    @State private var selectedBook: Book? // 선택된 도서: 상세보기 시트를 위한 옵셔널 상태
    @State private var showingDeleteAlert: Bool = false // 삭제 확인 알림
    @State private var bookToDelete: Book? // 삭제 대상 도서: 임시 저장으로 삭제 작업 안정성 확보
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Color
                Color.bookYellow.opacity(0.1)
                    .ignoresSafeArea()
                // Content
                VStack(spacing: 0) {
                    if myBooks.isEmpty {
                        emptyStateView
                    } else {
                        libraryContentView
                    }
                }
                
            } //:ZSTACK
            .navigationTitle("내 서재 (총 \(myBooks.count)권)")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Action
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.bookOrange)
                    }

                }
            } //:TOOLBAR
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book)
            }
			// alert 창
			.alert("책 삭제", isPresented: $showingDeleteAlert) {
				// 삭제버튼
				Button("취소", role: .cancel) {
					//Action
					bookToDelete = nil
				}
				Button("삭제", role: .destructive) {
					// Action
					if let book = bookToDelete {
						removeFromLibrary(book)
						bookToDelete = nil
					}
				}
			} message: {
				Text("이 책을 내 서재에서 삭제하시겠습니까?")
			}

        } //:NAVSTACK
    }
}

// MARK: - EXTENSION
extension MyLibraryView {
    
    /// 빈 상태 화면: 저장된 책이 없는 경우
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            // Label
            Label("아직 저장된 책이 없어요", systemImage: "books.vertical")
        } description: {  // 부가 설명 텍스트 영역
            Text("마음에 드는 책을 찾아서\n내 서재에 추가해 보세요")
        } actions: {      // 사용자 액션 버튼을 배치하는 영역
            Button {
                // Action
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                    
                    Text("책 찾으러 가기")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.vertical, 15)
                .padding(.horizontal, 25)
                .background(
                    LinearGradient(
                        colors: [.bookRed, .bookDarkBrown],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(15)
                )
            }
            .buttonStyle(.plain)
        }

    }
    
    /// 저장된 책을 보여주는 Content 영역
    @ViewBuilder
    private var libraryContentView: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                VStack(spacing: 15) {
					BookThumbnail.grid(
						books: myBooks.map { $0.asBook },
						onBookTapped: { book in
							selectedBook = book
						},
						// 롱프레스 시 삭제하고 alert 표시
						onBookLongPressed: { book in
							bookToDelete = book
							showingDeleteAlert = true
						}
					)
                } //:VSTACK
                .hLeading()
                .padding(.bottom, 40)
            } //:VSTACK
        } //:SCROLL
    }
	
	// Helper function
	/// 나의 책 삭제 로직
	private func removeFromLibrary(_ book: Book) {
		// SwiftData에 저장된 MyBook 배열에서 대상이 있는지 찾기
		if let myBookToDelete = myBooks.first(where: { myBook in
			myBook.title == book.title && myBook.authorsText == book.authorsText
		}) {
			// modelContext에서 해당 데이터를 삭제 (메모리에서 제거)
			modelContext.delete(myBookToDelete)
			do {
				// 변경 사항을 디스크에 저장
				try modelContext.save()
			} catch {
				print("저장 실패: \(error.localizedDescription)")
			}
		}
	}
}

/// 빈 상태 프리뷰
#Preview("MyLibraryView - Empty") {
    
    let emptyContainer: ModelContainer = {
        do {
            // 빈 메모리 컨테이너
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: MyBook.self, configurations: config)
            return container // 데이터를 추가하지 않고 빈 컨테이너 반환
        } catch {
            fatalError("Error: \(error)")
        }
    }()
    
    MyLibraryView()
        .modelContainer(emptyContainer)
}

/// 데이터가 있는 상태의 프리뷰
#Preview("MyLibraryView - with books") {
    // 메모리 전용 SwiftData 컨테이너
    let previewContainer = {
        do {
            // 메모리 전용 설정
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: MyBook.self, configurations: config)
            
            // 샘플데이터 추가
            let sampleBooks = Book.mockList
            for book in sampleBooks {
                let myBook = MyBook(from: book)
                container.mainContext.insert(myBook)
            }
            return container
        } catch {
            fatalError("Error: \(error)")
        }
    }()
    
    MyLibraryView()
        .modelContainer(previewContainer)
}
