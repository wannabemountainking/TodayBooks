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
    
    private let endpoint: String = "https://dapi.kakao.com/v3/search/book"
    
    private init() { }
}
