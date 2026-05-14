//
//  NetworkError.swift
//  TodayBooks
//
//  Created by yoonie on 5/14/26.
//

import Foundation

/// 네트워크 에러 타입 커스텀 정의
enum NetworkError: Error, LocalizedError {
    case invalidURL    // 잘못된 URL - URL 생성 실패 시
    case noData        // 데이터 없음 = 서버에서 응답이 오지 않을 때
    case decodingError // JSON 파싱 에러 - 받은 데이터를 Swift 객체로 변환 실패 시
    case networkError  // 네트워크 연결 에로 - 인터넷 연결 문제, 타임아웃 등
    case serverError   // 서버 에러 - HTTP 상태 코드가 200이 아닌 경우 ( 4xx, 5xx)
    
    // MARK: - LocalizedError 프로토콜 필수 구현 프로퍼티
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"                // 개발자 실수로 발생하는 경우가 많음
        case .noData:
            return "데이터를 받을 수 없습니다"          // 서버가 응답하지 않거나 빈 응답을 보낼 때
        case .decodingError:
            return "데이터 처리 중 오류가 발생했습니다"   // JSON 구조가 예상과 다르거나 데이터가 손상된 경우
        case .networkError:
            return "네트워크 연결을 확인해주세요"        // 가장 흔한 에러 - 와이파이, 셀룰러 연결 문제
        case .serverError:
            return "서버에 문제가 발생했습니다"         // 서버 점검, 과부하, API 키 문제 등
        }
    }
}
