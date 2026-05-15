//
//  KakaoBookService.swift
//  TodayBooks
//
//  Created by yoonie on 5/14/26.
//

import Foundation


/// 카카오 도서 검색 API 서비스 클래스
final class KakaoBookService {
    
    /// Singleton Pattern
    static let shared = KakaoBookService()
    
    // 보안이 취약한 코드: API 키 그대로 노출
//    private let apiKey: String = "e37bda64f200f2bad5d8e4f6177734e0"
	
	// 보안 강화: Info.plist 에서 설정한 키 가져오기
	// Bundle.main.infoDictionary: 앱의 Info.plist 파일에 자장된 설정값들에 접근
	private let apiKey: String = {
		guard let key = Bundle.main.infoDictionary?["KAKAO_API_KEY"] as? String else {
			return "인증키가 잘못되었습니다"
		}
		return key
	}()  // 클로저를 즉시 실행하여 앱 시작시 API키를 한 번만 로드
    
	/// API 기본 URL
    private let basicURL: String = "https://dapi.kakao.com/v3/search/book"
    
	/// 싱글톤 패턴을 강제하기 위해 외부에서 새로운 인스턴스 생성을 막음
    private init() { }
	
	// MARK: - Search Books
	func searchBooks(query: String, page: Int = 1, size: Int = 10) async throws -> BookResponse {
		guard let url = createURL(query: query, page: page, size: size) else {
			throw NetworkError.invalidURL  // URL 생성 실패시 에러 던지기
		}
		
		// URLRequest: 단수 URL 보다 더 세밀한 HTTP 설정 가능 -> 여기에 인증키 적용이 됨.
		var request = URLRequest(url: url)
		request.httpMethod = "GET"  // HTTP GET 메서드 사용 (데이터 조회 용)
		
		// 카카오 API는 인증된 사용자만 접근할 수 있도록 키 검증 요구 "KakaoAK" 접두사는 카카오에서 정한 인증방식
		request.setValue("KakaoAK \(self.apiKey)", forHTTPHeaderField: "Authorization")
		
		// 외부 do-catch: 전체 네트워크 요청의 에러 처리
		do {
			// URLSession.shared.data(for: URLRequest) : async / await 데이터 요청 메서드
			let (data, response) = try await URLSession.shared.data(for: request)
			// HTTP 상태 코드를 확인 -> 200 상태 코드만 정상적인 성공 응답
			guard let httpResponse = response as? HTTPURLResponse,
				  httpResponse.statusCode == 200 else {
				throw NetworkError.serverError  // 서버 에러
			}
			
			// 내부 do-catch: Json 파싱 에러와 네트워크 에러를 구분하기 위함
			// JSONDecoder 사용해서 JSON -> Swift 객체로 자동 변환해줌
			do {
				return try JSONDecoder().decode(BookResponse.self, from: data)
			} catch {
				throw NetworkError.decodingError // Json 파싱 실패
			}
		} catch let error as NetworkError { // 이미 NetworkError
			throw error
		} catch {
			throw NetworkError.networkError // 기타 에러는 네트워크 에러로 통합
		}
	}
}

private extension KakaoBookService {
	/// URL 생성 메서드
	func createURL(query: String, page: Int, size: Int) -> URL? {
		
		// URLComponents: 문자열 연결보다 안전하고 정확한 URL 생성 가능
		var components = URLComponents(string: self.basicURL)
		// URLQueryItem: URL의 쿼리 파라미터를 나타내는 구조체 (name=value 형태)
		components?.queryItems = [
			URLQueryItem(name: "query", value: query),     // 검색어
			URLQueryItem(name: "page", value: String(page)),  // 페이지 번호
			URLQueryItem(name: "size", value: String(size))   // 결과 갯수
		]
		
		// 최종 URL 반환 (실패 시 nil)
		// 예시 결과: "https://dapi.kakao.com/v3/search/book?query=SwiftUI&page=1&size=10"
		return components?.url
	}
}
