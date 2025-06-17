//
//  ButtonLoadingLabel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 10/6/25.
//

import SwiftUI

struct ButtonLoadingLabel: View {
    
    @State private var loadingText: String
    
    init(loadingText: String) {
        self.loadingText = loadingText
    }
    
    var body: some View {
        HStack {
            Text(loadingText)
                .fontWeight(.semibold)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .padding(.trailing, 8)
        }
    }
}

#Preview {
    ButtonLoadingLabel(loadingText: "hehe")
}
