import SwiftUI

struct OrderItemView: View {
    
    @EnvironmentObject private var appState: AppState
    
    let orderItem: OrderItem
    let name: String
    let price: String
    let updateQuantity: (Bool) -> Void
    let updateNote: (String) -> Void
    
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
    }
    
    private func itemImage() -> some View {
        Image(systemName: "cup.and.saucer.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .cornerRadius(8)
            .foregroundColor(.blue)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    private func itemDetails() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
            Text(price)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func quantitySelector() -> some View {
        HStack(spacing: 12) {
            Button(action: { updateQuantity(false) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Text("\(orderItem.quantity)")
                .font(.headline)
                .frame(width: 30)
            
            Button(action: { updateQuantity(true) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func noteSection() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Temprature: \(orderItem.temperature), Consumption: \(orderItem.consumption)")
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
                Text(orderItem.note ?? "No note")
                    .font(.footnote)
                    .foregroundStyle(Color.gray)
            }
            Spacer()
            Button {
                appState.coordinator.navigateTo(.note(orderItem), using: .overlay, with: NavigationConfig(autoDismiss: false))
            } label: {
                Image(systemName: "note.text")
                    .foregroundStyle(Color.blue)
            }
        }
    }
} 
