//
//  UpdateMenuView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct UpdateMenuView: View {
    
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Text("Update Menu View")
    }
}

#Preview {
    UpdateMenuView(viewModel: MenuViewModel(source: SourceModel()))
}
