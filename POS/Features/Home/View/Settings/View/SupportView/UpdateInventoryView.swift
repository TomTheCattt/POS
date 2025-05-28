//
//  UpdateInventoryView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct UpdateInventoryView: View {
    
    @ObservedObject var viewModel: InventoryViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Text("Inventory View")
    }
}

//#Preview {
//    UpdateInventoryView(viewModel: InventoryViewModel(environment: AppEnvironment()), coordinator: AppCoordinator())
//}
