//
//  VerifyEmailSentView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import SwiftUI

struct VerifyEmailSentView: View {
    
    @State private var showPopUp: Bool = false
    @State private var errorMessage: String = ""
    
    private let validationStrings = ValidationLocalizedString()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(validationStrings.verifyEmailSent)
                    .font(Font.largeTitle.bold())
                    .textCase(Text.Case.uppercase)
                    .padding(.bottom)
                    .multilineTextAlignment(.center)
                Text(validationStrings.verifyEmailSentContent)
                    .font(Font.title2)
                    .padding(.bottom)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: UIDevice.current.is_iPhone ? geometry.size.width : geometry.size.width / 1.5)
            .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
        }
        
        if showPopUp {
            VStack {
                Spacer().frame(height: 60)
                Text(errorMessage)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    .shadow(radius: 10)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showPopUp = false
                            }
                        }
                    }
                Spacer()
            }
            .transition(.opacity)
            .animation(.easeInOut, value: showPopUp)
        }
    }
}

#Preview {
    VerifyEmailSentView()
}
