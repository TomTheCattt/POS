//
//  NoteView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI

struct NoteView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject var appState: AppState
    let orderItem: OrderItem
    @State private var noteText: String
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedQuickNote: String?
    
    private let maxCharacterCount = 200
    
    init(viewModel: OrderViewModel, orderItem: OrderItem) {
        self.viewModel = viewModel
        self.orderItem = orderItem
        self._noteText = State(initialValue: orderItem.note ?? "")
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ghi chú cho món")
                        .font(.headline)
                    Text(orderItem.name)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                Spacer()
                Button {
                    appState.coordinator.dismiss(style: .present)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            Divider()
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Character count
                HStack {
                    Label("Ghi chú đặc biệt, yêu cầu riêng...", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(noteText.count)/\(maxCharacterCount)")
                        .font(.caption)
                        .foregroundColor(noteText.count >= maxCharacterCount ? .red : .gray)
                        .animation(.easeInOut, value: noteText.count)
                }
                .padding(.horizontal)
                
                // Text Editor
                TextEditor(text: Binding(
                    get: { noteText },
                    set: { noteText = String($0.prefix(maxCharacterCount)) }
                ))
                .keyboardType(.default)
                .focused($isTextFieldFocused)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTextFieldFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                
                // Quick Notes
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ghi chú nhanh", systemImage: "bolt")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Không đường", "Ít đường", "Không đá", "Ít đá", "Không caffein", "Thêm đá"], id: \.self) { note in
                                QuickNoteButton(
                                    note: note,
                                    isSelected: selectedQuickNote == note
                                ) {
                                    withAnimation(.spring()) {
                                        if noteText.isEmpty {
                                            noteText = note
                                        } else {
                                            noteText += ", \(note)"
                                        }
                                        selectedQuickNote = note
                                        
                                        // Reset selection after delay
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            selectedQuickNote = nil
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 16) {
                        Button {
                            appState.coordinator.dismiss(style: .present)
                        } label: {
                            Text("Huỷ")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            hapticFeedback()
                            viewModel.updateOrderItemNote(for: orderItem.id, note: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                            appState.coordinator.dismiss(style: .present)
                        } label: {
                            Text("Xác nhận")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue)
                                )
                                .foregroundColor(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    // MARK: - Animation Methods
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Supporting Views
struct QuickNoteButton: View {
    let note: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(note)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : (isHovered ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1)))
                )
                .foregroundColor(isSelected ? .white : .blue)
                .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHovered = isHovered
            }
        }
    }
}

// MARK: - Button Style
//struct PlainButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.95 : 1)
//            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
//    }
//}
