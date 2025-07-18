//
//  LanguageView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct LanguageView: View {

    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Select Language")
                .font(.largeTitle.bold())
                .padding(.top)

            ForEach(AppLanguage.allCases, id: \.self) { language in
                
            }

            Spacer()
        }
        .padding()
    }
}

enum AppLanguage: String, CaseIterable {
    case english
    case vietnamese

    var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }

    var iconName: String {
        switch self {
        case .english: return "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
        case .vietnamese: return "🇻🇳"
        }
    }
}


//#Preview {
//    LanguageView(
//        viewModel: SettingsViewModel(environment: AppEnvironment()),
//        coordinator: AppCoordinator()
//    )
//}
