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
    @FocusState private var textField: AppTextField?
    @State private var selectedQuickNote: String?
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
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
                        .foregroundColor(.primary)
                    Text(orderItem.name)
                        .font(.subheadline)
                        .foregroundColor(appState.currentTabThemeColors.primaryColor)
                }
                Spacer()
                Button {
//                    appState.coordinator.dismiss(style: .present)
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
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(noteText.count)/\(maxCharacterCount)")
                        .font(.caption)
                        .foregroundColor(noteText.count >= maxCharacterCount ? .red : .secondary)
                        .animation(.easeInOut, value: noteText.count)
                }
                .padding(.horizontal)
                
                // Text Editor
                TextEditor(text: Binding(
                    get: { noteText },
                    set: { noteText = String($0.prefix(maxCharacterCount)) }
                ))
                .keyboardType(.default)
                .focused($textField, equals: .note(.note))
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            textField != nil ?
                            appState.currentTabThemeColors.primaryColor :
                            Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                )
                .padding(.horizontal)
                
                // Quick Notes
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ghi chú nhanh", systemImage: "bolt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Không đường", "Ít đường", "Không đá", "Ít đá", "Không caffein", "Thêm đá"], id: \.self) { note in
                                let isSelected = selectedQuickNote == note
                                quickNoteButton(note)
                                    .foregroundStyle(isSelected ? Color.white : appState.currentTabThemeColors.primaryColor)
                                    .layeredSelectionButton(tabThemeColors: appState.currentTabThemeColors, isSelected: isSelected, namespace: animation, geometryID: "selected") {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if noteText.isEmpty {
                                                noteText = note
                                            } else {
                                                noteText += ", \(note)"
                                            }
                                            selectedQuickNote = note
                                            
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
//                            appState.coordinator.dismiss(style: .present)
                        } label: {
                            Text("Huỷ")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.systemGray3)
                                )
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            viewModel.updateOrderItemNote(for: orderItem.id, note: noteText.trimmingCharacters(in: .whitespacesAndNewlines))
//                            appState.coordinator.dismiss(style: .present)
                        } label: {
                            Text("Xác nhận")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(appState.currentTabThemeColors.gradient(for: colorScheme))
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
        .background(Color(.systemBackground))
        .onAppear {
            textField = .note(.note)
        }
    }
    
    private func quickNoteButton(_ note: String) -> some View {
        Text(note)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
    }
}
