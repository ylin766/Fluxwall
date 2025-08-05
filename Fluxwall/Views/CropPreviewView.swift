import SwiftUI

struct CropPreviewView: View {
    let displaySize: CGSize                         // Display resolution
    let previewImage: NSImage                       // Generated thumbnail
    
    @Binding var scale: CGFloat                     // Scale factor
    @Binding var offset: CGSize                     // Drag offset
    var onScaleChanged: ((CGFloat) -> Void)? = nil
    var onOffsetChanged: ((CGSize) -> Void)? = nil

    @GestureState private var dragOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 12) {
            // Screen simulator + thumbnail preview
            ComputerFrameView(displaySize: displaySize) {
                GeometryReader { previewGeometry in
                    CropPreviewImage(
                        image: previewImage,
                        scale: scale,
                        offset: offset,
                        targetDisplaySize: displaySize
                    )
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                // Relative position mapping: preview window is designed according to actual display ratio
                                // So we directly use the drag distance in preview container as relative offset
                                // Then map proportionally to actual display size
                                let previewSize = previewGeometry.size
                                
                                // Calculate relative offset (percentage)
                                let relativeOffsetX = value.translation.width / previewSize.width
                                let relativeOffsetY = value.translation.height / previewSize.height
                                
                                // Apply relative offset to actual display size
                                let actualOffsetX = relativeOffsetX * displaySize.width
                                let actualOffsetY = relativeOffsetY * displaySize.height
                                
                                let newOffset = CGSize(
                                    width: lastOffset.width + actualOffsetX,
                                    height: lastOffset.height + actualOffsetY
                                )
                                lastOffset = newOffset
                                offset = newOffset
                                onOffsetChanged?(newOffset)
                            }
                    )
                    .onChange(of: dragOffset) { newDrag in
                        // Use the same relative position mapping for real-time preview
                        let previewSize = previewGeometry.size
                        
                        // Calculate relative offset (percentage)
                        let relativeOffsetX = newDrag.width / previewSize.width
                        let relativeOffsetY = newDrag.height / previewSize.height
                        
                        // Apply relative offset to actual display size
                        let actualOffsetX = relativeOffsetX * displaySize.width
                        let actualOffsetY = relativeOffsetY * displaySize.height
                        
                        offset = CGSize(
                            width: lastOffset.width + actualOffsetX,
                            height: lastOffset.height + actualOffsetY
                        )
                    }
                }
            }
            .frame(height: 260)

            // Scale control slider + reset button
            VStack(spacing: 4) {
                HStack {
                    Text("\(LocalizedStrings.current.scale): \(String(format: "%.2f×", scale))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                        onScaleChanged?(1.0)
                        onOffsetChanged?(.zero)
                    }) {
                        Text(LocalizedStrings.current.reset)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .glassCard(
                                cornerRadius: 6,
                                shadowStyle: ModernDesignSystem.Shadow.minimal,
                                glassIntensity: 0.8
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .scaleEffect(1.0)

                }

                Slider(value: $scale, in: 0.5...2.0, step: 0.01) {
                    Text(LocalizedStrings.current.scale)
                } minimumValueLabel: {
                    Text("0.5×").font(.caption2)
                } maximumValueLabel: {
                    Text("2.0×").font(.caption2)
                }
                .onChange(of: scale) { newValue in
                    onScaleChanged?(newValue)
                }
            }

        }
        .padding(12)
        .glassCard(
            cornerRadius: 10,
            shadowStyle: ModernDesignSystem.Shadow.minimal
        )
    }
}
