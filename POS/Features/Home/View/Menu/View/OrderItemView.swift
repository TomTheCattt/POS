import SwiftUI

struct OrderItemView: View {
    
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false
    
    let orderItem: OrderItem
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                itemImage()
                itemDetails()
                Spacer()
                quantitySelector()
            }
            noteSection()
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { isHovered in
            self.isHovered = isHovered
        }
    }
    
    private func itemImage() -> some View {
        Image(systemName: "cup.and.saucer.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .foregroundColor(.blue)
            .padding(8)
            .background(Color.white)
            .cornerRadius(8)
    }
    
    private func itemDetails() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(orderItem.name)
                .font(.headline)
                .foregroundColor(.primary)
            Text("\(orderItem.price)")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
    }
    
    private func quantitySelector() -> some View {
        HStack(spacing: 12) {
            Button(action: { 
                withAnimation(.spring()) {
                    viewModel.updateOrderItemQuantity(for: orderItem.id, increment: false)
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("\(orderItem.quantity)")
                .font(.headline)
                .frame(width: 30)
                .foregroundColor(.primary)
            
            Button(action: { 
                withAnimation(.spring()) {
                    viewModel.updateOrderItemQuantity(for: orderItem.id, increment: true)
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(8)
    }
    
    private func noteSection() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Temperature
                    HStack(spacing: 4) {
                        Image(systemName: "thermometer")
                            .foregroundStyle(Color.orange)
                        Text(orderItem.temperature.rawValue)
                            .foregroundStyle(Color.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                    
                    // Consumption
                    HStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer")
                            .foregroundStyle(Color.purple)
                        Text(orderItem.consumption.rawValue)
                            .foregroundStyle(Color.purple)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(Capsule())
                }
                .font(.footnote)
                
                // Note section if exists
                if let note = orderItem.note, !note.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .foregroundStyle(Color.blue)
                        Text(note)
                            .font(.footnote)
                            .foregroundStyle(Color.blue)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            Spacer()
            Button {
                appState.coordinator.navigateTo(.note(orderItem), using: .present, with: .present)
            } label: {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(Color.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 8)
    }
} 
