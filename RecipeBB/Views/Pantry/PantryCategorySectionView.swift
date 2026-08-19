//
//  PantryCategorySectionView.swift
//  RecipeBB
//
//  Created by Jay Hui on 24/10/2025.
//

import SwiftUI

struct PantryCategorySectionView: View {
    let category: PantryCategory?
    let items: [PantryItem]
    let editingItem: PantryItem?
    @Binding var editName: String
    @Binding var editQuantity: String
    let isInputFocused: FocusState<Bool>.Binding
    let onStartEdit: (PantryItem) -> Void
    let onSaveEdit: (PantryItem) -> Void
    let onCancelEdit: () -> Void
    let onDrop: ([UUID], PantryCategory?) -> Void
    let onDelete: (PantryItem) -> Void

    @State private var swipedItemId: UUID?
    @State private var dragOffset: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let deleteButtonWidth: CGFloat = 90

    var categoryName: String {
        category?.name ?? String(localized: "Uncategorized")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(categoryName)
                    .sectionHeaderStyle()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .appBackground()
            .dropDestination(for: String.self) { droppedIds, _ in
                let uuids = droppedIds.compactMap { UUID(uuidString: $0) }
                onDrop(uuids, category)
                return true
            }

            // Items
            VStack(spacing: 0) {
                if items.isEmpty {
                    // A per-category line, not a `ContentUnavailableView`: this
                    // sits inside a card that may be one of several on screen,
                    // and a full centred empty state in each would drown the
                    // categories that do have items.
                    Text("Nothing here yet.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(Color(.appBackgroundElevated))
                        .dropDestination(for: String.self) { droppedIds, _ in
                            let uuids = droppedIds.compactMap { UUID(uuidString: $0) }
                            onDrop(uuids, category)
                            return true
                        }
                } else {
                    ForEach(items) { item in
                        ZStack(alignment: .trailing) {
                            // Delete button revealed underneath
                            Button(action: {
                                withAnimation {
                                    onDelete(item)
                                    swipedItemId = nil
                                    dragOffset = 0
                                }
                            }) {
                                ZStack {
                                    Color.red
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete")
                                    }
                                    .font(.footnote)
                                    .foregroundStyle(.white)
                                }
                            }
                            .frame(width: deleteButtonWidth)
                            .buttonStyle(.plain)
                            // VoiceOver has no z-order and reaches the button
                            // whether or not the row is swiped open — which is
                            // the only way to delete without the gesture. It
                            // just has to be read after the row it deletes.
                            .accessibilitySortPriority(-1)

                            PantryItemRowView(
                                item: item,
                                editingItem: editingItem,
                                editName: $editName,
                                editQuantity: $editQuantity,
                                isInputFocused: isInputFocused,
                                onStartEdit: { onStartEdit(item) },
                                onSaveEdit: { onSaveEdit(item) },
                                onCancelEdit: onCancelEdit
                            )
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(Color(.appBackgroundElevated))
                            .offset(x: swipedItemId == item.id ? dragOffset : 0)
                            .gesture(
                                editingItem?.id != item.id ?
                                DragGesture(minimumDistance: 20)
                                    .onChanged { gesture in
                                        let horizontalMovement = abs(gesture.translation.width)
                                        let verticalMovement = abs(gesture.translation.height)

                                        // Only capture gesture if horizontal movement is greater than vertical
                                        if horizontalMovement > verticalMovement && gesture.translation.width < 0 {
                                            swipedItemId = item.id
                                            dragOffset = max(gesture.translation.width, -deleteButtonWidth)
                                        }
                                    }
                                    .onEnded { gesture in
                                        let horizontalMovement = abs(gesture.translation.width)
                                        let verticalMovement = abs(gesture.translation.height)

                                        // Only handle the gesture if it was primarily horizontal
                                        if horizontalMovement > verticalMovement {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                if gesture.translation.width < -deleteButtonWidth / 2 {
                                                    // Snap to revealed position
                                                    dragOffset = -deleteButtonWidth
                                                } else {
                                                    // Snap back
                                                    swipedItemId = nil
                                                    dragOffset = 0
                                                }
                                            }
                                        }
                                    }
                                : nil
                            )
                            .onTapGesture {
                                // Tap to close if swiped open
                                if swipedItemId == item.id {
                                    withAnimation {
                                        swipedItemId = nil
                                        dragOffset = 0
                                    }
                                }
                            }
                        }
                        .onDrag {
                            NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        .dropDestination(for: String.self) { droppedIds, _ in
                            let uuids = droppedIds.compactMap { UUID(uuidString: $0) }
                            onDrop(uuids, category)
                            return true
                        }

                        if item != items.last {
                            Divider()
                                .padding(.leading, 16)
                                .background(Color(.appBackgroundElevated))
                        }
                    }
                }
            }
            // Rows arrive from `@Query`; keying on the ids catches the insert
            // the mutation's own `withAnimation` misses. Scoped to the id list
            // so it never animates the swipe offset.
            .animation(reduceMotion ? nil : .default, value: items.map(\.id))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .appBackground()
    }
}
