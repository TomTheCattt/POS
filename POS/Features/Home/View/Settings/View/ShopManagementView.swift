import SwiftUI

extension View {
    func optimizedShadow() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        )
    }
}

struct ShopManagementView: View {
    @StateObject var viewModel: ShopManagementViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingSearchBar = false
    @State private var searchText = ""
    @State private var animateHeader = false
    
    var filteredShops: [Shop] {
        if searchText.isEmpty {
            return appState.sourceModel.shops ?? []
        }
        return (appState.sourceModel.shops ?? []).filter {
            $0.shopName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Group {
            if let shops = appState.sourceModel.shops, shops.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Chưa có cửa hàng nào")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Bạn hiện chưa có cửa hàng nào, tạo cửa hàng ngay")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button {
                        appState.coordinator.navigateTo(.addShop, using: .present, with: .present)
                    } label: {
                        Label("Tạo cửa hàng mới", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Enhanced Header
                    headerSection
                        .opacity(animateHeader ? 1 : 0)
                        .offset(y: animateHeader ? 0 : -20)
                    
                    // Search Bar
                    if showingSearchBar {
                        EnhancedSearchBar(
                            text: $searchText,
                            placeholder: "Tìm kiếm cửa hàng..."
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .padding()
                    }
                    
                    // Shops List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredShops) { shop in
                                ShopRow(shop: shop)
//                                    .onTapGesture {
//                                        viewModel.activatedShop = shop
//                                        appState.coordinator.navigateTo(.shopDetail)
//                                    }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Quản lý cửa hàng")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showingSearchBar.toggle()
                                }
                            }) {
                                Image(systemName: showingSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                                    .font(.title2)
                                    .foregroundStyle(.primary)
                            }
                            
                            Button {
                                appState.coordinator.navigateTo(.addShop, using: .present, with: .present)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                    }
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animateHeader = true
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("\(filteredShops.count) cửa hàng")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Decorative divider
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.6), .red.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .frame(maxWidth: 100)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
}

struct ShopRow: View {
    let shop: Shop
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Icon section với gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: shop.isActive ?
                                [.blue.opacity(0.8), .purple.opacity(0.8)] :
                                    [.gray.opacity(0.5), .gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: shop.isActive ? .blue.opacity(0.3) : .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Content section
                VStack(alignment: .leading, spacing: 6) {
                    Text(shop.shopName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        // Ground Rent
                        Label(shop.formattedGroundRent, systemImage: "banknote.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Created Date
                        Label(formatDate(shop.createdAt), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                if shop.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Đang hoạt động")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}
