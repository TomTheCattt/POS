//
//  PrinterView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct PrinterView: View {
    
    @ObservedObject var viewModel: PrinterViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Text("Printer View")
    }
}

//#Preview {
//    PrinterView(viewModel: PrinterViewModel(environment: AppEnvironment()), coordinator: AppCoordinator())
//}
