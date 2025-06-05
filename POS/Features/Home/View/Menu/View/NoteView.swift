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
    @State private var offset: CGFloat = 1000
    @State private var opacity: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @GestureState private var dragState = CGSize.zero
    
    private let maxCharacterCount = 200
    
    init(viewModel: OrderViewModel, orderItem: OrderItem) {
        self.viewModel = viewModel
        self.orderItem = orderItem
        self._noteText = State(initialValue: orderItem.note ?? "")
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Drag Indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                
                // Header
                HStack {
                    Text("Ghi chú cho món")
                        .font(.headline)
                    Text(orderItem.name)
                        .font(.headline)
                        .foregroundColor(.blue)
                    Spacer()
                    Button {
                        dismissWithAnimation()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding()
                
                Divider()
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Character count
                    HStack {
                        Text("Ghi chú đặc biệt, yêu cầu riêng...")
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
                    .frame(height: 100)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextFieldFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Quick Notes
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Không đường", "Ít đường", "Không đá", "Ít đá", "Không caffein", "Thêm đá"], id: \.self) { note in
                                QuickNoteButton(note: note) {
                                    if noteText.isEmpty {
                                        noteText = note
                                    } else {
                                        noteText += ", \(note)"
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 12) {
                        Divider()
                        
                        HStack(spacing: 16) {
                            Button {
                                dismissWithAnimation()
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
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button {
                                hapticFeedback()
                                viewModel.updateOrderItemNote(for: orderItem.id, note: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
                                dismissWithAnimation()
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
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .overlayStyle(
                config: NavigationConfig(
                    isAnimated: true,
                    dismissOnTapOutside: true,
                    backgroundEffect: .dim(opacity: 0.5),
                    overlaySize: .medium,
                    customAnimation: .spring(response: 0.3, dampingFraction: 0.8),
                    enableDragToDismiss: true
                ),
                onDismiss: {
                    dismissWithAnimation()
                }
            )
            .offset(y: offset)
            .opacity(1 - opacity)
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        let translation = value.translation.height
                        state = CGSize(width: 0, height: translation)
                    }
                    .onEnded { value in
                        let height = value.translation.height
                        if height > 100 {
                            dismissWithAnimation()
                        }
                    }
            )
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                    opacity = 0
                }
            }
        }
    }
    
    // MARK: - Animation Methods
    private func showWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            opacity = 1
        }
        isTextFieldFocused = true
    }
    
    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 1000
            opacity = 0
        }
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            appState.coordinator.dismiss(style: .overlay)
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Supporting Views
struct QuickNoteButton: View {
    let note: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(note)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                )
                .foregroundColor(.blue)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
