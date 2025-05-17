//
//  ForgotPasswordView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        Text("We have sent an email to recover your account. Please check your mail box.")
            .multilineTextAlignment(.center)
            .bold()
            .ignoresSafeArea()
            .overlayStyle(config: .overlay) {
                coordinator.dismiss()
            }
    }
}
//
//#Preview {
//    ForgotPasswordView()
//}

