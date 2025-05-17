//
//  PrinterViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import Foundation
import Combine

final class PrinterViewModel: BaseViewModel {
    let environment: AppEnvironment
    
    var cancellables = Set<AnyCancellable>()
    
    var isLoading: Bool = false
    
    var errorMessage: String?
    
    var showError: Bool = false
    
    required init(environment: AppEnvironment) {
        self.environment = environment
    }
}
