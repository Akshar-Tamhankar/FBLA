//
//  SectionTitle.swift
//  FBLA
//
//  Created by Akshar Tamhankar on 1/6/26.
//


// UI/SectionTitle.swift
import SwiftUI

struct SectionTitle: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

