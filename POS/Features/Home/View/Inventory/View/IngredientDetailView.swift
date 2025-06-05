//
//  IngredientDetailView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI

struct IngredientDetailView: View {
    
    @State var item: IngredientUsage
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Text("Ingredient Detail View")
    }
}
