//
//  CategoryHeaderView.swift
//  TodayBooks
//
//  Created by yoonie on 5/16/26.
//

import SwiftUI

/// 메인 화면의 각 카테고리 섹션 상단에 표시되는 헤더 컴포넌트
struct CategoryHeaderView: View {
    // MARK: - Properties
    let title: String      // 카테고리 제목
    let subTitle: String   // 부제목 (도서 개수)
    let icon: String       // 이미지
    
    init(title: String, subTitle: String, icon: String) {
        self.title = title
        self.subTitle = subTitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // 카테고리 아이콘
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.bookRed)
                .frame(width: 25, height: 25)
                .background(
                    Circle()
                        .fill(.bookRed.opacity(0.1))
                        .frame(width: 35, height: 35)
                )
            
            // 카테고리 제목과 부제목
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.bookDarkBrown)
                    .lineLimit(1)
                // 부제목
                Text(subTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.bookOrange)
            } //:VSTACK
            Spacer()
        } //:HSTACK
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        CategoryHeaderView(title: "베스트 셀러", subTitle: "20권", icon: "star.fill")
        CategoryHeaderView(title: "프로그래밍", subTitle: "15권", icon: "laptopcomputer")
        CategoryHeaderView(title: "자기개발", subTitle: "40권", icon: "person.fill")
    } //:VSTACK
}
